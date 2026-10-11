# Interconnect Options for the LOT POC

**Last reviewed:** 2026-10-11  
**Purpose:** Identify candidates to compare before freezing a custom LOT bus or crossbar interface.

## Starting point

The current POC has a custom, simple request/response contract and a 4×4 ready/valid crossbar. This is useful for exploring transaction routing, but it does not establish that a custom fabric is the best final integration choice. The target MIPS core and peripheral inventory must be known before making that decision.

## Candidates

| Candidate | What it is | Potential fit | Key checks | Tag |
|---|---|---|---|---|
| Keep the custom LOT fabric | Current local transaction router and 4×4 crossbar. | Best for continuing the existing POC and exploring LOT-specific routing semantics. | Define stable interface, error behavior, byte enables, IDs, address map, reset/clock assumptions and endpoint contract. Measure synthesis/timing only after selecting a target. | [Inference] |
| AMBA AXI | Standard on-chip interface family; Arm positions AXI for high-frequency/high-bandwidth interconnects. | Candidate if the selected CPU subsystem or IP ecosystem already exposes AXI. | Determine AXI variant, widths, burst/ordering requirements, outstanding transactions, bridges, and license/implementation terms for any third-party IP. | [Confirmed overview; fit is inference] |
| AMBA AHB | Arm positions AHB for embedded/low-latency systems. | Candidate for an embedded subsystem if the chosen core and peripherals support it. | Confirm actual MIPS core support; do not assume Arm protocol use merely because it is a MIPS design. | [Confirmed overview; fit is inference] |
| AMBA APB | Simple, low-bandwidth peripheral bus; Arm documentation describes a bridge from the main memory system to APB peripherals. | Candidate for control/status registers or a peripheral segment behind an appropriate bridge. | APB is not itself a replacement for a high-throughput fabric; confirm the need for an AXI/AHB-to-APB bridge and target peripheral bus compatibility. | [Confirmed overview/spec; fit is inference] |
| dpretet/axi-crossbar | Open-source parametric AXI4 crossbar written in SystemVerilog. | Candidate only if the CPU-side fabric is AXI4-compatible or can be bridged cleanly. | Review current license file, supported AXI features, verification evidence, issue/maintenance state, parameter constraints and timing behavior before adoption. | [Candidate identified; adoption checks open] |
| atfox272/AXI4-Interconnect | Another public AXI4 interconnect candidate identified during discovery. | Potential comparison candidate if AXI4 is the chosen protocol. | License and maintenance/support details have not been confirmed here; do not adopt until reviewed. | [Check] |

## Recommendation

**[Inference — medium confidence]** Do not replace the current POC crossbar with a third-party interconnect until the MIPS core, bus protocol and transaction requirements are identified. The practical decision order is:

1. Identify the selected MIPS core/subsystem and native bus.
2. Check whether existing bus bridges and a memory-mapped SPI controller are available.
3. Decide whether the LOT value lies in a custom transaction protocol or whether a standard AXI/AHB/APB-compatible fabric would meet the requirements.
4. Compare candidate IP using actual feature requirements, license, documentation, verification, integration cost, and synthesis/timing evidence.
5. Keep the current RTL as the functional reference until a replacement demonstrates equivalent required behavior.

## Primary sources

- Arm, [AMBA overview](https://www.arm.com/architecture/system-architectures/amba) — overview and intended positioning of AXI/AHB/APB.
- Arm, [AMBA specifications](https://www.arm.com/architecture/system-architectures/amba/amba-specifications) — authoritative specification index.
- Arm, [APB specification / documentation](https://www.arm.com/architecture/system-architectures/amba/amba-specifications) — use the relevant APB version from the official specifications page.
- GitHub, [dpretet/axi-crossbar](https://github.com/dpretet/axi-crossbar) — source repository; verify the current license and feature set directly before reuse.
- GitHub, [atfox272/AXI4-Interconnect](https://github.com/atfox272/AXI4-Interconnect) — secondary candidate; license and maintenance need review.

## Non-claims

This note does not claim that AMBA is the native bus of the selected MIPS core, that either open-source crossbar is suitable without modification, or that any candidate has been synthesized, timed, or hardware-validated in this repository.
