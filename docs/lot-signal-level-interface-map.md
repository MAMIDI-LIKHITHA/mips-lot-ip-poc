# LOT Signal-Level Interface Map and Integration Gaps

**Status:** Source inspection of current `main`; interface mapping is preliminary.  
**Scope:** Record the actual signals and transaction fields visible in the current RTL before choosing or implementing a CPU-side bus adapter.

## Executive finding

**[Confirmed — RTL]** The current LOT design contains useful protocol-neutral pieces, but the inspected module interfaces do not yet constitute a complete, demonstrated MIPS/AXI/AHB/APB bridge contract.

The request router exposes a destination-selected payload with ready/valid handshakes. The behavioral endpoint adapter decodes a 65-bit request payload by default: one write bit, 32 address bits, and 32 write-data bits. The response router routes a 32-bit response plus one error bit using a source ID. These are related building blocks, but their integration and payload packing must be traced at the actual top level before declaring end-to-end signal compatibility.

## 1. Request router: `rtl/interconnect/lot_txn_router.sv`

Source: [lot_txn_router.sv](../rtl/interconnect/lot_txn_router.sv)

| Signal | Direction | Meaning in current module | Adapter implication |
|---|---|---|---|
| `clk`, `rst_n` | Input | Clock and active-low reset | Must match or be bridged to the chosen CPU subsystem clock/reset. |
| `src_valid[N-1:0]` | Input | Each source presents a request beat | Assert for a valid request and hold payload stable while stalled. |
| `src_ready[N-1:0]` | Output | Per-source acceptance/backpressure indication from crossbar | A request beat is accepted on a source's valid/ready handshake. |
| `src_dst[N-1:0][DST_W-1:0]` | Input | Destination index for each source | Address decode must generate a valid endpoint index; invalid-index behavior must be specified and tested. |
| `src_data[N-1:0][DATA_W-1:0]` | Input | Opaque request payload | Current router does not interpret read/write, address, byte enables, or IDs. |
| `dst_valid[N-1:0]` | Output | Request beat presented to each destination | Destination should consume only on valid/ready handshake. |
| `dst_ready[N-1:0]` | Input | Destination can accept a request beat | Backpressure propagates through the crossbar. |
| `dst_data[N-1:0][DATA_W-1:0]` | Output | Routed payload | Must match the payload format and width expected by each endpoint. |
| `grant[N-1:0][N-1:0]` | Output | Crossbar grant observability | Useful for verification/debug; not a CPU transaction ID. |

**Width observation:** `DATA_W` defaults to 32 bits here. The endpoint adapter's default request payload is 65 bits (see below). The inspected files alone do not prove how these widths are reconciled in the intended integrated path. Treat this as an **integration item to trace**, not as proof of a bug without checking all instantiations and parameter overrides.

## 2. Behavioral endpoint: `rtl/endpoints/lot_endpoint_adapter.sv`

Source: [lot_endpoint_adapter.sv](../rtl/endpoints/lot_endpoint_adapter.sv)

### Request payload (default parameters)

| Field | Bits | Current interpretation |
|---|---:|---|
| `req_write` | 1 | Most-significant payload bit |
| `req_addr` | 32 | Address immediately below the write bit |
| `req_wdata` | 32 | Least-significant 32 bits |
| **Total** | **65** | `LOT_W = ADDR_W + DATA_W + 1` with default widths |

The endpoint accepts a request when `req_valid && req_ready`. Its `req_ready` is high only when no response is pending and reset is deasserted. The endpoint creates one response per accepted request and holds `rsp_valid` while waiting for `rsp_ready`.

### Current register behavior

| Offset (low 16 address bits) | Read behavior | Write behavior |
|---|---|---|
| `0x0000` CONTROL | Returns control register | Updates control register |
| `0x0004` DATA | Returns data register | Updates data register |
| `0x0008` STATUS | Returns constant `0x00000001` | Error |
| `0x000C` ID | Returns constant `0x4C4F5430` | Error |
| Other offsets | Returns zero and sets error | Sets error |

**Important limits visible in this module:**
- No byte-enable/strobe input exists; the current write path writes the full 32-bit word.
- No transaction ID field exists in the endpoint request payload.
- The endpoint handles one outstanding request at a time. Because `req_ready` is low while a response is pending, a new request cannot be accepted until the prior response has been consumed; expect a possible acceptance bubble.
- Address decode uses `req_addr[15:0]`; this module does not itself define system-level address-region decode.
- The endpoint is behavioral simulation RTL, not a physical SPI controller or wireless-device interface.

## 3. Response router: `rtl/interconnect/lot_rsp_router.sv`

Source: [lot_rsp_router.sv](../rtl/interconnect/lot_rsp_router.sv)

| Signal | Direction | Meaning in current module | Adapter implication |
|---|---|---|---|
| `src_valid[N-1:0]` | Input | Completed responses available from endpoints | Each response beat must remain valid until accepted. |
| `src_ready[N-1:0]` | Output | Endpoint response acceptance/backpressure | Backpressure may hold a response pending. |
| `src_id[N-1:0][SRC_W-1:0]` | Input | Return-routing destination/source index | Must identify the original request source according to an explicit convention. It is a routing index, not a general transaction ID. |
| `src_data[N-1:0][DATA_W-1:0]` | Input | Response read-data payload | Default data width is 32 bits. |
| `src_error[N-1:0]` | Input | One-bit error indication | Adapter must translate this into the target CPU bus's error response semantics. |
| `dst_valid[N-1:0]` | Output | Routed response availability | CPU-side response adapter consumes using valid/ready. |
| `dst_ready[N-1:0]` | Input | Destination can accept response | Must be driven according to CPU adapter capacity. |
| `dst_data`, `dst_error` | Output | Routed response data and error | Together form a 33-bit logical response, routed through the crossbar. |

**Open integration question:** Where is the source index captured for each accepted request and later supplied as `src_id`? The response router expects that information from its upstream source; the inspected router module does not maintain a request-to-response transaction table itself. Verify the end-to-end integration and contention tests before claiming correct source association for the target CPU bus.

## 4. Signal-level mapping to a future CPU adapter

This is a **proposed mapping template**, not a mapping to a selected MIPS core.

| CPU-side concept | LOT-side candidate | What the adapter must define |
|---|---|---|
| Request is valid | `src_valid[i]` | Convert native CPU request/stall semantics into a valid beat. |
| Request accepted | `src_valid[i] && src_ready[i]` | Prevent duplicate issuance while the CPU is stalled; define whether acceptance completes the CPU-side request or only queues it. |
| Address | Part of opaque `src_data[i]` payload and/or decode feeding `src_dst[i]` | Define byte vs word addressing, address width, alignment, address-region decode, and unmapped address behavior. |
| Read/write | Payload field if packed into `src_data` | Current router has no separate read/write control. Confirm exact packing. |
| Write data | Payload field if packed into `src_data` | Current router has no separate write-data bus. |
| Byte enables | **No explicit field in inspected interfaces** | Decide whether the CPU requires partial writes and add a field/semantics if needed. |
| Request destination | `src_dst[i]` | Map address ranges to endpoints and define invalid destinations. |
| Response ready | `dst_ready[i]` on response side | Must reflect CPU adapter ability to accept response; keep response stable under stall. |
| Read data | `dst_data[i]` on response side | Return only for the corresponding CPU request. |
| Error response | `dst_error[i]` | Translate error into CPU-specific fault/response behavior. |
| Source association | `src_id` into response router | Define source-index capture/retention and whether one or multiple outstanding requests are permitted. |
| Clock/reset | `clk`, `rst_n` | Confirm common clock or implement CDC; define pending-request reset behavior. |

## 5. Required contract decisions before RTL changes

1. **Request payload format:** explicitly define bit positions, widths, address interpretation, read/write, write data, optional byte enables, and any tags.
2. **Request handshake:** document acceptance on valid/ready; require payload stability while valid is asserted and ready is low.
3. **Response association:** define how a response is tied to its originating source and whether the design supports one outstanding request or multiple.
4. **Error semantics:** define unmapped destination, invalid register offset, write-to-read-only register, timeout, and reset-during-transaction behavior.
5. **Throughput expectations:** document the single-outstanding behavior of the current behavioral endpoint and whether response/next-request overlap is needed.
6. **Width integration:** trace all module instantiations and parameter overrides to ensure the router payload width, endpoint payload width, and packed fields agree.
7. **Partial writes:** decide whether byte strobes are required by the target CPU and peripheral register map.
8. **Verification:** add targeted tests for stalls, back-to-back requests, response backpressure, invalid destination/address, source association under contention, reset with a pending response, and any byte-enable behavior.

## 6. Recommended next sequence

1. Review this map against the top-level/end-to-end testbench wiring and parameter overrides.
2. Resolve payload-width/packing and response-source association explicitly in documentation before touching RTL.
3. Only then draft a concrete CPU-adapter interface contract independent of any guessed MIPS protocol.
4. When the target core is identified, map that contract to the actual native bus and create adapter-specific tests.
5. Run the full ModelSim regression after any RTL/testbench changes; report simulation evidence separately from synthesis or hardware evidence.

## Evidence boundary

This note is based on the listed RTL module interfaces and endpoint behavior. It does not claim compatibility with a specific MIPS core, AXI/AHB/APB, a physical SPI controller, or Silicon Labs hardware. No RTL behavior, regression result, timing result, or hardware validation is changed or implied by this document.
