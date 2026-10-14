# LOT Internal Interface Contract v0.1

**Status:** Proposed, target-independent contract for the current simulation PoC.  
**Applies to:** The protocol-neutral LOT request/response fabric and behavioral endpoints.  
**Does not define:** A native MIPS, AXI, AHB, APB, SPI, Matter, Thread, Wi-Fi, or BLE interface. No target processor or wireless part has been selected.

## 1. Design boundary

Keep the system divided into three independently reviewable boundaries:

1. **CPU/native-bus adapter (future, target-specific):** translates the selected processor bus into the LOT request/response contract below.
2. **LOT fabric (current PoC):** routes one request beat to a selected endpoint and routes a response using an explicit return-destination index.
3. **Endpoint adapter:** implements a behavioral MMIO endpoint in this PoC. A future physical peripheral or wireless controller needs its own interface adapter and software integration.

The current `mips_mmio_adapter_candidate.sv` is a test candidate, not the approved CPU interface. Do not call it MIPS-compatible until the exact core and bus specification have been reviewed.

## 2. Request contract

The current candidate request is one beat with the following packed fields:

| Field | Width | Meaning |
|---|---:|---|
| `write` | 1 bit | 1 = write; 0 = read |
| `address` | 32 bits | Byte address in the candidate harness |
| `write_data` | 32 bits | Full-word write data |
| **Total** | **65 bits** | `{write, address[31:0], write_data[31:0]}` |

The request fabric treats the payload as opaque; it does not interpret these fields. The destination index is carried separately from the payload.

### Handshake rules

- A request transfers only on a rising clock edge where `valid && ready` are both 1.
- The producer must keep `valid`, destination, and payload stable while `valid=1` and `ready=0`.
- The consumer must not act on a request without a valid/ready handshake.
- The fabric must not duplicate an accepted request or grant one input to multiple outputs in the same transfer.
- Invalid destination behavior must be explicitly defined and tested; integrations must not rely on an accidental default route.

## 3. Response contract

The current candidate response is:

| Field | Width | Meaning |
|---|---:|---|
| `read_data` | 32 bits | Endpoint response data |
| `error` | 1 bit | 1 = endpoint reports an error |
| `return_destination` | index width | Index of the request source to receive the response |

A response transfers only on `valid && ready`. The producer holds `valid`, data, error, and return destination stable while stalled. The return destination is a routing index, **not** a transaction ID.

The current end-to-end testbench hardcodes the return destination to source 0 and instantiates one active candidate CPU-side initiator. This contract therefore does not claim multi-initiator response association. If more than one initiator is required, the design must define how the original source is captured and restored before RTL is changed.

## 4. Capacity and ordering

For v0.1, the safe baseline is **one outstanding request per candidate adapter**:

- The candidate adapter accepts a request, waits for its endpoint response, then presents one CPU-side response.
- The behavioral endpoint accepts no new request while a response is pending.
- Sequential requests are supported; pipelined or tagged multiple-outstanding requests are not part of this contract.
- Do not promise a fixed cycle latency. Backpressure may delay acceptance or response completion.
- Arbitration and fairness guarantees are properties of the specific fabric implementation and must be documented/tested separately.

## 5. Address map used by the current candidate

The candidate adapter currently decodes the top 16 address bits into four 64-KiB regions:

| Destination index | Base region |
|---:|---|
| 0 | `0x0000_0000` |
| 1 | `0x0001_0000` |
| 2 | `0x0002_0000` |
| 3 | `0x0003_0000` |

This is a test configuration, not a frozen product address map. The behavioral endpoint at destination 2 currently uses offsets `0x0000` CONTROL, `0x0004` DATA, `0x0008` STATUS, and `0x000C` ID. Other offsets return an error in the current model.

## 6. Reset and error behavior

- Reset is active-low (`rst_n`) in the current RTL.
- Current candidate reset clears pending request/response state. A future CPU adapter must map reset cancellation to the selected native bus's documented behavior.
- An unmapped candidate address completes locally with `error=1` and no LOT request.
- An endpoint-reported error is returned through the response path.
- These are current candidate behaviors, not requirements for the final processor bus. The target bus may require a different fault, retry, abort, or exception mapping.

## 7. Explicitly out of scope in v0.1

No byte enables/strobes, bursts, multiple outstanding transactions, transaction IDs, cache coherence, interrupts, clock-domain crossing, network packet framing, SPI electrical timing, Matter/Thread stack behavior, or hardware performance targets are specified. Add these only when target requirements establish the need and semantics.

## 8. Acceptance checklist before connecting a real processor

- [ ] Record exact MIPS core/subsystem, revision, configuration, and authoritative bus documentation.
- [ ] Confirm native address/data widths, byte addressing, request acceptance, wait states, errors, reset, and outstanding-transaction rules.
- [ ] Confirm initiator count and the return-source association mechanism.
- [ ] Confirm address map, endpoint count, byte-enable needs, and ordering requirements.
- [ ] Confirm target clock/reset topology and any clock-domain crossings.
- [ ] Select the wireless part/board and SoC/NCP/RCP mode separately from the on-chip interconnect decision.
- [ ] Add adapter-specific tests and assertions, then rerun the complete regression.
- [ ] Only after selecting target and tools, report synthesis, timing, area, power, and hardware results.

## 9. Evidence boundary

This document makes the current simulation contract explicit; it does not change RTL or claim a new regression result. It is a proposal for review, and must be revised when the actual processor bus, topology, and endpoint requirements are known.
