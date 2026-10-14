# FPGA implementation readiness: 100 MHz target

## Current decision

- **Implementation class:** FPGA.
- **Requested clock target:** 100 MHz, equivalent to a 10.000 ns clock period.
- **Device / family / package:** not specified.
- **Vendor toolchain:** not specified.
- **Top-level FPGA wrapper and clock-port name:** not yet selected/confirmed.
- **Pinout, I/O standards, external interface timing, and board oscillator details:** not specified.

This document records the known target and gates the next implementation stage. It does not constitute a usable board constraint file or evidence of timing closure.

## What the existing synthesis result means

The generic Yosys flow is a useful RTL/elaboration sanity check and produces a generic netlist/statistics artifact. It is **not** a vendor FPGA mapping or place-and-route result. Do not interpret generic cell counts as LUTs, registers, BRAMs, DSPs, or device utilization. The current generic flow also does not establish that the design meets 100 MHz.

## Timing budget

A 100 MHz clock has a nominal period:

`T = 1 / 100{,}000{,}000 = 10 ns`

The 10 ns period is the requested clock period, not a claim that every internal path has 10 ns of usable logic delay. Clock uncertainty, setup time, clock-to-Q, routing, generated clocks, and interface timing affect the actual path budget.

## Do not guess these constraints

Do not commit active XDC/SDC commands for the following until the top-level design and target are known:

- Clock port names, oscillator source, clock waveform, and any PLL/MMCM-generated clocks.
- Package pin locations and I/O standards.
- Input/output delays, which must be derived from the real external interface timing and board assumptions.
- False paths, multicycle paths, asynchronous clock groups, or other exceptions. Every exception needs an architectural justification; do not use exceptions to hide failing paths.
- Device part, speed grade, synthesis settings, and implementation strategy.

A constraint file with a guessed port or guessed pin can silently constrain the wrong object or fail to constrain the design. Vendor tools also differ in project setup and reporting flow. AMD documents XDC as sequentially interpreted constraints, while Intel Quartus uses SDC-based timing constraints; see the references below.

## Required inputs before implementation

1. **Exact FPGA part or development board** (family, device, package, speed grade if known).
2. **Toolchain and version** (for example, AMD Vivado or Intel Quartus; do not assume one).
3. **Actual synthesizable top module** and the exact primary clock/reset port names.
4. **Clock source details** (nominal frequency, oscillator tolerance/jitter if available, and PLL/MMCM use).
5. **External interfaces to be constrained** (including device timing and board-level delays, if applicable).
6. **Resource expectations** (optional but useful: LUT/FF/BRAM/DSP budget or utilization ceiling).

## Implementation sequence after those inputs arrive

1. Confirm the synthesis top and RTL file list; distinguish the full OpenMIPS integration from the smaller LOT fabric.
2. Add a vendor-specific project/constraint entry point with a 10.000 ns primary clock on the verified port.
3. Add only justified I/O timing constraints and generated-clock definitions.
4. Run vendor synthesis, inspect inferred memories and black boxes, and record warnings.
5. Run implementation/place-and-route and timing analysis for the selected device.
6. Report worst negative slack, total negative slack, constrained/unconstrained paths, resource utilization, and critical-path details. Treat a run as passing only when the tool's timing and constraint checks support that conclusion.
7. Re-run functional regressions after any RTL changes made for timing or resource optimization.

## Current blockers and independent RTL verification work

Target-specific implementation is blocked by the missing device, toolchain, top-level clock port, and physical interface constraints. Work that does not require those choices can continue in parallel:

- Strengthen reset/late-response and fault-policy verification.
- Define response-source association before enabling multiple concurrent initiators.
- Resolve the CPU-visible error/exception policy for bridge faults.
- Review the pinned OpenMIPS source license and redistribution obligations before packaging or publishing a derived hardware bundle.

## References

- AMD, *Recommended Constraints Sequence (Vivado Design Methodology Guide)*: https://docs.amd.com/r/2024.2-English/ug949-vivado-design-methodology/Recommended-Constraints-Sequence
- Intel, *Creating Base Clocks (Quartus Prime Pro Timing Analyzer)*: https://www.intel.com/content/www/us/en/docs/programmable/683243/24-1/creating-base-clocks.html
