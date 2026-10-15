# FPGA Target Readiness — OpenMIPS + LAN of Things

## Current target information

- Implementation class: FPGA
- Requested clock frequency: 100 MHz
- Nominal clock period: 10.000 ns
- FPGA vendor/family/device: not specified
- Board and package: not specified
- Top-level clock port and clock source: not specified
- FPGA synthesis/place-and-route tool and version: not specified

This document records the target-independent requirements. It is not a timing-constraints file and does not claim timing closure.

## Why no executable XDC/SDC is committed yet

A valid timing file must refer to real top-level ports and the actual clock source. A placeholder port name or invented device can make constraints silently ineffective or incorrect. Before generating executable XDC/SDC, identify:

1. Exact FPGA part number and package/speed grade.
2. Board clock source frequency, top-level clock port, and any clock-management IP.
3. The actual implementation top and whether generated memories/DSPs are vendor IP, inferred resources, or external black boxes.
4. Required I/O standards, pin assignments, and external input/output timing budgets, if applicable.
5. Toolchain and version (for example, Vivado for a supported Xilinx target or Quartus for a supported Intel target).

## Timing contract for the intended 100 MHz domain

- Nominal period: 10.000 ns.
- Create a primary clock on the confirmed top-level clock input.
- If a PLL/MMCM or other clock generator is present, constrain its generated clocks using the selected tool's supported syntax.
- Define asynchronous clock groups only after all clock domains and CDC paths are identified.
- Add input/output delays only when the external interface and board timing are known.
- Review unconstrained paths and clock-interaction reports; do not treat a clean synthesis run as proof that paths are constrained.
- Check worst negative slack, total negative slack, and timing constraints coverage after placement and routing.

The 10 ns value is a target requirement, not evidence that the current RTL meets it.

## Current synthesis evidence and limitations

The generic Yosys flow for `openmips_mips32_lot_system` passed in [CI run 38563738864](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38563738864). The generic report previously recorded 70,353 generic cells, 15,049 wires, and 108,739 wire bits.

These figures are not FPGA LUT/FF/BRAM/DSP utilization. The flow uses generic cells with ABC mapping disabled, and generated I-cache BRAM, D-cache BRAM, and DSP blocks are black boxes. Target-specific mapping and implementation must replace or correctly bind these black boxes before resource and timing results can be trusted.

## Required FPGA implementation sequence

1. Confirm target part, board clock input, implementation top, and toolchain.
2. Identify and bind target-specific memory/DSP implementations; verify inferred and instantiated resources.
3. Generate XDC/SDC using actual port names and clock topology.
4. Run target synthesis and inspect inferred resources, latches, black boxes, and critical warnings.
5. Run placement and routing; inspect timing constraints coverage and critical paths against 10 ns.
6. Resolve timing/resource issues and rerun until the target tool reports timing closure.
7. Run post-implementation checks and hardware bring-up; verify LOT transactions, reset/fault behavior, and memory-path integrity on the target board.

## Separate integration blockers

Target selection alone does not resolve the following architectural risks already identified in the integration review:

- The stock OpenMIPS top does not export all physical-address/cache-attribute sidebands needed for safe LOT qualification.
- A reset during an outstanding LOT transaction can orphan a late downstream response unless reset is coordinated or a drain/cancel contract is defined.
- Multi-initiator response association is not yet demonstrated; current tests do not prove concurrent multi-initiator correctness.
- The bridge has a sticky fault output but no CPU exception/error return path.

These must remain explicit review items before describing the system as hardware-ready.
