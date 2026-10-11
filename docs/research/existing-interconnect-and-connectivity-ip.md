# Existing interconnect and connectivity IP — initial research

**Purpose:** Give the LOT POC team traceable starting points for evaluating reusable IP, following the QRPD principle of reusing the best-fit existing building blocks.

**Status:** Research shortlist only. No candidate has been selected or integrated. Product availability, license terms, commercial eligibility, and compatibility must be confirmed before a decision. The links below are starting evidence, not a substitute for checking the exact revision, license file, configuration, or vendor terms.

## Keep two problems separate

1. **On-chip interconnect / switch:** connects a CPU-side master interface to internal peripherals or transaction endpoints. It must match the actual bus protocol, address map, transaction ordering, IDs, error semantics, and timing requirements.
2. **External connectivity:** carries data to networked devices over technologies such as Wi-Fi, Thread, or Ethernet. Bluetooth LE can be used for Matter commissioning. A radio/network device is not a substitute for an on-chip AXI/AHB/APB interconnect.

Matter is an application-layer interoperability standard over IP-based networks; the Connectivity Standards Alliance describes Wi-Fi, Thread, and Ethernet as supported network technologies. See the [CSA Matter overview](https://csa-iot.org/all-solutions/matter/) and [CSA Matter security and privacy paper](https://csa-iot.org/developer-resource/white-paper-matter-security-and-privacy-copy/).

## Candidate 1 — Arm CoreLink NIC-400

- **What it is:** Configurable AMBA interconnect IP supporting AXI4, AXI3, AHB-Lite, and APB, according to Arm's product page.
- **Why investigate:** It is a vendor-supported candidate if the selected CPU and peripherals expose compatible AMBA interfaces and project access terms fit the business plan.
- **Potential advantage:** Commercially supported configurable interconnect, if terms and configuration suit the project.
- **Key checks:** Identify the exact MIPS core/native bus first; confirm whether an adapter is needed; verify current licensing/access eligibility directly with Arm; check supported configuration, deliverables, tool requirements, and commercial terms.
- **Primary sources:** [Arm CoreLink interconnect family / NIC-400](https://www.arm.com/products/silicon-ip-system/corelink-interconnect/nic); [Arm NIC-400 Technical Reference Manual](https://documentation-service.arm.com/static/5f5a411f235b3560a01eb5ce).
- **License/access status:** Not established for this project. Do not assume free access or that a commercial threshold mentioned in discussion applies to this IP. Confirm terms with Arm.

## Candidate 2 — PULP Platform AXI

- **What it is:** Open-source SystemVerilog AXI infrastructure. The project's `axi_xbar` documentation describes a configurable fully connected AXI4 crossbar with address mapping and response routing.
- **Why investigate:** Source and documentation are publicly inspectable, making it a traceable candidate for adapting an AXI-based design without writing a new crossbar from scratch.
- **Potential advantage:** Inspectable RTL and documented AXI features; a strong candidate to evaluate if the host side can use AXI.
- **Key checks:** Confirm the exact license and obligations for the selected revision; establish that the chosen CPU adapter can speak AXI; compare required features (IDs, response errors, ordering, backpressure, parameterization) and run upstream verification plus project-specific integration tests.
- **Primary source:** [PULP Platform AXI crossbar documentation](https://github.com/pulp-platform/axi/blob/master/doc/axi_xbar.md).
- **License/maintenance status:** Verify the current repository license, dependencies, supported release and project maintenance before adopting; this note does not certify a license conclusion.

## Candidate 3 — dpretet/axi-crossbar

- **What it is:** An open-source, parameterizable AXI4 crossbar implemented in SystemVerilog; the repository describes configurable master/slave counts and address-decoded request routing.
- **Why investigate:** Another traceable implementation to compare against PULP AXI if the target bus is AXI-compatible.
- **Potential advantage:** Focused AXI4 crossbar implementation that may be simpler to evaluate for a small system, subject to the feature and maintenance checks below.
- **Key checks:** Inspect the repository's current license, maintenance/activity, supported AXI features, test coverage, and integration constraints before use.
- **Primary source:** [dpretet/axi-crossbar repository](https://github.com/dpretet/axi-crossbar).
- **License/maintenance status:** Not yet verified for the intended project and revision.

## Silicon Labs and Matter connectivity

Silicon Labs documents SiWx917 in at least two relevant configurations:

- **SoC mode:** The SiWx917 is used as a single-chip platform for Matter over Wi-Fi, with integrated processing and networking stacks.
- **NCP mode:** A host MCU communicates with a SiWx917 network co-processor. Silicon Labs' documentation includes NCP configurations and, for specific Matter + AWS dual-stack designs, an SPI NCP interface between an EFR32 host and the SiWx917 NWP.

These are different integration models. Do not assume the current LOT POC connects to either model; the host interface, selected part/board, firmware mode, and command/data contract remain to be chosen.

- [Silicon Labs Matter hardware requirements](https://docs.silabs.com/matter/latest/matter-prerequisites/hardware-requirements)
- [Silicon Labs Matter + AWS dual-stack overview](https://docs.silabs.com/matter/latest/matter-aws-feature/matter-aws-dual-stack-overview)
- [Silicon Labs NCP mode with EFR32 host](https://docs.silabs.com/wiseconnect/latest/wiseconnect-getting-started/getting-started-with-ncp-mode-with-efr32)
- [CSA Matter overview](https://csa-iot.org/all-solutions/matter/)

**Open vendor question:** The documentation above identifies available product modes, but does not establish that Silicon Labs exposes a customizable internal switch/crossbar IP suitable for LOT. Ask Silicon Labs directly whether such IP is available, licensable, customizable, and appropriate for this use case.

## Initial comparison — no scores or winner assigned

| Candidate | Layer / interface dependency | Evidence currently linked | Why it may fit | Blocking checks before selection |
|---|---|---|---|---|
| Arm CoreLink NIC-400 | On-chip interconnect; AMBA AXI/AHB-Lite/APB | [Product page](https://www.arm.com/products/silicon-ip-system/corelink-interconnect/nic), [TRM](https://documentation-service.arm.com/static/5f5a411f235b3560a01eb5ce) | Configurable commercial interconnect if the target bus and terms fit | Actual MIPS bus compatibility; access/commercial terms; supported configuration; tool and integration dependencies |
| PULP Platform AXI | On-chip interconnect; AXI | [AXI crossbar docs](https://github.com/pulp-platform/axi/blob/master/doc/axi_xbar.md) | Publicly inspectable RTL and AXI crossbar documentation | Exact revision/license/dependencies; bus adapter; needed features; upstream tests and maintenance |
| dpretet/axi-crossbar | On-chip interconnect; AXI4 | [Repository](https://github.com/dpretet/axi-crossbar) | Parameterizable AXI4 crossbar candidate | Exact license; supported AXI feature set; maintenance; verification; timing/integration fit |
| Keep current custom LOT fabric | Existing simulation RTL; custom ready/valid payload | [Current architecture](../images/lot-poc-current-architecture.svg), [signal-level interface map](../lot-signal-level-interface-map.md) | Preserves the current POC and any genuinely required custom semantics | Prove a documented requirement justifies custom logic; specify bus contract; verify gaps; synthesize/measure before performance claims |
| Silicon Labs SiWx917 | External connectivity device; SoC or NCP host interface depends on mode | [Hardware requirements](https://docs.silabs.com/matter/latest/matter-prerequisites/hardware-requirements), [NCP guide](https://docs.silabs.com/wiseconnect/latest/wiseconnect-getting-started/getting-started-with-ncp-mode-with-efr32) | Candidate Wi-Fi / Matter connectivity platform, not an on-chip crossbar | Exact part/mode/board/SDK; host protocol and driver; controller availability; vendor customization options |
| Matter / Thread ecosystem | External network/application connectivity | [CSA Matter overview](https://csa-iot.org/all-solutions/matter/) | Defines interoperability and network/application requirements | Does not provide the local CPU bus or on-chip crossbar; identify which component owns Matter/Thread/network stacks |

**How to read this table:** It is a shortlist and evidence checklist, not a benchmark. No performance, area, latency, cost, license permission, or overall score is claimed because the target requirements and reproducible measurements are not available yet.

## Direct M2M / transaction requirements to clarify

Before judging whether any crossbar is a good fit, ask the architecture owner to define:

- What exactly is an M2M transaction: register read/write, command/message transfer, streaming data, or a mixture?
- Number of initiators and targets; whether the intended design really needs 4×4 connectivity.
- Native CPU-side protocol and version; address/data widths; byte enables; bursts; transaction IDs; ordering and outstanding-request policy.
- Response behavior: errors, unmapped destinations, timeout, reset while pending, and source association under contention.
- Backpressure, arbitration/fairness, clock/reset domains, throughput/latency targets, and whether CDC is required.
- External-device command/data interface and who owns the driver, buffering, interrupts, and Matter/network stack.

Do not infer that a generic AXI crossbar can perform application-level M2M messaging by itself. It routes bus transactions; endpoint adapters/controllers and software define the actual command or message semantics.

## Recommended decision sequence

1. **Identify the actual CPU/core and its native bus** (including request/response semantics, widths, IDs, reset, error behavior, and existing peripheral inventory).
2. **Agree the M2M transaction contract** and minimum switch requirements with the architecture owner.
3. **Eliminate incompatible candidates first.** Do not compare AXI-only IP as a drop-in for an unknown/non-AXI host bus.
4. **Review exact source revisions, license texts, upstream verification and maintenance** for the remaining candidates; record evidence and dates.
5. **In parallel, define external connectivity:** target Silicon Labs part and SoC/NCP mode, host interface, Matter/Thread/Wi-Fi requirements, and what traffic LOT is expected to transport.
6. **Ask vendors precise questions** and record answers with date/contact/reference. Do not infer access rights or customization support from sponsorship of Matter.
7. **Recommend a candidate with explicit trade-offs** only after the blocking checks are answered; integrate and verify only after interfaces and requirements are agreed.

## Current POC boundary

The repository's existing crossbar is a simulation POC component, not evidence that a custom crossbar should be retained in a future implementation. This research does not select or replace it. The actual MIPS core/bus, reusable interconnect, Silicon Labs part/mode, and network-facing interface remain open decisions.
