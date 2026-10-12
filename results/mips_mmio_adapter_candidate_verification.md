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


## Follow-up source review — 12 October 2026

A review of the checked-in RTL and testbench found that the original invalid-address test expected `req_ready=0`, while the RTL intentionally accepts an unmapped request locally and generates an error response without issuing a LOT transfer. These expectations conflict. The testbench has been updated to verify local acceptance, no LOT transfer, zero response data, asserted error, and response stability until the CPU-side handshake completes.

**Validation status:** the corrected test has not yet been run in ModelSim in this environment. The historical PASS result above must be treated as pending re-validation until the updated test is executed successfully. No native MIPS bus compatibility, synthesis, timing, or hardware validation is implied.
