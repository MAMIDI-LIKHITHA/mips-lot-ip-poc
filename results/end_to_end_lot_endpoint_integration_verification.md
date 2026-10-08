# End-to-End LOT Endpoint Integration Verification

## Testbench

`tb/tb_end_to_end_candidate.sv`

## Tool

ModelSim Intel FPGA Edition 2021.1

## Result

**PASS**

Observed run:

- Compilation: **0 errors**
- Simulation: **0 errors, 0 warnings**
- Simulation completion: **296 ps**
- Testbench result: **PASS**

## Verified system path

**CPU request → MIPS MMIO candidate adapter → LOT transaction router → 4×4 request XBAR → Endpoint 2 register adapter → response XBAR → LOT response router → MIPS MMIO candidate adapter → CPU response**

## Verified transactions

| Test | Result |
|---|---|
| CONTROL write at endpoint 2 + offset 0x0000 | PASS |
| CONTROL readback | PASS |
| DATA write at endpoint 2 + offset 0x0004 | PASS |
| DATA readback | PASS |
| STATUS read at offset 0x0008 | PASS |
| ID read at offset 0x000C | PASS |
| Invalid endpoint register at offset 0x0010 | PASS |
| Response backpressure / response-data stability | PASS |

## Endpoint register behavior exercised

Endpoint 2 uses the behavioral register map:

- `0x0000` — CONTROL, read/write
- `0x0004` — DATA, read/write
- `0x0008` — STATUS, read-only, returns `32'h0000_0001`
- `0x000C` — ID, read-only, returns `32'h4C4F_5430` (`LOT0`)

The candidate CPU address map places endpoint 2 at `32'h0002_0000`, so the transactions above exercise addresses from `32'h0002_0000` through `32'h0002_0010`.

## Error propagation

An access to the invalid local register offset `0x0010` generated an endpoint error response. The error propagated through the response XBAR and LOT response router to the candidate CPU response interface.

## Backpressure verification

The final STATUS read intentionally held the CPU response interface stalled for three cycles after the response became valid. The testbench checked that:

- `cpu_rsp_valid` remained asserted.
- Response data remained unchanged.
- Response error status remained unchanged.
- The response completed after `cpu_rsp_ready` was asserted.

## Scope and limitations

This verifies the current protocol-neutral behavioral integration path. It does **not** claim final MIPS-bus compatibility, final network protocol behavior, synthesis/timing closure, or production-ready endpoint implementation.

## Reproduction

Compile:

    vlog -sv rtl/crossbar/xbar_scheduler.sv rtl/crossbar/xbar_4x4.sv rtl/interconnect/lot_txn_router.sv rtl/interconnect/lot_rsp_router.sv rtl/mips_if/mips_mmio_adapter_candidate.sv rtl/endpoints/lot_endpoint_adapter.sv tb/tb_end_to_end_candidate.sv

Run:

    vsim work.tb_end_to_end_candidate
    run -all
