# Gate 0.5 — Existing LOT/MIPS Simulation Baseline

**Status:** IN PROGRESS — historical results recorded; current checkout has not yet been re-run in the project owner's simulator.  
**Purpose:** Reproduce the current simulation baseline before adding architecture-driven RTL.  
**Evidence boundary:** This record distinguishes previously reported results from a fresh run. It does not claim hardware validation, target-specific timing closure, or production MIPS approval.

## 1. Current regression entry point

- Repository: `MAMIDI-LIKHITHA/mips-lot-ip-poc`
- Default branch at preparation: `main`
- ModelSim script: `sim/modelsim/run.do`
- Documented command from repository root: `do sim/modelsim/run.do`
- Historical simulator: ModelSim Intel FPGA Edition 2021.1
- Current script SHA observed during review: `39f08b495a08848abc64e1884bba8bdb6bbf3e04`
- Fresh commit SHA / simulator run ID / exit code: **pending owner-side execution**

The script compiles the RTL and runs twelve testbenches one by one, requiring each per-test transcript to contain the explicit `TB RESULT: PASS` marker. It writes transcripts under `sim/modelsim/regression_<testbench>.log` and exits non-zero if compilation, loading, simulation, or a pass-marker check fails.

## 2. Test inventory in the current script

| # | Testbench | Primary area |
|---:|---|---|
| 1 | `tb_xbar_4x4` | Crossbar connectivity and routing |
| 2 | `tb_xbar_backpressure_stability` | Ready/valid stability under backpressure |
| 3 | `tb_xbar_multi_output` | Simultaneous output routing |
| 4 | `tb_xbar_coverage` | Functional route/contention coverage |
| 5 | `tb_xbar_invalid_dst` | Invalid destination handling |
| 6 | `tb_xbar_reset` | Reset behavior |
| 7 | `tb_xbar_stress_latency` | Deterministic stress/latency counters |
| 8 | `tb_lot_txn_router` | Request routing |
| 9 | `tb_lot_rsp_router` | Response routing |
| 10 | `tb_mips_mmio_adapter_candidate` | Candidate MMIO adapter behavior |
| 11 | `tb_end_to_end_candidate` | Candidate CPU/MMIO-to-LOT end-to-end path |
| 12 | `tb_mips_four_endpoint_integration` | Four-endpoint integration |

This list is the script's configured test inventory, not evidence that these tests have just passed.

## 3. Previously reported baseline (historical, not re-run here)

The repository README records a local run on 14 October 2026 using ModelSim Intel FPGA Edition 2021.1:

- 12 passed, 0 failed.
- 0 compilation errors and 14 warnings.
- Crossbar route coverage: 16/16.
- Stress counters: 500 cycles, 1,175 accepted and 1,175 delivered transfers.
- The README explicitly states that this was local simulation evidence, not a GitHub Actions result.

These figures must be re-confirmed against the current commit. The 14 warnings remain untriaged in this record; do not assume they are harmless.

## 4. Fresh-run record — fill only from actual execution

| Field | Result |
|---|---|
| Commit SHA | PENDING |
| OS / runner | PENDING |
| Simulator and exact version | PENDING |
| Exact command | `do sim/modelsim/run.do` |
| Compile errors | PENDING |
| Compile/runtime warnings | PENDING |
| Per-test results | PENDING |
| Final summary | PENDING |
| Process exit status | PENDING |
| Transcript/log artifact location | PENDING |
| Warning triage | PENDING |

### Required run procedure

1. Start from a clean checkout and record `git rev-parse HEAD`.
2. Open ModelSim Intel FPGA Edition 2021.1 at the repository root.
3. Run `do sim/modelsim/run.do`.
4. Preserve the complete console transcript and the twelve generated per-test logs.
5. Record the exact final summary, exit status, and every warning. For each warning, classify it as fixed, actionable, or accepted with a specific simulator-related reason.
6. If any test fails, keep Gate 0.5 open, capture the first reproducible failure, and fix it before adding new architecture RTL.

## 5. Gate 0.5 acceptance checklist

- [ ] Fresh current-commit ModelSim regression completes with 12/12 expected pass markers.
- [ ] Compile and runtime warnings are reviewed and documented.
- [ ] Portable Icarus tests for the candidate adapter, OpenMIPS access classifier, bridge, actual-cache wrapper, and full-core program are checked against their current workflow results.
- [ ] Read/write payload and response-source association are evidenced end to end.
- [ ] Invalid/unmapped access, reset with outstanding traffic, backpressure, contention/fairness, and deterministic timeout behavior are covered by named tests or explicitly tracked gaps.
- [ ] A verification report links the fresh run and any CI jobs.

## 6. Boundaries and blockers

- This record is not a fresh simulation report until Section 4 is populated from an actual run.
- ModelSim is a tool on the project owner's Windows setup; this GitHub documentation workflow cannot execute that local installation. No local simulator output has been fabricated.
- Portable CI results are separate from the full twelve-test ModelSim regression and must not be represented as equivalent.
- FPGA board, exact production MIPS core/native bus, vendor permissions, Silicon Labs board/SDK, target constraints, timing/resource results, and hardware validation remain separate open decisions/gates.
