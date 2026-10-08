# 4×4 Crossbar Sustained Backpressure Verification

## Testbench

- `tb/tb_xbar_backpressure_stability.sv`
- Simulator: ModelSim Intel FPGA Edition 2021.1

## Scope

Directed verification of sustained output backpressure and ready/valid behavior for a held input request.

## Checks

- Destination remains stalled for multiple clock cycles.
- `out_valid` remains deasserted while the selected destination is not ready.
- `in_ready` remains deasserted while the selected destination is stalled.
- Held request data remains unchanged during backpressure.
- Releasing `out_ready` allows the request to transfer.
- Output data remains `32'hCAFE_1234`.
- Source deassertion returns the crossbar to idle.

## Result

**PASS**

Observed ModelSim result:

- Compilation: 0 errors, 3 nonfatal warnings.
- Simulation: 0 errors, 0 warnings.
- Testbench result: **PASS**
- Simulation completion: **37 ps**

The ModelSim `$finish` / Break message at the testbench `$finish` line is expected and does not indicate a failure.

## Evidence

Observed output:

`TB RESULT: PASS - sustained backpressure, ready/valid suppression, data stability and recovery checks passed.`
