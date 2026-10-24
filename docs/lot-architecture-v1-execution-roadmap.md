# LOT Architecture v1 — GitHub Execution Roadmap

**Authority:** [LOT Complete Architecture Specification v1.0](architecture/lot-complete-architecture-specification-v1.md)  
**Status:** Gate 0 accepted by the project owner; existing-project simulation and verification is the immediate next step. No hardware validation implied.  
**Rule:** Verify the current RTL baseline before adding architecture-driven RTL. Do not start target-specific adapter RTL until the host core/bus and owner-approved scope are recorded.

## Gate 0 — Owner decisions (accepted for planning)

The project owner has confirmed Gate 0 is OK. Treat this as authorization to proceed with simulation/verification of the existing POC, not as proof that unresolved target-specific choices (production MIPS core/bus, board, SDK, licenses or performance targets) have been technically verified. Record any specific owner answers separately as they become available.

- [ ] Confirm LOT role: device-side connectivity only or another explicitly defined role; initial proposal excludes Thread border router.
- [ ] Confirm Wi-Fi-first scope and whether BLE/Matter is in the first deliverable.
- [ ] Name the target FPGA board, device/part, exposed pins, I/O voltage and toolchain.
- [ ] Ask MIPS which core is available in FPGA form and obtain written permission/license terms.
- [ ] Select/confirm the exact SiWx917 NCP board, adapter, SDK release and example configuration.
- [ ] Name MobilFlex contacts for MIPS and Silicon Labs.
- [ ] Agree deadline, definition of done, throughput/latency/CPU targets, and Swapnil's x86 comparison method.
- [ ] Record each answer with source/evidence and date; unanswered questions remain explicitly open.

**Gate exit:** no hidden assumptions; all blocking unknowns are answered or explicitly accepted as open by the project owner.

## Gate 0.5 — Verify the existing LOT/MIPS POC (immediate priority)

- [ ] Run the current regression from a clean checkout using the documented simulator/version and command.
- [ ] Capture the commit SHA, simulator/version, exact command, compile errors/warnings, each test result, and final exit status.
- [ ] Reconcile the documented 12-test ModelSim baseline with the current source tree; do not assume historical PASS results still reproduce.
- [ ] Run available Icarus Verilog unit tests and the existing OpenMIPS/LOT bridge and CPU-level tests where scripts and dependencies support them.
- [ ] Inspect every failure and warning; fix real defects and explain any accepted tool-specific warning with evidence.
- [ ] Confirm the end-to-end transaction path: candidate CPU/MMIO bridge → LOT router → request crossbar → endpoint/register model → response crossbar/router → CPU-side response.
- [ ] Verify read/write data, response source association, invalid/unmapped addresses, reset during outstanding traffic, backpressure stability/recovery, contention/fairness, and deterministic timeout behavior.
- [ ] Check route/function coverage and stress counters; add missing tests only where a real gap is confirmed.
- [ ] Ensure CI runs all portable deterministic tests. Keep ModelSim-only checks explicit if the CI runner cannot legally or technically run ModelSim.
- [ ] Publish a verification report with pass/fail matrix and links to logs/workflow runs. Do not claim hardware, timing closure, or target-specific performance from simulation.

**Gate exit:** clean reproducible regression with all expected tests passing, warnings triaged, end-to-end behavior evidenced, and known limitations recorded. If failures remain, the gate stays open and fixes take priority over new feature RTL.

## Gate 1 — Freeze interfaces and inventory reusable IP

- [ ] Record host protocol/version, widths, byte enables, wait/ready behavior, error responses, bursts/IDs/outstanding policy, ordering, clocks/resets and address map.
- [ ] Inventory existing memory-mapped SPI, GPIO, UART, timer, interrupt controller, bridge and driver.
- [ ] Confirm APB4 as the proposed peripheral contract with the owner.
- [ ] Evaluate AHB-Lite→APB path only if AHB-Lite host is selected; locate/verify bridge implementation and license.
- [ ] Evaluate PULP AXI modules only if the confirmed host makes the AXI path viable; pin exact revisions and review licenses/dependencies.
- [ ] Verify SPI master mode 0, software-controlled chip select, reset/interrupt/wake requirements and 25 MHz initialization limit against exact AN1432/SDK.
- [ ] Confirm no crossbar is needed for one initiator; add one only when an additional initiator (such as DMA) is approved.
- [ ] Approve or revise the proposed `lot_rlink` register map before software/RTL depend on it.

**Gate exit:** reviewed interface contract, peripheral inventory, source/license notes, and approved register map. No production bus adapter before this gate.

## Gate 2 — Simulation-first `lot_rlink` and radio model

- [ ] Define register reset values, access semantics, FIFO behavior, W1C IRQ behavior, timeout and reset recovery.
- [ ] Build/choose SPI master only after mode-0 and chip-select requirements are verified.
- [ ] Implement the SystemVerilog radio model with initialization response, BOARD READY/CARD READY, LOADFIRMWARE response, interrupts and no-response fault injection.
- [ ] V1: host model reads/writes registers.
- [ ] V2: radio model returns expected initialization response.
- [ ] V3: unmapped address returns an error without hanging.
- [ ] V4: SPI_ERR_INTR triggers documented reinitialization.
- [ ] V5: reset during transfer recovers.
- [ ] Add deterministic timeouts and explicit pass markers; run the full regression and record simulator/version/warnings.
- [ ] Do not call the radio model vendor-conformant until its token sequence is checked against the exact source release.

**Gate exit:** V1–V5 pass in CI/local simulator; report results and limitations.

## Gate 3 — Software/HAL bring-up

- [ ] Pin the WiSeConnect SDK release and identify the 12 host functions and CMSIS-RTOS2 requirements for that release.
- [ ] Port host init/deinit, SPI transfer, optional high-speed switch, reset, wake/sleep, interrupt enable/disable and ISR/event dispatch.
- [ ] Select RTOS or justify a minimal supported CMSIS-RTOS2 layer.
- [ ] Test NULL TX/RX buffers and maximum buffer length according to the selected SDK contract.
- [ ] Reach BOARD READY and CARD READY in firmware-in-the-loop simulation.
- [ ] Verify error/timeout/reinitialization and interrupt behavior.

**Gate exit:** V8 passes in simulation; SDK and RTOS versions are recorded.

## Gate 4 — FPGA build and board validation

- [ ] Confirm FPGA part, pin assignments, voltage levels/level shifters, board clocks and programming/console path.
- [ ] Add pin constraints and SPI output-delay constraints; check reset and CDC assumptions.
- [ ] Run target synthesis/implementation and record resources, timing constraints, achieved timing and warnings.
- [ ] V6: timing and resources recorded for the selected board/toolchain.
- [ ] Verify SPI wiring and waveforms with analyzer; V7 passes.
- [ ] Verify reset sequence, BOARD READY and CARD READY on real radio; V8 passes on board.
- [ ] Join Wi-Fi and record V9 throughput.
- [ ] Keep board results separate from generic Yosys synthesis and simulation results.

**Gate exit:** V6–V9 evidence attached/linked, with board/FPGA/tool/SDK versions.

## Gate 5 — Baseline performance before offload

- [ ] Disable serial logging during measurement.
- [ ] Measure throughput, CPU cycles/frame, CPU cycles/Mbit, interrupts/sec and frame latency.
- [ ] Agree the comparison methodology with Swapnil and record the x86 baseline's environment and workload.
- [ ] Publish raw measurements, scripts, conditions, repetitions and limitations.
- [ ] Decide whether interrupt/copy cost justifies DMA and interrupt coalescing.

**Gate exit:** baseline report approved. Offload remains out of scope unless measured baseline justifies it.

## Gate 6 — Optional DMA/offload

- [ ] Confirm second bus initiator and therefore crossbar need.
- [ ] Define descriptor ring format, ownership, alignment, error handling, queue size, N-frame/timer coalescing and reset semantics.
- [ ] Add tests for descriptor wrap, full/empty queue, reset, malformed descriptors, interrupt coalescing and data integrity.
- [ ] Repeat the same workload and metrics as the software baseline.
- [ ] Record measured improvement or documented no gain.

## Gate 7 — Extension scope

- [ ] Thread: decide radio and UART/SPI host path; implement Spinel/OpenThread integration if approved.
- [ ] Ethernet: choose MAC/PHY and validate stream-to-memory bridge/DMA needs.
- [ ] BLE/Matter commissioning: only proceed after decision on R12 and host memory/CPU budget.
- [ ] Key storage/security and certification scope are explicitly decided before claims of product readiness.

## Repository process rules

1. Every architecture decision should link the owner decision, source, date, and status (Confirmed / Inference / Proposal / Check).
2. Every implementation PR states the gate it advances, acceptance criteria, tests run and evidence links.
3. CI must test deterministic RTL behavior; hardware-only criteria remain manual evidence until hardware automation exists.
4. Never mark a gate complete from a plan or source inspection alone. Link logs, workflow run, waveform or board measurement.
5. Keep production host/core choice, licensing, target-specific timing and hardware validation open until supported by evidence.
