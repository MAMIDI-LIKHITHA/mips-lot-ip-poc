# End-to-End LOT Integration Trace and Follow-up Checks

**Status:** Static source trace of the current `main` RTL and `tb_end_to_end_candidate.sv`.  
**Scope:** Document what the existing candidate harness actually wires together. This is not a final MIPS bus contract and is not a new simulation result.

## 1. Confirmed request path

Source testbench: [`tb_end_to_end_candidate.sv`](../tb/tb_end_to_end_candidate.sv)  
Candidate adapter: [`mips_mmio_adapter_candidate.sv`](../rtl/mips_if/mips_mmio_adapter_candidate.sv)  
Request router: [`lot_txn_router.sv`](../rtl/interconnect/lot_txn_router.sv)  
Endpoint: [`lot_endpoint_adapter.sv`](../rtl/endpoints/lot_endpoint_adapter.sv)

The testbench explicitly overrides the request router's payload width to `LOT_W = ADDR_W + DATA_W + 1 = 65` and instantiates the endpoint with the same `LOT_W`. So in this end-to-end candidate harness, the request router is parameterized for a 65-bit payload; the standalone router's default `DATA_W=32` is not the width used by this instantiation.

The candidate adapter's default `DATA_W=64` is split in its port declarations as `DATA_W/2`, giving 32-bit write data and response data. The testbench uses `CPU_DATA_W=64` for the adapter parameter while its CPU-side request/response data signals are 32 bits. This is consistent with the candidate adapter's current half-width convention, but the name `DATA_W` is easy to misread. Consider renaming/documenting this parameter in a later, separately reviewed change rather than altering behavior in this documentation step.

### Request payload

The candidate adapter packs:

- bit 64: `req_write`
- bits 63:32: `req_addr[31:0]`
- bits 31:0: `req_wdata[31:0]`

The request router forwards this payload unchanged to destination 2 in the testbench. The endpoint decodes the same write/address/data fields. The testbench exercises endpoint 2 with addresses in the `0x0002_0000` region and offsets `0x0`, `0x4`, `0x8`, `0xC`, and `0x10`.

## 2. Confirmed response path—and current limitation

The endpoint outputs `rsp_rdata` and `rsp_error`. In the end-to-end testbench, those signals are connected to response-router input lane 0. The testbench assigns:

```systemverilog
rsp_src_id[0] = 2'd0;
```

The response router uses this ID as its destination output index. Therefore, **the current end-to-end harness hardcodes the response route back to candidate source 0**. It does not demonstrate dynamic request-source tracking across multiple CPU request sources. That is acceptable for this single-source candidate test, but multi-source integration needs an explicit source-association policy and tests.

## 3. Confirmed candidate address decode

The candidate adapter decodes the upper address region using `DEST_MASK = 32'hFFFF_0000` and defaults:
- destination 0: `0x0000_0000` region
- destination 1: `0x0001_0000` region
- destination 2: `0x0002_0000` region
- destination 3: `0x0003_0000` region

For an address outside these regions, `addr_valid` is false. In the current candidate adapter, `lot_valid=0` and `req_ready` can still assert when the adapter is idle and reset is deasserted. When the CPU-side request handshakes (`req_valid && req_ready`) with an unmapped address, the adapter creates a local response with zero read data and `rsp_error=1`; no LOT request is issued. The end-to-end candidate testbench includes a read at `0x0004_0000` to check this behavior. This is candidate-adapter behavior, not a confirmed native MIPS fault/exception mapping.

## 4. Current request/response capacity

The candidate adapter has a `busy` flag and a single response register. It accepts one LOT request, waits for its LOT response, presents one CPU response, and clears busy when the CPU consumes the response. The behavioral endpoint also accepts requests only when no response is pending. This supports a simple single-outstanding transaction model, not a demonstrated pipelined or tagged multi-outstanding bus.

The request handshake in the harness is:
- CPU side: `req_valid && req_ready`
- LOT side: `lot_valid && lot_ready`
- Endpoint side: `req_valid && req_ready`
- Response router side: `src_valid && src_ready` and `dst_valid && dst_ready`
- CPU response completion: `rsp_valid && rsp_ready`

A future adapter contract should say explicitly that request payload/address/control remain stable while valid is asserted and ready is low, and that a response remains stable until accepted.

## 5. Follow-up items before RTL changes

| Priority | Item | Why it matters | Recommended verification |
|---|---|---|---|
| Done in candidate harness; confirm native mapping | Unmapped destination handling | Candidate adapter returns a local error response for unmapped addresses; the real CPU bus's error/fault translation remains unconfirmed | Keep the unmapped-address test in regression and map `rsp_error` to the selected CPU protocol once identified |
| High | Dynamic response-source association | Current end-to-end test hardcodes `rsp_src_id[0]=0` | Add multi-source request/response test if multi-source CPU initiators are intended |
| High | Address and payload contract | Current 65-bit layout is coherent in this testbench but is protocol-neutral and custom | Add packing assertions and a field/width definition shared by adapter/router/endpoint |
| Medium | Parameter naming | Adapter parameter `DATA_W=64` yields 32-bit CPU data ports via `DATA_W/2` | Rename in a future API revision or clearly document half-width convention |
| Medium | Reset with request/response pending | Reset clears adapter/endpoint pending state; cancellation semantics are not a CPU bus specification | Test reset during each phase and define whether the CPU sees cancellation/error |
| Medium | Back-to-back throughput | Single-outstanding `busy` and endpoint pending state limit concurrency | Add acceptance/response timing assertions and decide if a bubble is acceptable |
| Medium | Byte writes | No byte-enable/strobe field is carried in the payload | Confirm target core/peripheral requirements before adding a field |

## 6. Evidence boundary

**[Confirmed]** The testbench wires a 65-bit request payload through the request router into the endpoint and routes the response through the response router back to source 0. It tests register reads/writes, invalid offsets within the mapped endpoint region, error propagation, and CPU response backpressure.

**[Not established]** Dynamic multi-source request tracking, a final MIPS native bus, AXI/AHB/APB compatibility, native CPU fault/exception semantics, synthesis, timing closure, FPGA/ASIC behavior, or network-device integration.

This is a static source trace only. No RTL/testbench behavior was changed, and no new regression was run as part of writing this note.
