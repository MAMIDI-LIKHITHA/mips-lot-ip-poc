# Gate 0.5 — Existing LOT/MIPS Simulation Baseline

**Status:** PARTIALLY VERIFIED — portable Verilator regression passed 11/11 on 27 October 2026; fresh full ModelSim regression and warning triage remain pending.  
**Purpose:** Reproduce the current simulation baseline before adding architecture-driven RTL.  
**Evidence boundary:** This record distinguishes previously reported results from a fresh run. It does not claim hardware validation, target-specific timing closure, or production MIPS approval.

## 1. Current regression entry point

- Repository: `MAMIDI-LIKHITHA/mips-lot-ip-poc`
- Default branch at preparation: `main`
- ModelSim script: `sim/modelsim/run.do`
- Documented command from repository root: `do sim/modelsim/run.do`
- Historical simulator: ModelSim Intel FPGA Edition 2021.1
- Current script SHA observed during review: `39f08b495a08848abc64e1884bba8bdb6bbf3e04`
- Fresh ModelSim commit SHA / simulator run ID / exit code: **pending owner-side execution**
- Portable CI commit SHA: `433b7483be7c3e049c8e97e99bba60a6ab1bba87`
- Portable CI run: [Gate 0.5 — Verilator portable regression](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/40467577406) — **SUCCESS**

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

This list is the ModelSim script's configured inventory. The separate portable CI workflow runs 11 tests; it excludes `tb_xbar_coverage` because its covergroup syntax is not part of the portable Verilator subset.

## 3. Previously reported baseline (historical, not re-run here)

The repository README records a local run on 14 October 2026 using ModelSim Intel FPGA Edition 2021.1:

- 12 passed, 0 failed.
- 0 compilation errors and 14 warnings.
- Crossbar route coverage: 16/16.
- Stress counters: 500 cycles, 1,175 accepted and 1,175 delivered transfers.
- The README explicitly states that this was local simulation evidence, not a GitHub Actions result.

These figures must be re-confirmed against the current commit. The 14 warnings remain untriaged in this record; do not assume they are harmless.

## 4. Fresh portable CI run — actual execution evidence

A GitHub Actions run on 27 October 2026 completed successfully on commit `433b7483be7c3e049c8e97e99bba60a6ab1bba87`.

- Runner: GitHub-hosted Ubuntu runner.
- Simulator: Verilator 5.020 (Debian package `5.020-1`), as printed in the GitHub Actions log.
- Workflow: [Gate 0.5 — Verilator portable regression](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/40467577406).
- Result: **11 passed, 0 failed**.
- The workflow requires a `TB RESULT: PASS` marker for each test and stores build/simulation logs in the `gate-0-5-verilator-logs` artifact.
- The successful run covered crossbar routing, backpressure stability, multi-output, invalid destination, reset, stress/latency, transaction router, response router, candidate MMIO adapter, end-to-end candidate path, and four-endpoint integration.
- The portable run does **not** execute `tb_xbar_coverage`, so it does not replace ModelSim coverage-specific validation.
- Warnings observed include `TIMESCALEMOD` for RTL modules without an explicit timescale and `WIDTHEXPAND` in the stress testbench and response-router comparisons/assignments. They remain **untriaged**; no warning is presumed harmless. The `TIMESCALEMOD` messages arise from mixed timescale declarations across testbench and RTL compilation units; decide whether to add a consistent explicit timescale or configure the simulation unit in a follow-up. Width warnings need a source-level review to distinguish harmless testbench sizing from RTL comparisons.
- The CI workflow uses temporary testbench copies to convert testbench `$stop` calls to `$finish`; it does not modify the original testbench source for this purpose.

## 5. Fresh ModelSim run — pending actual owner-side execution

| Field | Result |
|---|---|
| Commit SHA | PENDING — record the clean checkout SHA used for ModelSim |
| OS / runner | Project owner's Windows environment; exact OS build pending |
| Simulator and exact version | ModelSim Intel FPGA Edition 2021.1 (confirm installed version) |
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

## 6. Gate 0.5 acceptance checklist

- [ ] Fresh current-commit ModelSim regression completes with 12/12 expected pass markers.
- [ ] Compile and runtime warnings are reviewed and documented.
- [x] Portable Verilator CI subset passes 11/11 on the recorded commit (does not replace ModelSim coverage test).
- [ ] Existing Icarus/OpenMIPS access-classifier/bridge/actual-cache/full-core workflows are individually checked and mapped to architecture requirements.
- [ ] Read/write payload and response-source association are evidenced end to end.
- [ ] Invalid/unmapped access, reset with outstanding traffic, backpressure, contention/fairness, and deterministic timeout behavior are covered by named tests or explicitly tracked gaps.
- [ ] A verification report links the fresh run and any CI jobs.

## 7. Boundaries and blockers

- The portable Verilator result is fresh CI evidence, but this record is not a full Gate 0.5 pass until Section 5 is populated from a fresh ModelSim run and warning triage.
- ModelSim is a tool on the project owner's Windows setup; this GitHub documentation workflow cannot execute that local installation. No local simulator output has been fabricated.
- Portable CI results are separate from the full twelve-test ModelSim regression and must not be represented as equivalent.
- FPGA board, exact production MIPS core/native bus, vendor permissions, Silicon Labs board/SDK, target constraints, timing/resource results, and hardware validation remain separate open decisions/gates.
