# LOT Foundation Options — Simple Decision Note

**Purpose:** Turn the research into a practical decision for the LOT POC. This note is deliberately short. It does not select a final architecture without the actual MIPS subsystem, target use case, and licensing constraints.

## Recommendation in one minute

1. **Evaluate CoreLink NIC-400 as a candidate interconnect only if the system uses compatible AMBA interfaces and the required IP/license is available.** It is the closest of these three items to the on-chip LOT interconnect problem.
2. **Do not select Arm CSS as the default LOT POC foundation yet.** CSS is a pre-integrated compute subsystem built around Arm processors and system IP, aimed at market-specific SoC platforms. If the requirement is to keep the existing MIPS-based architecture, CSS is not a drop-in replacement; it would imply a much larger processor/platform decision.
3. **Treat Carbon Design System as optional software/UI tooling only.** It is IBM's open-source design system for digital products, not an on-chip interconnect, CPU subsystem, or hardware IP. Consider it only if LOT needs a web dashboard or operator UI.

## What the options actually solve

| Option | What it is | Fit for LOT | Main gate before choosing |
|---|---|---|---|
| Arm CoreLink NIC-400 | Configurable on-chip interconnect supporting AMBA AXI3/AXI4, AHB-Lite, and APB | **Potentially relevant** to connecting CPU masters and peripheral slaves inside an SoC | Identify the actual MIPS bus, protocol/version, widths, outstanding-transaction behavior, and whether a suitable bridge and NIC-400 license/source package are available |
| Arm Compute Subsystem (CSS) | Pre-integrated Arm CPU(s), interconnect, system IP, and supporting software, tailored to a target market | **Potentially relevant only if LOT is intended to adopt an Arm-based SoC platform**; likely too broad to assume as the starting point for a MIPS-focused RTL POC | Confirm CPU/platform can change, intended market and performance target, partner access, commercial terms, implementation flow, and target silicon |
| IBM Carbon Design System | Reusable UI design language, components, and developer assets | **Not relevant to the hardware interconnect**; useful only for a software dashboard/control panel | Confirm that a UI is in scope and choose its software framework |

## NIC-400: practical evaluation checklist

Arm's product page describes NIC-400 as configurable, hierarchical connectivity for AMBA 4 AXI4, AXI3, AHB-Lite, and APB. The technical reference manual lists configurations from 1–128 slave interfaces and 1–64 master interfaces, plus configurable switching networks and timing-closure options. These figures describe the IP's supported configuration range, **not** a promise that any configuration is available to this project or suitable without integration work.

Before treating it as the LOT core IP, verify:

- [ ] What processor and exact MIPS subsystem is being used?
- [ ] What bus does it expose (including protocol revision, address/data widths, bursts, IDs, ordering, and response behavior)?
- [ ] Does that interface match a NIC-400 configuration, or is a protocol bridge needed?
- [ ] What are the required masters, peripherals/slaves, address map, clock/reset domains, and error-response requirements?
- [ ] Is NIC-400 accessible under the project's commercial license and tool flow? Can the team obtain the configuration tools, deliverables, documentation, and support needed?
- [ ] What minimum test would prove integration: one master, two targets, read/write transactions, contention, backpressure, and error handling?

**Decision rule:** If the existing MIPS subsystem already has a suitable AMBA bus and NIC-400 access is confirmed, compare it against the current custom RTL on interface fit, integration effort, configurability, verification evidence, and licensing. If the bus is proprietary or incompatible, first estimate bridge effort; do not assume NIC-400 connects directly.

## Arm CSS: practical evaluation checklist

Arm describes CSS as a pre-integrated, market-tuned compute foundation that typically combines Arm CPUs, interconnect, system IP, and supporting firmware/software. It is a platform-level choice, not just a replacement crossbar.

Confirm:

- [ ] Is the project allowed to replace or move away from the MIPS CPU?
- [ ] What is the target market and compute requirement (IoT/edge, mobile, infrastructure, automotive, etc.)?
- [ ] Which specific CSS offering matches that market and is accessible to the project?
- [ ] Does it support the required external peripherals and wireless/network device path?
- [ ] What are the licensing, foundry/process, EDA, implementation, and partner-access requirements?

**Decision rule:** Keep CSS as a separate platform-level option until the CPU/platform decision is explicit. Do not describe it as the selected LOT foundation based only on public product descriptions.

## Carbon Design System

Carbon provides reusable components, patterns, styles, and developer resources for building digital experiences, with official support for React and Web Components. It may be useful if the POC includes a web-based status/configuration dashboard. It does not implement hardware routing, arbitration, bus conversion, or networking protocols.

**Decision rule:** Defer it unless a user-facing software interface is an explicit deliverable.

## Proposed next steps

1. **Get the missing facts from Swapnil:** exact MIPS core/subsystem and bus; whether CPU replacement is in scope; intended LOT use case; whether NIC-400/CSS are exploratory candidates or expected deliverables; and what the Silicon Labs boards should demonstrate.
2. **Create a one-page requirement sheet** from those answers: initiators, targets, bus protocol, address map, throughput/latency goals, clock/reset domains, wireless device/mode, host interface, and software-stack ownership.
3. **Run a bounded NIC-400 fit check** against the real bus and project access/licensing. Compare only compatible candidates; do not implement iSLIP or another scheduler unless requirements show that arbitration policy is the issue.
4. **Keep the existing custom RTL as a functional reference**, not as a production IP claim. The current repository says synthesis, timing closure, area/resource measurement, and hardware validation have not been performed.
5. **Make the decision after the evidence is available:** reuse existing interconnect IP if it fits and is accessible; otherwise document the bridge/custom-RTL trade-off. Evaluate CSS only if a platform change is in scope. Evaluate Carbon only if a UI is in scope.

## Questions to send Swapnil

1. Should LOT remain based on the existing MIPS subsystem, or is moving to an Arm-based CSS platform a real option?
2. Can you share the exact MIPS core/subsystem, its bus interface, and the current peripheral/address-map information?
3. Is NIC-400 expected to be the preferred candidate to evaluate, and do we have access to the IP, configuration tooling, and license?
4. What exactly should the Silicon Labs DVKs demonstrate, and which board/part and host interface are intended?
5. Is a Carbon-based UI actually required for this POC, or was that only a research lead?

## Sources

- Arm CoreLink Network Interconnect family (including NIC-400): https://www.arm.com/products/silicon-ip-system/corelink-interconnect/nic
- Arm CoreLink NIC-400 Technical Reference Manual: https://documentation-service.arm.com/static/5e8f1a896db15673561aaa56
- Arm Compute Subsystems: https://www.arm.com/products/compute-subsystems
- Arm Neoverse CSS (infrastructure example): https://www.arm.com/products/cloud-datacenter/neoverse-compute-subsystems
- IBM Carbon Design System — overview: https://www.carbondesignsystem.com/getting-started/developing/overview

**Evidence boundary:** This is a public-source fit assessment, not confirmation of product availability, commercial entitlement, or compatibility with the project's undisclosed MIPS subsystem. Those require project-specific confirmation.
