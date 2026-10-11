# LOT Connectivity Layer — Research Report 01 (Reviewed)

**Prepared for:** Mihai Buta and Swapnil (MobilFlex)  
**Author:** Likhitha Mamidi  
**Review date:** 11 October 2026  
**Status:** Preliminary research. No architecture or IP selection approved. No hardware tested.

## Executive summary

This report evaluates existing building blocks for a LAN of Things (LOT) connectivity layer. The goal is to identify a best-fit existing interconnect and an appropriate external connectivity approach—not to justify a new crossbar by default.

A Matter-over-Wi-Fi NCP setup (EFR32 host + SiWx917 NCP) is a useful *working research reference* because it makes the host-to-radio interface explicit. It is not a MobilFlex decision. The right Silicon Labs mode depends on whether LOT is a device-side connectivity layer or must bridge a Thread network to other IP networks.

The most important blocker is the exact MIPS subsystem and native bus. Public 2022 material about particular MIPS eVocore cores described ACE/AXI interfaces, but this does not establish the interface of the core used by this POC. Confirm the actual core, configuration, and available peripheral controllers before comparing interconnects.

> **Decision status:** No winner is selected. The current custom ready/valid fabric is a simulation POC, not evidence that a bespoke crossbar is required. Compare reusable IP only after the host interface and transaction requirements are written down.

## 1. Review findings and corrections

1. **Source traceability:** the source table in the original PDF contains truncated URLs. Replace ellipses with complete clickable links, exact document/version titles, and access dates. A source list that cannot be followed is not auditable.
2. **MIPS compatibility:** treat the AXI/ACE reference as historical context only. It is not evidence that this POC's specific MIPS core exposes AXI, ACE, or an available non-coherent peripheral port.
3. **Silicon Labs modes:** NCP, RCP, and SoC are not interchangeable. State which stack runs where, what protocol crosses the host link, and which board/SDK example supports each claim.
4. **Crossbar scope:** a crossbar routes on-chip transactions. It does not implement Matter, Thread, Wi-Fi, application-level device discovery, or M2M command semantics. These belong to separate protocol, controller, endpoint, and software layers.
5. **Arm access and cost:** do not repeat old Flexible Access eligibility or royalty-free claims as current terms. Confirm the exact product, entitlement, configuration, and commercial terms directly with Arm.
6. **PULP AXI licensing:** review the exact repository revision, license, dependencies, obligations, and intended distribution model. A license identifier alone is not a project-specific legal conclusion.
7. **Performance claims:** simulation alone does not establish latency, throughput, Fmax, area, power, or hardware compatibility.

Use “candidate,” “working assumption,” and “to verify” wherever the actual board, core, bus, or SDK is not selected. Keep the comparison unscored until requirements and reproducible evidence exist.

## 2. Answers to the five open questions

### Q1 — Which Silicon Labs board and mode?

**Working research reference:** Matter over Wi-Fi NCP with an EFR32 host and SiWx917 NCP. Silicon Labs' Matter hardware-requirements documentation describes separate boards for NCP mode and a single-chip SiWx917 option for Wi-Fi SoC mode. This is a research baseline, not a MobilFlex decision.

Alternatives:
- **Wi-Fi SoC:** consider if the goal is a self-contained device.
- **Thread RCP + host:** consider if LOT must run host-side OpenThread/border-router software.

Confirm the board, SDK release, host link, and supported configuration against the exact official guide and board schematic.

### Q2 — Must LOT be a Thread/Matter border router?

Only if the product must connect a Thread network to another IP network. Wi-Fi Matter devices join the Wi-Fi network directly; a Thread border router is not automatically required for a Wi-Fi-only accessory. This is a product-scope decision for Mihai and Swapnil, not a crossbar design decision.

### Q3 — What is the MIPS-side bus?

**Not established by the supplied evidence.** The original report cites 2022 material describing AXI/ACE interfaces for particular eVocore products. Ask the owner/vendor for the exact core, version, subsystem configuration, bus protocol/version, address/data widths, ID and ordering behavior, clock/reset domains, and present memory-mapped peripherals. Do not assume AXI until confirmed.

### Q4 — Who owns the network stack?

It depends on the selected mode:
- **NCP:** the co-processor runs the Wi-Fi/network stack.
- **RCP:** the host runs higher-level Thread networking and border-router software.
- **SoC:** application and connectivity functions run on the single-chip platform according to the selected vendor architecture.

Verify the details against the exact SDK guide and selected configuration.

### Q5 — Who can answer customization/licensing questions?

Contact Silicon Labs Sales for product/commercial questions, Technical Support for supported-configuration questions, and the vendor community for implementation guidance. The original report's CPMS reference concerns factory provisioning/customization such as keys and certificates; it does **not** establish that internal silicon blocks can be modified or licensed. Ask explicitly whether interconnect, bridge, or peripheral IP is available for licensing and what “customization” covers.

## 3. Interconnect shortlist — no score or winner

| Candidate | Potential fit | Blocking checks |
|---|---|---|
| Arm CoreLink NIC-400 class | Commercial AMBA interconnect candidate if the host/peripherals use compatible AXI/AHB-Lite/APB interfaces. | Exact MIPS bus; entitlement and commercial terms; configuration/tool requirements; integration scope. |
| PULP Platform AXI (axi_xbar) | Publicly inspectable AXI4 infrastructure; useful to evaluate if the host can expose AXI. | Exact revision/license/dependencies; required AXI features; adapter needs; project-level verification and maintenance. |
| dpretet/axi-crossbar | Another AXI4 crossbar candidate if AXI compatibility is established. | Current license, activity, supported AXI feature set, verification evidence, and integration cost. |
| Current custom LOT fabric | Preserves current simulation behavior while requirements are clarified. | Demonstrate a specific requirement not met by reusable IP; close protocol/error/response gaps; synthesize and measure before claims. |
| Silicon Labs SiWx917 | External Wi-Fi connectivity candidate in NCP or SoC configurations. | Exact board/mode/SDK; host protocol/controller/driver; software ownership; vendor answers on custom IP. |
| Matter / Thread | External application/network interoperability requirements. | Not an on-chip interconnect; decide whether Thread border routing is in scope and who owns the stack. |

This is a documentation-level shortlist, not a benchmark. Do not compare latency, area, cost, or performance without matching configurations and reproducible tests.

## 4. Define the transaction contract before selecting IP

“Direct M2M” must be defined in functional terms. A generic crossbar routes bus transactions; it does not by itself define device-command or network-message semantics.

- **Traffic type:** memory-mapped register reads/writes, command/message transfer, streaming data, or a combination.
- **Topology:** actual number of initiators/targets and whether 4×4 connectivity is required.
- **Host protocol:** exact bus/version, address/data width, byte enables, bursts, IDs, ordering, outstanding transactions, and address map.
- **Response rules:** error response, unmapped address, timeout, reset while pending, and source association under contention.
- **Flow control:** backpressure, arbitration/fairness, clock/reset domains, and CDC requirements.
- **External device contract:** SPI/UART/SDIO or another interface; controller/driver ownership; buffering, interrupts, and ownership of Matter/Thread/network software.
- **Targets:** measurable latency/throughput goals, expected concurrent traffic, and verification acceptance criteria.

## 5. Recommended next steps and decision gates

| Gate | Action | Exit evidence |
|---|---|---|
| 1. Confirm host | Identify exact MIPS core/subsystem and native bus; inventory existing SPI/UART and memory-mapped peripherals. | Product/subsystem documentation; interface widths and semantics recorded. |
| 2. Freeze requirements | Agree on the LOT transaction contract and whether LOT must be a Thread border router. | Written requirement checklist approved by Mihai/Swapnil. |
| 3. Confirm radio path | Choose SiWx917 NCP/SoC or Thread RCP; inspect the exact SDK guide, board schematic, and supported host interface. | Board/mode/SDK and interface selected; software stack ownership documented. |
| 4. Compare reusable IP | Evaluate Arm NIC-400-class and PULP AXI only if compatible; include dpretet/axi-crossbar if useful. | Feature matrix, exact license/revision, dependencies, tests, and integration estimate. |
| 5. Prototype integration | Reuse a compatible existing SPI controller if present; write an adapter only for a documented protocol gap. | Compile/simulation tests against the real interface contract. |
| 6. Validate implementation | Run synthesis, timing/resource analysis, then board-level tests in the selected environment. | Reproducible reports for area, timing, latency, functionality, and hardware interoperability. |

**Decision requested from Mihai and Swapnil:**
1. Product role: device-side connectivity or Thread border router?
2. Exact target MIPS core/subsystem and bus?
3. Preferred Silicon Labs mode/board?
4. Who will contact Silicon Labs and MIPS?

Until these are answered, IP selection remains open.

## 6. Source links

Documentation changes over time; reopen the exact version and record the access date before making a design decision.

- [Silicon Labs Matter hardware requirements v2.8.0](https://docs.silabs.com/matter/2.8.0/matter-prerequisites/hardware-requirements)
- [Silicon Labs Matter hardware requirements — latest](https://docs.silabs.com/matter/latest/matter-prerequisites/hardware-requirements)
- [Silicon Labs NCP mode with EFR32 host](https://docs.silabs.com/wiseconnect/latest/wiseconnect-getting-started/getting-started-with-ncp-mode-with-efr32)
- [OpenThread Border Router guide](https://openthread.io/guides/border-router)
- [Matter overview — Connectivity Standards Alliance](https://csa-iot.org/all-solutions/matter/)
- [Arm CoreLink interconnect family / NIC-400](https://www.arm.com/products/silicon-ip-system/corelink-interconnect/nic)
- [PULP AXI crossbar source](https://github.com/pulp-platform/axi/blob/master/src/axi_xbar.sv)
- [PULP AXI repository license](https://github.com/pulp-platform/axi/blob/master/LICENSE)
- [PULP AXI crossbar documentation](https://github.com/pulp-platform/axi/blob/master/doc/axi_xbar.md)
- [dpretet/axi-crossbar repository](https://github.com/dpretet/axi-crossbar)

## Limitations

This review does not constitute a legal opinion on licensing, a vendor confirmation, a complete audit of every cited source, or hardware verification. The exact MIPS core, bus, target board, SDK version, and production requirements remain unconfirmed.
