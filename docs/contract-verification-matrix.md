# LOT Contract Verification Matrix

**Purpose:** Map the proposed [LOT Internal Interface Contract v0.1](lot-internal-interface-contract-v0.1.md) to the existing checked-in tests and identify gaps without implying unrun tests have passed.

## Current test mapping

| Contract area | Existing testbench / evidence | Current coverage | Remaining limitation |
|---|---|---|---|
| Request destination decode and packed payload | `tb/tb_mips_mmio_adapter_candidate.sv` | Exercises all four candidate destination regions and checks `{write,address,write_data}` packing | Candidate adapter only; not a selected native MIPS bus |
| Request payload stable during LOT-side stall | `tb/tb_mips_mmio_adapter_candidate.sv`, `tb/tb_lot_txn_router.sv` | Directed checks hold VALID and payload while downstream READY is low | CPU-side request-stall rules still depend on the selected native bus |
| Single outstanding request and sequential reuse | `tb/tb_mips_mmio_adapter_candidate.sv` | Checks a second request is not accepted while the response is outstanding and sequential requests recover | Does not verify tagged or multiple outstanding transactions |
| Response data/error propagation and backpressure | `tb/tb_mips_mmio_adapter_candidate.sv`, `tb/tb_lot_rsp_router.sv`, `tb/tb_end_to_end_candidate.sv` | Checks response data/error, response stability while stalled, and acceptance after READY returns | No fixed response latency guarantee |
| Local unmapped-address error | `tb/tb_mips_mmio_adapter_candidate.sv`, `tb/tb_end_to_end_candidate.sv` | Checks no LOT request is issued and a stable local error response is returned | Error mapping for a real CPU exception/fault remains undefined |
| Endpoint invalid-register error | `tb/tb_end_to_end_candidate.sv` | Checks invalid endpoint offset returns an error | Only the behavioral endpoint register map is exercised |
| Return-destination routing | `tb/tb_lot_rsp_router.sv` | Checks direct routing, distinct-destination concurrent responses, contention, and invalid source IDs | End-to-end CPU harness uses one active initiator and hardcodes source 0 |
| Reset cancellation/recovery | `tb/tb_mips_mmio_adapter_candidate.sv`, `tb/tb_end_to_end_candidate.sv` | Checks reset clears outstanding state and a stalled response, with post-reset recovery | Must be reconciled with the selected native bus reset contract |
| Crossbar arbitration, stalls, invalid destinations, stress | Crossbar testbench family and CI results documented in `docs/next-verification-plan.md` | Existing directed and parameterized simulation coverage | Does not establish synthesis, timing, or hardware behavior |

## Current regression inventory

The checked-in `sim/modelsim/run.do` currently enumerates **12** testbenches. The README's last user-reported ModelSim run records **11 passed, 0 failed on 12 October 2026**. These are different facts: do not infer that the current 12-test script has passed from the earlier 11-test report. Run the current script and update the recorded result only after observing its final summary and all required pass markers.

## Required next checks

1. Run `do sim/modelsim/run.do` with the project's supported ModelSim setup and capture the exact final summary, simulator version, compile warnings, and per-test pass markers.
2. Resolve any mismatch between the current testbench inventory and the reported run before advertising the latest regression as green.
3. When the target MIPS core/native bus is selected, add adapter-specific checks for its exact handshake, byte enables, errors, reset behavior, and request stability rules.
4. If multiple initiators are intended, add an end-to-end test that sends requests from at least two initiators and proves each response returns to the correct origin without misassociation.
5. Keep functional simulation, synthesis, timing/resource analysis, and hardware validation as separate evidence categories.

## Evidence boundary

This matrix is a documentation audit of the checked-in test sources and scripts. It does not run the simulator and does not claim new test results.
