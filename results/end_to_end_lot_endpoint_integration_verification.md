# End-to-End LOT Endpoint Integration Verification

## Testbench

`tb/tb_mips_four_endpoint_integration.sv`

## Tool

ModelSim Intel FPGA Edition 2021.1

## Result

**PASS — verified by directed simulation**

Observed run:

- Compilation: **0 errors**
- Simulation: **0 errors, 0 warnings**
- Clock period: **10 ns**
- Clock frequency: **100 MHz**
- Simulation completion: **306 ns**
- Testbench result: **PASS**

## Verified system path

**CPU request → MIPS MMIO candidate adapter → LOT transaction router → 4×4 request XBAR → one of four independent endpoint adapters → response XBAR → LOT response router → MIPS MMIO candidate adapter → CPU response**

## Verified transactions

| Test | Result |
|---|---|
| Endpoint 0 ID read | PASS |
| Endpoint 1 CONTROL write/readback | PASS |
| Endpoint 2 DATA write/readback | PASS |
| Endpoint 3 STATUS read | PASS |
| Invalid local register error propagation | PASS |
| CPU response backpressure / response-data stability | PASS |
| Endpoint isolation after traffic | PASS |

## Endpoint register behavior exercised

Each endpoint uses the behavioral register map:

- `0x0000` — CONTROL, read/write
- `0x0004` — DATA, read/write
- `0x0008` — STATUS, read-only, returns `32'h0000_0001`
- `0x000C` — ID, read-only, returns `32'h4C4F_5430` (`LOT0`)

The candidate CPU address map selects an endpoint with the upper address field and uses the lower 16 bits as the local register offset.

## Error propagation

An access to the invalid local register offset `0x0010` generated an endpoint error response. The error propagated through the response XBAR and LOT response router to the candidate CPU response interface.

## Backpressure verification

The STATUS read intentionally held the CPU response interface stalled for three cycles after the response became valid. The testbench checked that:

- `cpu_rsp_valid` remained asserted.
- Response data remained unchanged.
- Response error status remained unchanged.
- The response completed after `cpu_rsp_ready` was asserted.

## Scope and limitations

This verifies the current **protocol-neutral behavioral integration path by directed simulation**. It does **not** claim final MIPS-bus compatibility, final network protocol behavior, synthesis/timing closure, FPGA resource utilization, or production-ready endpoint implementation.

The reported 100 MHz clock is the **simulation testbench clock**, not an achieved FPGA Fmax. Implementation timing remains to be measured with an appropriate synthesis/place-and-route toolchain.

## Reproduction

Compile:

    vlog -sv rtl/crossbar/xbar_scheduler.sv rtl/crossbar/xbar_4x4.sv rtl/interconnect/lot_txn_router.sv rtl/interconnect/lot_rsp_router.sv rtl/mips_if/mips_mmio_adapter_candidate.sv rtl/endpoints/lot_endpoint_adapter.sv tb/tb_mips_four_endpoint_integration.sv

Run:

    vsim -voptargs=+acc work.tb_mips_four_endpoint_integration
    run -all
