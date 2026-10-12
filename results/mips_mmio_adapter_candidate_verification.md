# MIPS MMIO Candidate Adapter Verification

## Environment

- Simulator: ModelSim Intel FPGA Edition 2021.1
- Regression script: `sim/modelsim/run.do`
- DUT: `rtl/mips_if/mips_mmio_adapter_candidate.sv`
- Adapter testbench: `tb/tb_mips_mmio_adapter_candidate.sv`

## Latest reported ModelSim regression — 12 October 2026

The user ran `do sim/modelsim/run.do` from the repository root in ModelSim. The captured Transcript ended with:

```text
REGRESSION SUMMARY: 11 passed, 0 failed
REGRESSION RESULT: PASS
```

All 11 testbenches reported PASS:

1. `tb_xbar_4x4`
2. `tb_xbar_backpressure_stability`
3. `tb_xbar_multi_output`
4. `tb_xbar_coverage`
5. `tb_xbar_invalid_dst`
6. `tb_xbar_reset`
7. `tb_xbar_stress_latency`
8. `tb_lot_txn_router`
9. `tb_lot_rsp_router`
10. `tb_mips_mmio_adapter_candidate`
11. `tb_end_to_end_candidate`

The run generated per-test logs under `sim/modelsim/regression_<testbench>.log`. The user checked those logs with `findstr`; each of the 11 logs contained a `TB RESULT: PASS` marker.

## Adapter scenarios reported as verified

The adapter test log reports checks for:

1. Four destination decodes and LOT payload encoding.
2. LOT-side request backpressure and request-data stability.
3. Single-outstanding-request enforcement.
4. CPU-side response backpressure and response/error stability.
5. Error handling for unmapped addresses without issuing a LOT transfer.
6. Reset quiescence and recovery.

The test log ends with a `TB RESULT: PASS` marker.

## Scope and limitations

This is behavioral simulation evidence for the candidate RTL and the testbenches listed above. It does **not** establish:

- Compatibility with the native bus interface of the actual target MIPS core. That core and its bus specification still need to be confirmed.
- MIPS ISA functionality or a complete processor implementation.
- Synthesis success, FPGA resource utilization, timing closure, or hardware validation.
- Production readiness of the candidate adapter or interconnect.

The regression result above is based on the ModelSim Transcript and logs supplied from the user's local Windows run. It is not a claim that the run was executed by GitHub Actions.
