# LOT Foundation Options — Research and Decision Note

**Purpose:** Convert the NIC-400, Arm CSS, and Carbon research into a practical decision for the LOT POC. This is a public-source assessment, not a final architecture approval.

## Recommendation

1. **Evaluate Arm CoreLink NIC-400 first** as a commercial on-chip interconnect candidate, but only if the actual MIPS subsystem exposes a compatible AMBA interface (or a justified bridge is feasible) and the project can obtain the IP, configuration tools, and license.
2. **Compare PULP Platform AXI as an open-source candidate** only if AXI is a valid interface choice. Check the exact revision, license, dependencies, features, verification, and maintenance before adopting it.
3. **Keep the existing custom LOT RTL as the functional reference** while requirements are clarified. Do not replace it or claim it is production-ready without compatibility evidence and implementation measurements.
4. **Treat Arm CSS as a platform-level alternative**, not a drop-in crossbar replacement. It matters only if moving from the existing MIPS-based direction to an Arm-based compute platform is in scope.
5. **Defer IBM Carbon Design System** unless a web dashboard or operator UI is actually required; Carbon is software UI tooling, not hardware IP.

## What each option solves

| Option | Role | Relevance to LOT | Main blocker |
|---|---|---|---|
| Arm CoreLink NIC-400 | Configurable AMBA on-chip interconnect | Closest commercial candidate for connecting compatible bus masters and peripheral targets | Actual MIPS bus compatibility; IP/license/tool access; integration effort |
| PULP Platform AXI | Publicly inspectable AXI infrastructure, including an AXI crossbar | Candidate if the host interface can use AXI and its feature set fits | Exact revision/license/dependencies; AXI feature fit; integration verification |
| Existing custom LOT fabric | Current simulation-focused ready/valid router and 4×4 crossbar | Useful functional reference for the behavior already exercised in the POC | Not yet shown to be required for the final design; implementation results unavailable |
| Arm Compute Subsystem (CSS) | Pre-integrated Arm CPU and system-IP platform | Relevant only if the project may change processor/platform | Product/platform choice, access and commercial terms, target silicon and software |
| IBM Carbon Design System | Software design system and UI components | Optional dashboard/control panel only | Confirm UI is in scope |

## What the repository establishes

The current repository documents a custom ready/valid transaction router, 4×4 crossbar, behavioral endpoints, response router, and candidate single-outstanding MMIO path in the testbench. The latest reported ModelSim regression is 10 passed / 0 failed, with all 16 routes exercised and a 500-cycle stress test delivering 1,175 accepted transfers.

These are **simulation results only**. The repository explicitly says synthesis, place-and-route, timing closure, resource measurement, and hardware validation have not been performed. The actual MIPS core/native bus, final peripheral map, Silicon Labs device/mode, and host interface remain unselected.

Therefore, the POC demonstrates useful transaction-routing behavior, but does not establish that the custom crossbar is the best final IP or that any third-party candidate is compatible.

## NIC-400: bounded compatibility assessment

Arm documents NIC-400 as configurable AMBA interconnect IP supporting AXI4, AXI3, AHB-Lite, and APB. The technical reference manual describes configurable interfaces and switching structures. Those advertised capabilities do not establish access rights, tool availability, compatibility with our undisclosed MIPS subsystem, or suitability for a specific configuration.

Before selecting it, verify:

- [ ] Exact MIPS core/subsystem name, version and configuration.
- [ ] Native bus protocol and revision; address/data widths; byte enables; burst and ID behavior; outstanding transactions; ordering and response/error semantics.
- [ ] Whether NIC-400 supports the required interface combination directly or needs a protocol bridge.
- [ ] Required initiators, targets, address map, clock/reset domains, and clock-domain-crossing needs.
- [ ] Availability of IP RTL/deliverables, configuration tools, documentation, support, and commercial entitlement for this project.
- [ ] Minimum integration test: one initiator and two targets; read/write; contention; backpressure; unmapped-address/error response; reset while a transaction is pending; and correct response association.

**Decision rule:** If the native bus is compatible and access is confirmed, compare NIC-400 with the custom RTL and suitable open-source options on required features, integration effort, verification evidence, license, and measurable implementation results. If it is incompatible, estimate bridge effort before deciding. Do not assume direct connection.

## PULP AXI: comparison candidate

PULP Platform AXI provides publicly inspectable AXI infrastructure, including a documented crossbar. It is a reasonable candidate to investigate if AXI is selected or can be exposed cleanly by the CPU-side adapter. It is not a universal replacement for an unknown MIPS bus.

Before adopting it, inspect the exact repository revision and license, dependencies, supported protocol/features, upstream verification, maintenance status, and integration constraints. Run project-specific tests for address decode, backpressure, ordering/IDs as needed, errors, reset, and response routing.

## Arm CSS

Arm CSS is a pre-integrated compute subsystem, combining Arm CPUs and system IP for a target market. It is a larger CPU/platform decision, not merely a replacement crossbar. If LOT must retain its MIPS-based architecture, CSS is not a drop-in alternative. Keep it out of the immediate interconnect decision unless the project explicitly allows a processor/platform change.

## IBM Carbon Design System

Carbon is an open-source design system for digital interfaces. It can help build a dashboard using supported web technologies, but does not implement bus routing, arbitration, bus conversion, a CPU subsystem, or network connectivity. Defer it unless a user-facing UI is a defined deliverable.

## Recommended next steps

1. Identify the real MIPS core/subsystem and native bus from RTL, manuals, or integration documents.
2. Record the bus contract and the intended initiators, targets, address map, error behavior, outstanding-transaction policy, clock/reset domains, and measurable latency/throughput goals.
3. Inventory existing peripheral controllers, especially whether a suitable memory-mapped SPI controller already exists for the chosen external connectivity device.
4. Check NIC-400 interface fit and project access; compare PULP AXI only if the bus choice supports it.
5. Keep the custom RTL as a functional baseline. Do not implement iSLIP or another scheduler unless the requirements demonstrate that the current arbitration behavior is inadequate.
6. After selecting a candidate and target flow, run synthesis/timing/resource analysis and then board-level validation before making implementation-performance claims.

## Questions to resolve with the architecture owner

- Must LOT stay with the existing MIPS subsystem, or is an Arm-based platform genuinely in scope?
- What is the exact MIPS core/subsystem and native bus, including the current address map and available peripherals?
- Is NIC-400 accessible to the project under suitable licensing and tool access?
- Which Silicon Labs part/board and mode are intended (SoC, NCP, or RCP), what host interface is supported, and who owns the network stack?
- What should the POC demonstrate: device-side connectivity, a Thread border router, or another role?
- Is a Carbon-based UI a real requirement or just a research lead?

## Sources

- Arm CoreLink interconnect / NIC-400: https://www.arm.com/products/silicon-ip-system/corelink-interconnect/nic
- Arm NIC-400 Technical Reference Manual (verify the revision applicable to any proposed configuration): https://documentation-service.arm.com/static/5e8f1ac06db15673561aaa56
- Arm Compute Subsystems: https://www.arm.com/products/compute-subsystems
- Arm Neoverse CSS (infrastructure example): https://www.arm.com/products/cloud-datacenter/neoverse-compute-subsystems
- PULP Platform AXI crossbar documentation: https://github.com/pulp-platform/axi/blob/master/doc/axi_xbar.md
- PULP Platform AXI repository: https://github.com/pulp-platform/axi
- IBM Carbon Design System overview: https://www.carbondesignsystem.com/getting-started/developing/overview

**Evidence boundary:** This note distinguishes public product descriptions from project-specific facts. It does not confirm vendor availability, licensing entitlement, compatibility with the unidentified MIPS subsystem, hardware interoperability, or production readiness.
