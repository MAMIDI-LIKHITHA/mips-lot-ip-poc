# LOT POC Acceptance Criteria and Next Steps

**Status:** Proposal for owner review; not an approved product specification  
**Date:** 2026-10-12  
**Related research:** [LOT Research Brief](lot-research-brief.md) · [MIPS/interface note](03_mips_interface.md) · [Bus compatibility matrix](mips-bus-compatibility-matrix.md)

## Purpose

Turn the existing simulation POC and MobilFlex's public LOT product goals into a small set of decisions, measurable verification targets, and an implementation sequence. This document builds on the existing RTL and reported regression; it does not replace the project owner's target-interface requirements.

## Current baseline and evidence boundary

The repository currently contains a candidate MMIO adapter, LOT transaction routing, a 4×4 ready/valid crossbar, behavioral endpoints, response routing, and a ModelSim regression flow.

The latest reported local run used ModelSim Intel FPGA Edition 2021.1 and passed 12 testbenches with zero failures. The route-coverage test exercised all 16 source/destination combinations. Treat this as reported simulation evidence only; it is not CI evidence, hardware validation, native host-bus compatibility, or proof of 16 simultaneous end-to-end M2M transactions.

## Decisions required from the project owner

Do not freeze the host adapter or add protocol-specific RTL until these are answered:

1. **Host:** exact CPU/core or subsystem, repository/IP version, and whether MIPS is mandatory.
2. **Native interface:** bus/protocol and version, address/data widths, byte enables, request/response handshake, error behavior, outstanding requests, bursts, IDs/tags, ordering, clock/reset, and address map.
3. **Meaning of “16 concurrent M2M transactions”:** choose one explicit definition:
   - all 16 crossbar source/destination routes are exercised;
   - 16 transactions are accepted and remain outstanding before all responses complete; or
   - 16 end-to-end device exchanges are in flight across specified endpoints.
4. **First endpoint and controller:** concrete device/protocol, existing controller availability, register map, clock/reset, interrupts, and physical interface.
5. **Demonstration level:** simulation only, FPGA emulation, or physical hardware.
6. **Host-impact claim:** agreed baseline, workload, host model/platform, and metric for stalls, cycles, throughput, or utilization.

## Candidate integration options

These are options to compare after the target is confirmed, not a ranking of compatible IP.

| Option | Where it fits | Advantages | Checks / limitations |
|---|---|---|---|
| Keep and harden the custom 4×4 RTL | Current candidate POC | Direct control over arbitration, ready/valid behavior, response routing, and testbench | Verify buffering, fairness, response association, reset/error semantics, synthesis and timing; do not infer concurrency from route coverage |
| Reuse an existing standard-bus interconnect | If the selected host exposes a compatible standard bus | May reduce custom integration and leverage established interface conventions | Verify exact protocol/version, widths, outstanding/ID support, license, tooling, and whether its topology meets LOT needs |
| Add a host-bus adapter around the existing LOT fabric | Once the native host interface is confirmed | Keeps host-specific behavior isolated from the fabric | Requires a written interface contract and tests for stalls, errors, reset, ordering and outstanding transactions |
| Reuse an existing peripheral controller | First endpoint has a compatible memory-mapped controller | Keeps physical-protocol timing and device-specific behavior outside the crossbar | Confirm controller, register map, FIFO/DMA/interrupt behavior, clocks, reset, pin mux, and license |
| Add a protocol-specific controller or bridge | Only if the selected target lacks a reusable compatible controller | Enables a concrete endpoint demonstrator | Expands scope; requires a separate protocol contract and verification plan |

### Core-selection guidance

Do not select a new CPU just to make progress on the fabric. Prefer the actual project-owner core and its documented native bus. If no core is supplied and the owner approves a reference implementation, evaluate a documented MIPS core such as OpenMIPS for a genuine MIPS reference path. A RISC-V core such as PicoRV32 can be a protocol/fabric demonstrator only if the owner explicitly accepts that it does not satisfy a MIPS-core requirement. Check repository activity, license, interface semantics and integration effort before adoption.

## Proposed acceptance matrix

All thresholds below are proposals for review. Owner approval is required before they become release criteria.

| ID | Test | Proposed pass condition | Evidence |
|---|---|---|---|
| A1 | Route correctness | Exercise all 16 source/destination combinations; verify destination, payload and response path | Per-route coverage and scoreboard |
| A2 | Defined concurrency | If the agreed requirement is 16 outstanding transactions, observe at least 16 accepted requests not yet completed at once | Counter/assertion for accepted minus completed requests; transaction log |
| A3 | Response integrity | Every accepted request completes exactly once with matching source/ID and expected data/status | Scoreboard; no missing, duplicate or misrouted responses |
| A4 | Backpressure | Hold a destination not-ready for multiple cycles; requests remain stable while stalled and complete after readiness returns | Assertions and directed/randomized tests |
| A5 | Contention/fairness | Multiple sources target the same destination; no loss, and progress meets an owner-approved fairness bound if one is required | Contention test and per-source progress counters |
| A6 | Reset recovery | Reset with requests pending; no stale response is associated with post-reset traffic; the fabric returns to an agreed idle/ready state | Reset-during-traffic test |
| A7 | Invalid address/error | Invalid targets and endpoint errors return the defined error behavior without corrupting unrelated traffic | Directed tests and scoreboard |
| A8 | Host adapter contract | Native request/response timing, byte enables, address mapping, ordering and any ID/outstanding rules match the selected interface specification | Interface-level tests against the agreed contract |
| A9 | Performance | Measure latency/throughput under a documented workload and clock; compare with an agreed baseline | Reproducible logs and configuration |
| A10 | Host impact | Only claim reduced CPU work if the agreed host model/platform and before/after measurement demonstrate it | Cycle/stall/utilization evidence; simulation-model limits disclosed |

### Important interpretation

A 4×4 crossbar has 16 source/destination combinations. Testing those combinations establishes route coverage, not 16 simultaneously outstanding transactions. Also, a design cannot accept 16 outstanding requests unless its buffering, arbitration, transaction bookkeeping, and response association support the agreed traffic model. Inspect the current transaction and response routers before deciding whether IDs, queues, or per-source tracking are required.

If the agreed requirement is 16 end-to-end device exchanges, the test must model the specified endpoint/controller path and define exactly when an exchange starts and completes. Do not equate crossbar requests with complete device-level transactions without that definition.

## Suggested delivery sequence (indicative 4–6 week plan)

| Phase | Work | Exit evidence |
|---|---|---|
| Week 1 — scope and contract | Confirm host/bus, concurrency definition, endpoint, demonstration level, baseline and acceptance criteria; compare viable interconnect choices | Owner-approved block diagram, interface contract and test plan |
| Weeks 2–3 — integration | Implement only the agreed adapter/bridge and connect the selected endpoint model; preserve the current passing regression | Compilation clean; new interface and endpoint tests pass |
| Week 4 — verification | Add concurrency scoreboard/assertions, backpressure, contention, reset and error tests; run full regression | Logs, coverage, scoreboard summary and documented limitations |
| Weeks 5–6 — optional target validation | Synthesis/timing/resource analysis, FPGA emulation or physical endpoint integration if tools and hardware are available | Tool reports and reproducible evidence for the agreed milestone |

The schedule is indicative. It depends on timely access to the target RTL/specification, endpoint/controller, toolchain, and hardware if needed.

## Immediate next actions

1. Send the owner the six decision questions above and request the actual interface document or RTL.
2. In parallel, inspect the existing transaction router and response router to determine whether multiple outstanding transactions are supported today; record findings without changing architecture.
3. Keep the current 12-test passing regression as the baseline.
4. Once the owner defines “16 concurrent,” implement a dedicated test and scoreboard for that exact definition.
5. Only after the host and endpoint are confirmed, choose the adapter/controller approach and update the interface note and compatibility matrix.
6. Do not claim native bus compatibility, real CPU-utilization reduction, synthesis/timing closure, or hardware validation until matching evidence exists.

## External references for candidate evaluation

- [OpenMIPS repository](https://github.com/grantae/OpenMIPS) — possible MIPS reference candidate; evaluate its native interface and license before use.
- [PicoRV32 repository](https://github.com/YosysHQ/picorv32) — possible RISC-V fabric/interface demonstrator only if a non-MIPS reference is accepted.
- [MobilFlex official website](https://mobil-flex.com/) — public product context; public product claims are not a substitute for a target RTL/interface contract.

