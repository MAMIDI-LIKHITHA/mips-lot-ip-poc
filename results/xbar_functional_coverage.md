# XBAR Functional Coverage Verification

## Objective

Exercise the 4×4 request crossbar across the complete route space and key traffic/reset scenarios using a simulator-portable procedural coverage tracker.

## Testbench

- Coverage tracker: `verification/xbar_coverage.sv`
- Testbench: `tb/tb_xbar_coverage.sv`
- RTL:
  - `rtl/crossbar/xbar_scheduler.sv`
  - `rtl/crossbar/xbar_4x4.sv`

## Verification command

```text
vlog -sv rtl/crossbar/xbar_scheduler.sv rtl/crossbar/xbar_4x4.sv verification/xbar_coverage.sv tb/tb_xbar_coverage.sv
vsim work.tb_xbar_coverage
run -all
```

## Result

**PASS**

```text
==============================================
XBAR FUNCTIONAL COVERAGE
Route coverage       : 16/16 = 100.00%
Contention           : PASS
Multi-output         : PASS
Backpressure         : PASS
Reset                : PASS
==============================================
TB RESULT: PASS - functional coverage scenarios exercised all 16 routes, contention, four-way multi-output traffic, partial backpressure and reset.
```

## Observed simulator status

- Compilation: **0 errors, 5 warnings**
- Simulation: **0 errors, 0 warnings**
- Simulation completion: **204 ps**
- Testbench terminated normally with `$finish`

## Coverage interpretation

The testbench exercised every possible input-to-output route in the 4×4 crossbar:

`4 inputs × 4 outputs = 16 route combinations`

In addition, it exercised:

- Multiple-input contention for a shared output
- Four simultaneous input/output transfers
- Partial output backpressure
- Reset assertion/deassertion and post-reset recovery

The tracker is intentionally procedural rather than a SystemVerilog covergroup, because ModelSim Intel FPGA Edition does not provide the Questa verification-coverage license required to simulate covergroups.

## Conclusion

The directed functional-coverage milestone for the current 4×4 crossbar implementation is **PASS**. All 16 route combinations and the selected contention, multi-output, backpressure and reset scenarios were observed without simulation errors.