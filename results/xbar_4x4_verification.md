# 4×4 Crossbar Verification Result

## Testbench

- Testbench: `tb/tb_xbar_4x4.sv`
- DUT: `rtl/crossbar/xbar_4x4.sv`
- Scheduler: `rtl/crossbar/xbar_scheduler.sv`
- Simulator: ModelSim Intel FPGA Edition 2021.1

## Compilation

Command used:

```text
vlog -sv rtl/crossbar/xbar_scheduler.sv rtl/crossbar/xbar_4x4.sv tb/tb_xbar_4x4.sv
```

Result:

- Errors: **0**
- Warnings: **3**
- Warnings were the existing `vlog-13314` relaxed SystemVerilog input-port warnings and did not prevent compilation.

## Simulation

Command used:

```text
vsim work.tb_xbar_4x4
run -all
```

Result:

```text
TB RESULT: PASS — connectivity, contention, input exclusivity, backpressure and round-robin fairness checks passed.
** Note: $finish : tb/tb_xbar_4x4.sv(163)
Time: 85 ns
Errors: 0, Warnings: 0
```

## Verified checks

| Check | Result |
|---|---|
| 4×4 connectivity/routing | PASS |
| Contention for same output | PASS |
| Input exclusivity | PASS |
| Backpressure | PASS |
| Round-robin fairness | PASS |
| Simulation errors | 0 |

## Conclusion

The standalone 4×4 crossbar and its round-robin scheduler have passed the current directed verification suite. This establishes the crossbar as a verified building block for the next LOT interconnect integration stage.

This result does **not** imply full LOT IP or system-level verification. Reset/error corner cases, transaction/response routers, MIPS integration, endpoint adapters, and end-to-end behavior remain to be verified.
