# 4×4 Crossbar Simultaneous Multi-Output Verification

## Testbench

- `tb/tb_xbar_multi_output.sv`
- Simulator: ModelSim Intel FPGA Edition 2021.1

## Scope

Directed verification of simultaneous independent traffic across all four crossbar outputs, followed by partial backpressure and recovery.

## Checks

- Four simultaneous inputs routed to four different outputs.
- Correct data observed on all four outputs.
- Exactly one grant per active input.
- Exactly one grant per active output.
- Stalling output 2 does not block the other three independent outputs.
- Input/output ready signals correctly reflect partial backpressure.
- Independent output data remains unchanged during partial backpressure.
- Releasing output 2 restores all four transfers.

## Result

**PASS**

Observed ModelSim result:

- Compilation/simulation: **0 errors, 0 warnings**
- Testbench result: **PASS**
- Simulation completion: **35 ps**

The ModelSim `$finish` / Break message at the testbench `$finish` line is expected and does not indicate a failure.

## Evidence

Observed output:

`TB RESULT: PASS - simultaneous multi-output routing, one-to-one grants, partial backpressure and recovery checks passed.`
