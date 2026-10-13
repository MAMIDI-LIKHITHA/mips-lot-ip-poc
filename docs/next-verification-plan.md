# LOT POC — Next Verification Plan

**Status:** Proposed verification work based on source inspection of `main`.  
**Scope:** Planning only. No RTL/testbench behavior is changed by this document, and no new simulation is claimed.

## 1. Current evidence baseline

The README reports a user-run ModelSim Intel FPGA Edition 2021.1 regression on 12 October 2026 with 11 tests passing, 0 failing, all 16 request routes covered, and a 500-cycle stress test with 1,175 accepted and 1,175 delivered transfers. These are local simulation results reported by the project, not hardware validation.

The checked-in end-to-end candidate testbench directly demonstrates:
- CONTROL and DATA writes/readbacks.
- STATUS and ID reads.
- Invalid endpoint register and unmapped-address error responses.
- Stability of a CPU response while `cpu_rsp_ready` is low for several cycles.

The testbench hardcodes the response source ID to source 0 and only instantiates one active candidate CPU-side initiator. Therefore, it does not demonstrate dynamic response association for multiple initiators.

## 2. Recommended tests, in priority order

| Priority | Test | Stimulus and required assertion | Why it matters |
|---|---|---|---|
| P0 | Request payload stability under CPU-side stall | Hold `cpu_req_valid=1` while `cpu_req_ready=0`; assert request fields remain stable and no duplicate LOT transfer occurs. | Protects request integrity when the downstream fabric applies backpressure. |
| P0 | Reset during outstanding transaction | Assert reset after request acceptance but before endpoint response; verify adapter, endpoint, and routers clear pending state and recover without phantom responses. | Reset cancellation semantics are not yet a native CPU-bus contract. |
| P0 | Reset while CPU response is stalled | Hold `cpu_rsp_ready=0` with a valid response, assert reset, then verify defined post-reset behavior and ability to accept a new request. | Exercises the response-hold state across reset. |
| P0 | Response-source association | Exercise at least two response destinations/source IDs and concurrent responses; verify data and error return only to the intended destination. | Current end-to-end harness hardcodes source ID 0. |
| P1 | Invalid response destination ID | Drive an ID outside the configured `N`-destination range and verify documented behavior without accidental routing or unknown propagation. | Routing behavior for out-of-range IDs should be explicit. |
| P1 | Back-to-back transactions | Complete one request and immediately offer the next; assert exactly one response per accepted request and document the throughput/bubble behavior. | Establishes the actual single-outstanding throughput contract. |
| P1 | Request crossbar destination changes under contention | Keep multiple contenders active while the selected output stalls, then release it; verify grant, payload, and round-robin progression. | Strengthens fairness and stability evidence for changing traffic. |
| P1 | Error response under backpressure | Stall an error response at the CPU and assert both error and data remain stable until consumed. | The existing end-to-end backpressure helper checks a successful STATUS read, not an error response. |
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

1. Add the two P0 reset tests and request-stall stability test to the candidate adapter testbench.
2. Add a dedicated response-router test for multiple destination IDs and invalid IDs.
3. Add a multi-initiator end-to-end test only after response-source association policy is agreed.
4. Run the complete regression and update the README with evidence from the actual run.
5. Keep any protocol-specific adapter changes on a separate reviewed branch after the target MIPS bus is identified.

## Evidence boundary

This plan is derived from the checked-in end-to-end testbench and current README verification summary. It does not claim these proposed tests have been implemented or run, and it does not establish target-core, bus-standard, synthesis, or hardware compatibility.
