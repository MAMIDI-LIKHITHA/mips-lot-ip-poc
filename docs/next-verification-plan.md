# LOT POC — Next Verification Plan

**Status:** Refreshed after PRs #39–#46. The test items below distinguish implemented coverage from remaining work.  
**Scope:** Planning only. This document update does not change RTL/testbench behavior and does not claim a new simulation.

## 1. Current evidence baseline

The README reports a user-run ModelSim Intel FPGA Edition 2021.1 regression on 12 October 2026 with 11 tests passing, 0 failing, all 16 request routes covered, and a 500-cycle stress test with 1,175 accepted and 1,175 delivered transfers. These are local simulation results reported by the project, not hardware validation.

The checked-in candidate adapter and router tests now additionally cover:
- Invalid response source IDs without accidental routing.
- Response stability across sustained destination backpressure and acceptance when READY returns, including CPU-side error-response backpressure (PR #46).
- Deterministic lowest-index source priority during same-destination contention (candidate behavior only; no fairness guarantee).
- Reset gating of response VALID, source READY, and grants.
- Sequential read/write transactions after the previous response completes, including idle recovery without a stale response.

The candidate adapter test also exercises request payload stability during LOT-side backpressure, CPU response/error stability, single-outstanding enforcement, unmapped-address errors, and reset cancellation. PR #46 extends end-to-end backpressure coverage to an unmapped-address error response. These tests define the current candidate POC behavior; they do not establish compatibility with a target MIPS bus.

The testbench hardcodes the response source ID to source 0 and only instantiates one active candidate CPU-side initiator. Therefore, it does not demonstrate dynamic response association for multiple initiators.

## 2. Recommended tests, in priority order

| Priority | Test | Stimulus and required assertion | Why it matters |
|---|---|---|---|
| P0 | Target bus contract review | Obtain the exact MIPS core/manual or wrapper and define request/response semantics, reset cancellation, byte enables, and outstanding policy. | Blocks protocol-specific integration; avoid encoding unapproved assumptions. |
| P0 | Target topology and source association | Confirm intended initiator count and response-routing contract before extending beyond source 0. | The current end-to-end harness has one active candidate initiator and hardcodes response source 0. |
| P1 | CPU-side request stability assertion | Add a protocol assertion/test for request field stability whenever the actual CPU-side valid/ready contract requires it. | CPU-side requirements depend on the chosen native interface. |
| P0 | Response-source association | Exercise at least two response destinations/source IDs and concurrent responses; verify data and error return only to the intended destination. | Current end-to-end harness hardcodes source ID 0. |
| P1 | Invalid response destination ID | **Implemented in PR #39.** Drive an out-of-range source ID and verify no destination VALID, source READY, or grant is asserted. | Protects against accidental routing of malformed response IDs. |
| P1 | Back-to-back transactions | **Implemented in PR #43.** Complete sequential read/write requests; check matching responses and idle recovery without stale response. | Confirms sequential reuse; it does not imply multiple outstanding support. |
| P1 | Sustained response backpressure | **Implemented in PR #40.** Hold destination READY low across multiple cycles, check response stability, then verify acceptance when READY returns. | Prevents response loss or mutation under stall. |
| P1 | Same-destination response contention | **Implemented in PR #41.** Assert the current fixed lowest-index priority and corresponding response data/READY behavior. | Documents current arbitration behavior; fairness remains unproven and is not promised. |
| P1 | Response router reset gating | **Implemented in PR #42.** Verify no destination VALID, source READY, or grant during reset. | Makes candidate reset behavior explicit in regression. |
| P1 | Request crossbar destination changes under contention | Keep multiple contenders active while the selected output stalls, then release it; verify grant, payload, and round-robin progression. | Strengthens fairness and stability evidence for changing traffic. |
| P1 | Error response under backpressure | **Implemented in PR #46.** Stall an unmapped-address error response at the CPU; verify VALID, data, and error remain stable until accepted. | Protects error semantics under response backpressure. |
| P2 | Parameter and width sanity | Compile representative legal parameter combinations and add elaboration-time checks/documentation for unsupported widths or destination counts. | Prevents silent assumptions around `DATA_W/2`, `LOT_W`, and destination widths. |
| P2 | Assertions and coverage | Add assertions for valid/payload stability while stalled, no duplicate acceptance, response stability, and accepted-request/response accounting. | Makes the regression catch protocol regressions rather than only expected examples. |

## 3. Test acceptance rules

For each new test:
1. Make the stimulus deterministic and bounded with a timeout so a deadlock fails rather than hanging the regression.
2. Check both safety (no duplicate, misrouted, or changing transaction) and liveness (accepted request eventually completes, unless reset cancellation is the tested outcome).
3. Count accepted requests and completed responses; reconcile counts at the end.
4. Include a distinct `TB RESULT: PASS` marker only after all assertions pass.
5. Run the complete existing regression, not only the new test, and record simulator/version, command, test count, warnings, and results.
6. Report simulation findings separately from synthesis, timing, area, power, and hardware evidence.

## 4. Protocol and scope boundaries

- Do not implement multi-initiator tracking or new error semantics until the intended topology and transaction contract are agreed.
- Invalid-ID tests must follow an explicitly documented expected behavior; do not assume a safe default where the RTL does not define one.
- Reset behavior must be written as a project-level contract before using the test to claim compatibility with a real MIPS bus.
- Byte enables, transaction IDs, and multiple outstanding requests remain requirements questions, not implicit features of the current 65-bit request payload.

## 5. Suggested execution sequence

1. Obtain the exact target MIPS core/native bus documentation and peripheral/address map; keep this as the primary integration blocker.
2. Agree the reset contract, initiator count, response-source association, byte-enable semantics, and outstanding-request policy with the project owner.
3. Once topology is confirmed, add a multi-initiator response-association test and any required source-ID tracking; do not invent policy before requirements are known.
4. Add CPU-side request-stall assertions only after checking the actual native bus handshake contract.
5. Run and record the full regression after substantive verification changes; keep simulation evidence separate from synthesis/timing/hardware claims.

## Evidence boundary

This plan is derived from the checked-in end-to-end testbench and current README verification summary. It does not claim these proposed tests have been implemented or run, and it does not establish target-core, bus-standard, synthesis, or hardware compatibility.
