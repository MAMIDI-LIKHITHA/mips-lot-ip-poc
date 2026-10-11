# Existing interconnect and connectivity IP — initial research

**Purpose:** Give the LOT POC team traceable starting points for evaluating reusable IP, following the QRPD principle of reusing the best-fit existing building blocks.

**Status:** Research shortlist only. No candidate has been selected or integrated. Product availability, license terms, commercial eligibility, and compatibility must be confirmed before a decision.

## Keep two problems separate

1. **On-chip interconnect / switch:** connects a CPU-side master interface to internal peripherals or transaction endpoints. It must match the actual bus protocol, address map, transaction ordering, IDs, error semantics, and timing requirements.
2. **External connectivity:** carries data to networked devices over technologies such as Wi-Fi, Thread, or Ethernet. Bluetooth LE can be used for Matter commissioning. A radio/network device is not a substitute for an on-chip AXI/AHB/APB interconnect.

Matter is an application-layer interoperability standard over IP-based networks; the Connectivity Standards Alliance describes Wi-Fi, Thread, and Ethernet as supported network technologies. See the [CSA Matter overview](https://csa-iot.org/all-solutions/matter/) and [CSA Matter security and privacy paper](https://csa-iot.org/developer-resource/white-paper-matter-security-and-privacy-copy/).

## Candidate 1 — Arm CoreLink NIC-400

- **What it is:** Configurable AMBA interconnect IP supporting AXI4, AXI3, AHB-Lite, and APB, according to Arm's product page.
- **Why investigate:** It is a vendor-supported candidate if the selected CPU and peripherals expose compatible AMBA interfaces and project access terms fit the business plan.
- **Key checks:** Identify the exact MIPS core/native bus first; confirm whether an adapter is needed; verify current licensing/access eligibility directly with Arm; check supported configuration, deliverables, tool requirements, and commercial terms.
- **Primary sources:** [Arm CoreLink interconnect family / NIC-400](https://www.arm.com/products/silicon-ip-system/corelink-interconnect/nic); [Arm NIC-400 Technical Reference Manual](https://documentation-service.arm.com/static/5f5a411f235b3560a01eb5ce).

**Important:** This source does not establish that NIC-400 is free for this project or that the specific commercial threshold mentioned in discussion applies to this IP. Confirm terms with Arm.

## Candidate 2 — PULP Platform AXI

- **What it is:** Open-source SystemVerilog AXI infrastructure. The project's `axi_xbar` documentation describes a configurable fully connected AXI4 crossbar with address mapping and response routing.
- **Why investigate:** Source and documentation are publicly inspectable, making it a traceable candidate for adapting an AXI-based design without writing a new crossbar from scratch.
- **Key checks:** Confirm the exact license and obligations for the selected revision; establish that the chosen CPU adapter can speak AXI; compare required features (IDs, response errors, ordering, backpressure, parameterization) and run the upstream verification plus project-specific integration tests.
- **Primary source:** [PULP Platform AXI crossbar documentation](https://github.com/pulp-platform/axi/blob/master/doc/axi_xbar.md).

## Candidate 3 — dpretet/axi-crossbar

- **What it is:** An open-source, parameterizable AXI4 crossbar implemented in SystemVerilog; the repository describes configurable master/slave counts and address-decoded request routing.
- **Why investigate:** Another traceable implementation to compare against PULP AXI if the target bus is AXI-compatible.
- **Key checks:** Inspect the repository's current license, maintenance/activity, supported AXI features, test coverage, and integration constraints before use.
- **Primary source:** [dpretet/axi-crossbar repository](https://github.com/dpretet/axi-crossbar).

## Silicon Labs and Matter connectivity

Silicon Labs documents SiWx917 in at least two relevant configurations:

- **SoC mode:** The SiWx917 is used as a single-chip platform for Matter over Wi-Fi, with integrated processing and networking stacks.
- **NCP mode:** A host MCU communicates with a SiWx917 network co-processor. Silicon Labs' documentation includes NCP configurations and, for specific Matter + AWS dual-stack designs, an SPI NCP interface between an EFR32 host and the SiWx917 NWP.

These are different integration models. Do not assume the current LOT POC connects to either model; the host interface, selected part/board, firmware mode, and command/data contract remain to be chosen.

- [Silicon Labs Matter hardware requirements](https://docs.silabs.com/matter/latest/matter-prerequisites/hardware-requirements)
- [Silicon Labs Matter + AWS dual-stack overview](https://docs.silabs.com/matter/latest/matter-aws-feature/matter-aws-dual-stack-overview)
- [CSA Matter overview](https://csa-iot.org/all-solutions/matter/)

**Open vendor question:** The documentation above identifies available product modes, but does not establish that Silicon Labs exposes a customizable internal switch/crossbar IP suitable for LOT. That needs a direct vendor answer.

## Evaluation matrix

| Candidate | Layer | Interface dependency | Initial reason to evaluate | Main unresolved items |
|---|---|---|---|---|
| Arm CoreLink NIC-400 | On-chip interconnect | AMBA AXI/AHB-Lite/APB | Configurable commercial interconnect | License/access terms; target bus compatibility |
| PULP Platform AXI | On-chip interconnect | AXI | Public source and detailed AXI crossbar docs | License obligations; AXI adaptation; feature fit |
| dpretet/axi-crossbar | On-chip interconnect | AXI4 | Parameterizable open-source implementation | License/maintenance; feature and verification fit |
| Silicon Labs SiWx917 | External connectivity device | SoC or host/NCP interface depends on mode | Candidate Wi-Fi / Matter connectivity platform | Exact part/mode, host protocol, SDK/firmware fit, vendor customization options |
| Matter / Thread ecosystem | Network/application connectivity | IP over Wi-Fi/Ethernet/Thread; BLE commissioning | Defines interoperable network/application ecosystem | Does not itself provide the on-chip bus switch |

## Recommended decision sequence

1. **Identify the actual CPU/core and its native bus** (including request/response semantics, widths, IDs, reset, and error behavior).
2. **Write a minimal requirements checklist** for the switch: number of initiators/targets, address decode, arbitration, outstanding requests, ordering, response routing, error handling, backpressure, clock/reset domains, and licensing constraints.
3. **Shortlist only compatible reusable IP.** If the host interface is not AXI/AMBA, determine whether a small, justified bridge is practical before choosing an AXI crossbar.
4. **In parallel, define the external connectivity boundary:** target Silicon Labs part and SoC/NCP mode, host interface, Matter/Thread/Wi-Fi requirements, and what traffic LOT is expected to transport.
5. **Ask vendors precise questions** and record answers with date/contact/reference. Do not infer access rights or customization support from sponsorship of Matter.
6. **Integrate and verify a selected candidate** only after the interfaces and requirements are agreed.

## Current POC boundary

The repository's existing crossbar is a simulation POC component, not evidence that a custom crossbar should be retained in a future implementation. This research does not select or replace it. The actual MIPS core/bus, reusable interconnect, Silicon Labs part/mode, and network-facing interface remain open decisions.
