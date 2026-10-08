# XBAR Stress + Latency Verification

## Testbench
- tb/tb_xbar_stress_latency.sv
- DUT: rtl/crossbar/xbar_4x4.sv
- Scheduler: rtl/crossbar/xbar_scheduler.sv
- Simulator: ModelSim Intel FPGA Edition

## Result

**PASS**

The stress test exercised 500 deterministic traffic cycles and checked transfer accounting, arbitration invariants, data integrity, contention, backpressure, simultaneous four-output traffic, and the combinational transfer path.

### Observed results

| Metric | Result |
|---|---:|
| Stress cycles | 500 |
| Accepted transfers | 1002 |
| Delivered transfers | 1002 |
| Contention cycles | 450 |
| Backpressure output stalls | 200 |
| Four-output cycles | 50 |
| Latency minimum | 0 cycles |
| Latency maximum | 0 cycles |
| Latency average | 0.00 cycles |
| Zero-cycle transfers | 1002 |

## Verification checks

- Accepted and delivered transfer counts matched: **1002 = 1002**
- Contention was exercised: **450 cycles**
- Output backpressure was exercised: **200 output-stall observations**
- Four outputs were simultaneously active: **50 cycles**
- Input/output grant exclusivity was checked every stress cycle
- Granted destination and output data integrity were checked
- Zero-cycle latency was observed for all accepted transfers
- Testbench result: **PASS**

## Interpretation

The current 4×4 crossbar is a combinational ready/valid datapath, so the measured **0-cycle transfer latency** means a transfer can propagate from input to output within the same simulation cycle when arbitration and handshake conditions permit it. This is not a registered clock-to-clock latency measurement.

No FPGA resource or Fmax claim is made here because Quartus implementation was not run.

## Reproduction

    vlog -sv rtl/crossbar/xbar_scheduler.sv rtl/crossbar/xbar_4x4.sv tb/tb_xbar_stress_latency.sv
    vsim work.tb_xbar_stress_latency
    run -all

The testbench ends with $stop so ModelSim remains available for waveform/debug inspection.

## Conclusion

**PASS — deterministic 500-cycle stress verification completed with full transfer accounting, contention, backpressure, four-output simultaneous traffic, and zero-cycle combinational latency checks.**
