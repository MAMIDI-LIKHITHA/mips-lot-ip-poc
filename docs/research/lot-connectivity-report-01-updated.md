# LOT Connectivity Layer
## Research Report 01 — Updated for Stakeholder Review

**Prepared for:** Mihai Buta and Swapnil (MobilFlex)  
**Author:** Likhitha Mamidi  
**Date:** 11 October 2026  
**Status:** Preliminary research. No architecture/IP selection approved. No hardware tested.

> **Decision status:** No interconnect candidate is selected. Reusing a compatible SPI controller is an investigation hypothesis, not an approved architecture. The target MIPS core/bus, board, SDK, transaction requirements, licensing, and hardware behavior remain to be confirmed.

## Executive summary

The purpose of this report is to identify the best-fit existing building blocks for the LAN of Things (LOT) POC—not to justify a new crossbar by default. The current repository is a simulation-focused transaction-routing POC. It does not establish compatibility with a real MIPS subsystem, a specific SPI controller, or Silicon Labs hardware.

The most practical first investigation is to determine whether the target MIPS subsystem already has a compatible memory-mapped SPI controller. If the selected wireless device is a SiWx917 Network Co-Processor (NCP), a controller/driver and the vendor-defined host protocol are needed between the host subsystem and the NCP. Reuse an existing controller if it fits; consider a new controller or custom bridge only after documenting a concrete gap.

## 1. What the existing POC establishes

- The repository contains a custom ready/valid-style transaction-routing fabric and 4×4 crossbar intended for simulation exploration.
- The project README reports local ModelSim Intel FPGA Edition 2021.1 regression results. Treat these as repository/user-reported simulation evidence, not independent CI evidence or hardware validation.
- The current POC does not demonstrate a direct connection to the actual MIPS core, a production-standard AXI/AHB/APB bridge, a physical SPI controller, or a Silicon Labs device.
- The internal ready/valid contract is not by itself a complete CPU bus protocol. Request/response mapping, error semantics, address handling, outstanding-transaction behavior, reset recovery, and clock domains must be specified.

## 2. Correct interpretation of Silicon Labs options

Silicon Labs' current Matter hardware-requirements page describes a two-board Matter-over-Wi-Fi NCP configuration: an EFR32 host running Matter code and a SiWx917 or WF200 device running the Wi-Fi protocol stack. The same documentation separately describes SiWx917 SoC mode as a single-chip configuration. These are different system partitions; neither has been selected for MobilFlex. See the [official Matter hardware requirements](https://docs.silabs.com/matter/latest/matter-prerequisites/hardware-requirements) and [EFR32-host NCP guide](https://docs.silabs.com/matter/latest/matter-wifi-getting-started-example/getting-started-efx32-ncp).

Silicon Labs also documents a [SiWx917 RCP Linux-host example](https://docs.silabs.com/matter/2.8.0/matter-wifi-getting-started-example/getting-started-siwx917-rcp). It is a different integration pattern from the EFR32-host NCP example and should not be treated as interchangeable. The selected board, operating mode, SDK version, example/build configuration, and host transport must be confirmed together.

For a SiWx917 NCP using the documented [SPI host interface](https://docs.silabs.com/wifi-application-notes/1.0.4/wifi-siwx917-ncp-spi-protocol-application-note/), the host needs an SPI-main controller plus software/driver integration for the vendor protocol. Whether the MIPS subsystem already provides a compatible controller is unknown. Do not assume pin mappings, clock limits, or board behavior without the exact board schematic and SDK configuration.

Matter is an application-layer standard and Thread is a networking technology. A Thread border router is relevant only if the product must connect a Thread network to another IP network. A Wi-Fi-only Matter accessory does not automatically imply that LOT itself must implement border-router functionality. See the [OpenThread Border Router guide](https://openthread.io/guides/border-router) and [Connectivity Standards Alliance Matter overview](https://csa-iot.org/all-solutions/matter/).

## 3. Interconnect shortlist — no score and no winner

| Candidate | Potential role | Checks before selection |
|---|---|---|
| Current custom LOT fabric | Continue as the POC reference while requirements are clarified. | Stable interface contract; error/timeout behavior; arbitration and response association; synthesis/timing evidence if a target is chosen. |
| Arm CoreLink NIC-400-class interconnect | Commercial AMBA interconnect candidate only if the target subsystem has compatible interfaces and licensing/access is available. | Exact target bus; supported configuration; tool/access requirements; commercial terms confirmed directly with Arm. |
| PULP Platform AXI / axi_xbar | Public AXI infrastructure candidate if the selected bus is compatible or a justified adapter exists. | Exact revision and [license file](https://github.com/pulp-platform/axi/blob/master/LICENSE); dependencies; supported AXI features; verification and maintenance evidence; integration effort. |
| dpretet/axi-crossbar | Additional AXI4 crossbar candidate for comparison if AXI4 is confirmed. | Current [repository](https://github.com/dpretet/axi-crossbar), license, maintenance, AXI feature support, verification evidence, parameter constraints, and integration cost. |
| SiWx917 NCP / SoC / RCP options | External wireless connectivity architecture, not an on-chip crossbar replacement. | Exact board, operating mode, SDK/build, host interface, driver/software ownership, and vendor-supported configuration. |
| Matter / Thread | Application/networking requirements and stack placement. | Confirm product use case, network type, border-router scope, and which processor owns each stack. |

This is a qualitative, documentation-level shortlist—not a benchmark. No latency, throughput, area, power, timing, cost, or production-readiness ranking is claimed. Arm commercial terms have not been verified for this project. The current PULP license and all dependency obligations must be checked at the exact revision before adoption; this report is not a legal opinion.

## 4. Define the LOT transaction contract

- **Traffic type:** memory-mapped reads/writes, command/message transactions, streaming data, or a defined combination.
- **Topology:** number of initiators/targets and whether 4×4 connectivity is actually required.
- **Host interface:** exact protocol/version, address/data widths, byte enables, burst rules, IDs, ordering, and maximum outstanding requests.
- **Response behavior:** error responses, unmapped addresses, timeouts, reset while requests are pending, and source association during contention.
- **Flow control and clocking:** arbitration/fairness, backpressure, clock/reset domains, and whether CDC logic is required.
- **External-device boundary:** SPI/UART/SDIO interface, controller/driver ownership, buffers, interrupts/handshake signals, and who owns Matter/Thread/network software.
- **Acceptance criteria:** measurable latency/throughput targets, expected concurrent traffic, verification cases, and hardware validation plan.

## 5. Decision gates and requested input

| Gate | Action | Evidence needed to proceed |
|---|---|---|
| 1. Identify the host | Confirm the exact MIPS core/subsystem and native bus; inventory existing SPI/UART controllers and memory-mapped peripherals. | Core/vendor documentation or subsystem RTL; widths, handshake, address map, clocks and resets recorded. |
| 2. Confirm product role | Decide whether LOT is device-side connectivity only or must support Thread border routing. | Written scope from Mihai/Swapnil. |
| 3. Confirm wireless setup | Select a Silicon Labs mode/board and SDK/example version for evaluation. | Official guide and exact board schematic/configuration reviewed; host interface and stack ownership recorded. |
| 4. Compare reusable IP | Evaluate compatible interconnects only after the bus and requirements are known. | Feature matrix, exact revision/license, dependencies, support/maintenance, test evidence, integration estimate. |
| 5. Prototype and validate | Reuse a compatible SPI controller if available; otherwise compare a new controller with a custom bridge. Then run simulation, synthesis/timing and board tests as appropriate. | Reproducible functional results and, when hardware is available, measured timing/resource and interoperability evidence. |

> **Decisions requested from Mihai and Swapnil:** (1) LOT product role; (2) target MIPS core and bus; (3) preferred Silicon Labs mode/board, if any; (4) who will coordinate vendor technical and licensing questions. Until these are answered, keep the IP decision open.

## 6. Source traceability and limitations

The following public documentation pages were opened during this revision on 11 October 2026. They support the specific statements noted above, but do not prove MobilFlex's selected hardware, license entitlement, or implementation compatibility. Exact board revision, SDK release, build configuration, and legal/commercial terms still need confirmation.

- [Silicon Labs — Matter hardware requirements](https://docs.silabs.com/matter/latest/matter-prerequisites/hardware-requirements)
- [Silicon Labs — Matter over Wi-Fi with EFR32 host in NCP mode](https://docs.silabs.com/matter/latest/matter-wifi-getting-started-example/getting-started-efx32-ncp)
- [Silicon Labs — Matter with SiWx917 RCP and Linux host](https://docs.silabs.com/matter/2.8.0/matter-wifi-getting-started-example/getting-started-siwx917-rcp)
- [Silicon Labs — SiWx917 NCP SPI protocol application note](https://docs.silabs.com/wifi-application-notes/1.0.4/wifi-siwx917-ncp-spi-protocol-application-note/)
- [Arm — AMBA overview](https://www.arm.com/architecture/system-architectures/amba)
- [Arm — AMBA specifications index](https://www.arm.com/architecture/system-architectures/amba/amba-specifications)
- [PULP Platform AXI crossbar source](https://github.com/pulp-platform/axi/blob/master/src/axi_xbar.sv)
- [PULP Platform AXI license file](https://github.com/pulp-platform/axi/blob/master/LICENSE)
- [dpretet/axi-crossbar repository](https://github.com/dpretet/axi-crossbar)
- [OpenThread — Border Router guide](https://openthread.io/guides/border-router)
- [Connectivity Standards Alliance — Matter overview](https://csa-iot.org/all-solutions/matter/)

This is preliminary engineering research, not a complete source audit, legal opinion, vendor confirmation, or hardware test report. The exact MIPS core, bus, target board, SDK version, product requirements, and license terms remain unresolved. New evidence should be tagged as **confirmed**, **inference**, or **to-check**.
