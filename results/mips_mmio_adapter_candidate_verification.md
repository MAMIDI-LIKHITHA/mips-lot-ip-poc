# MIPS MMIO Candidate Adapter Verification

## Testbench

- Testbench: tb/tb_mips_mmio_adapter_candidate.sv
- DUT: rtl/mips_if/mips_mmio_adapter_candidate.sv
- Simulator: ModelSim Intel FPGA Edition 2021.1

## Result

**PASS**

Observed simulation result:

- Compilation: **0 errors, 0 warnings**
- Testbench result: **PASS**
- Simulation completion: **346 ps**
- Final $stop: expected testbench termination after all checks pass

## Verified scenarios

1. Four destination decodes and LOT payload encoding.
2. LOT-side request backpressure and request-data stability.
3. Single-outstanding-request enforcement.
4. CPU-side response backpressure and response/error stability.
5. Invalid-address suppression.
6. Reset quiescence and post-reset recovery.

The testbench explicitly reports:

> TB RESULT: PASS - candidate MIPS MMIO adapter destination decode, payload encoding, request/response backpressure, single-outstanding behavior, error propagation, invalid-address suppression and reset recovery verified.

## Scope note

This is a behavioral simulation result. It does not claim MIPS ISA functionality, timing closure, FPGA resource utilization, or implementation performance.
