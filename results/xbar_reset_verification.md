# 4×4 Crossbar Reset Verification Result

## Testbench

- Testbench: `tb/tb_xbar_reset.sv`
- DUT: `rtl/crossbar/xbar_4x4.sv`
- Scheduler: `rtl/crossbar/xbar_scheduler.sv`
- Simulator: ModelSim Intel FPGA Edition 2021.1

## Compilation

Command used:

```text
vlog -sv rtl/crossbar/xbar_scheduler.sv rtl/crossbar/xbar_4x4.sv tb/tb_xbar_reset.sv
```

Result:

- Errors: **0**
- Warnings: **3**
- Warnings were nonfatal existing SystemVerilog input-port warnings.

## Simulation

Command used:

```text
vsim work.tb_xbar_reset
run -all
```

Result:

```text
TB RESULT: PASS - reset quiescence, reset-time traffic suppression, post-reset recovery and repeated reset behavior checks passed.
** Note: $finish    : tb/tb_xbar_reset.sv(114)
Time: 26 ns
```

The `$finish` / `Break in Module` message is the expected simulator stop at the testbench's `$finish` statement.

## Verified checks

| Check | Result |
|---|---|
| Reset quiescence | PASS |
| Traffic suppressed while reset asserted | PASS |
| Post-reset traffic recovery | PASS |
| Repeated reset behavior | PASS |
| Simulation errors | 0 |

## Conclusion

The 4×4 crossbar passed the current directed reset verification. External transfer signals remain quiescent during reset, traffic is suppressed while reset is asserted, and normal routing resumes correctly after reset release.

This result establishes reset behavior for the current crossbar implementation. It does not by itself establish full system reset verification across the LOT routers, MIPS adapter, endpoint models, or complete candidate path.
