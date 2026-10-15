# FPGA implementation readiness

Status date: 15 October 2026

## Current evidence

The integrated `openmips_mips32_lot_system` passes the repository's generic Yosys synthesis smoke workflow ([run 38563738864](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38563738864)). This is a useful RTL/elaboration check, not FPGA implementation evidence. The generic report is documented in [OpenMIPS generic synthesis](openmips-generic-synthesis.md).

The project has a requested **100 MHz target clock intent** (10 ns period), but the FPGA vendor, exact part, board, package/speed grade, top-level clock port, I/O standards, and toolchain are not yet specified. No device-specific constraints or timing-closure claims are made here.

## Target-independent gates before implementation

1. **Freeze the target.** Record FPGA vendor, exact part number, package/speed grade, board revision, and supported tool version.
2. **Confirm the synthesis top.** Verify the intended hardware top, all source files, generated memory/DSP IP, and all black-box implementations. The current generic synthesis flow deliberately treats generated cache BRAM/DSP modules as black boxes.
3. **Define clocks and resets.** Confirm the real clock input port, oscillator frequency, clock-generation/reset behavior, and whether 100 MHz is an input clock or a generated internal clock. A 10 ns clock constraint is only valid after this is known.
4. **Constrain I/O from the board/interface specification.** Set pin locations, I/O voltage standards, input/output delays, drive/slew settings, and any asynchronous interface exceptions only from the selected board and interface timing documents. Do not guess pins or voltage standards.
5. **Resolve memory and DSP implementation.** Replace simulation/generic black boxes with the intended vendor IP or inferable RTL; document depth, width, read latency, byte enables, initialization, and collision semantics.
6. **Run target mapping and implementation.** Capture synthesis utilization (LUTs, registers, BRAM, DSP, clocking), placement/routing results, and static timing analysis. Check setup/hold and unconstrained paths, not only the headline worst slack.
7. **Verify the 100 MHz goal.** Require the final implementation's timing report to show the 10 ns requirement is met on all required synchronous paths, with tool/version, constraints, and report artifacts retained.
8. **Validate on hardware.** Test reset/start-up, ordinary RAM traffic, cache-line fills/writebacks, LOT read/write, invalid/high-address rejection, error handling, and sustained traffic. Simulation and generic synthesis do not substitute for this gate.

## Current known blockers / risks

- Device and board are not selected, so vendor-specific mapping and pin/timing constraints cannot be validly authored yet.
- The generic Yosys report excludes target-specific resource mapping; generated cache BRAM/DSP blocks are black boxes.
- The native cache integration requires source-specific qualification patches and a defined physical-address/cache-attribute path.
- The native memory interface has no CPU-visible exception/error response for rejected accesses; system-level fault policy remains an integration decision.
- Reset while a LOT request is outstanding needs a system contract for cancellation/draining and late responses.
- Multi-initiator response/source-ID association has not been established by the current single-initiator regression.

## Required inputs to make the next step executable

- FPGA vendor and exact part (or board model/revision).
- Vendor toolchain and version, if already chosen.
- Actual top-level clock port and board oscillator frequency.
- Board pinout and I/O voltage standards.
- Whether the 100 MHz requirement applies to the host core, LOT interconnect, SPI/peripheral domain, or all of them.

Until these are supplied, continue target-independent RTL regression and generic synthesis only. Do not publish LUT/BRAM estimates, Fmax, power, or timing closure as verified results.
