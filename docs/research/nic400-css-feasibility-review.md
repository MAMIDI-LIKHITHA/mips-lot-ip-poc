# LOT POC: NIC-400 and CSS Feasibility Review

**Status:** Preliminary desk research — not an architecture approval  
**Date:** 2026-10-12  
**Scope:** Assess the options raised in stakeholder feedback in plain language. No RTL was changed and no simulation was run for this note.

## Executive summary

- **CoreLink NIC-400:** A credible *candidate to investigate* if LOT needs a configurable AMBA on-chip interconnect and the CPU/peripheral interfaces can be made compatible. It is not automatically a drop-in replacement for the current LOT fabric. Product access, configuration tools, integration inputs and license terms must be confirmed with Arm.
- **Arm Compute Subsystems (CSS):** A much broader option: a pre-integrated compute subsystem including Arm CPU(s), interconnect and system IP, with platform-dependent software/firmware. It may be appropriate if LOT is intended to move to an Arm-based SoC platform. It is not simply a way to add a bus to the existing MIPS-based POC.
- **Carbon Design System:** A software user-interface design system. It may help if LOT needs a web dashboard, but it does not provide hardware interconnect or CPU subsystem functionality. A historical joint Arm/Carbon presentation does not establish technical integration between Carbon and NIC-400.
- **Current recommendation:** Do not select any of these yet. First confirm the actual MIPS core, its native bus, the required host/endpoint interfaces, project target, budget and IP/tool access.

## 1. CoreLink NIC-400

### What it does

Arm describes NIC-400 as configurable on-chip connectivity for AMBA AXI4, AXI3, AHB-Lite and APB interfaces. Arm's NIC-400 optimization paper describes a configurable network of switches and bridges, with address maps, interface widths and clock choices set for a particular SoC.

Official sources:
- Arm CoreLink Network Interconnect family page: https://www.arm.com/products/silicon-ip-system/corelink-interconnect/nic
- Arm's NIC-400 overview and configuration paper: https://developer.arm.com/community/arm-community-blogs/b/soc-design-and-simulation-blog/posts/getting-the-most-out-of-the-arm-corelink-nic-400
- Arm NIC-400 product support/access: https://support.arm.com/compute-ip/corelink-nic-400
- Arm Socrates tooling overview: https://developer.arm.com/dev2/Tools%20and%20Software/Socrates

### Fit for LOT

**Why it is worth checking**
- The purpose—connecting multiple memory-mapped masters and peripherals—is aligned with the general role of an SoC interconnect.
- It supports several AMBA interface families and can bridge/configure connectivity within those supported families.
- Configuration can be tailored to the required master/slave topology and address map.

**What is not yet established**
- The repository does not identify the real MIPS core or its native bus. Therefore, compatibility with NIC-400 is **unknown**. If the MIPS bus is not AXI/AHB/APB-compatible, an adapter may be required; the complexity and correctness of that adapter need investigation.
- The current POC's request/response interface is a custom ready/valid transaction format. It is not evidence of AMBA compliance.
- Arm's public product page does not establish that the IP, RTL deliverables, configuration tooling or required support are free or available to this project. Arm's access and licensing terms must be confirmed.
- No comparison of area, timing, latency or power can be made from the current POC simulation. These require a defined target and a valid implementation flow.

### Minimum checks before choosing NIC-400

1. Identify the CPU core, version, native bus and all relevant signal semantics.
2. List each LOT master and peripheral, including data/address widths, clock/reset domains, address map, read/write behavior, error responses and outstanding-transaction requirements.
3. Ask Arm whether NIC-400 is available for this project's organization/use case, what license and tools are required, and whether evaluation RTL or a reference integration can be accessed.
4. Check whether the toolchain can configure and generate the required topology and whether generated RTL can be used with the project's simulator/synthesis tools.
5. Compare the smallest viable configuration against the current fabric only after the interface contract is known.

## 2. Arm Compute Subsystems (CSS)

### What it does

Arm describes CSS as pre-integrated, market-tuned subsystems combining optimized compute, interconnect and system IP. Depending on the platform, this may include CPUs, system controllers, accelerators and supporting firmware/drivers.

Official source: https://www.arm.com/products/compute-subsystems

### Fit for LOT

CSS is not the same category as NIC-400:
- **NIC-400** addresses on-chip connectivity between compatible interfaces.
- **CSS** provides a broader compute foundation for an Arm-based SoC.

CSS is worth considering only if the intended LOT product can use an Arm CPU/subsystem and the project scope includes a broader SoC platform. If the requirement is to retain an existing MIPS core and add connectivity around it, CSS may be a major platform change rather than a small integration step.

### Checks before investing further

1. Is LOT allowed to change from MIPS to an Arm-based CPU/subsystem?
2. Which CSS family/platform actually fits the target application and required peripherals?
3. What RTL, software, implementation guidance, tools, board/reference design and support are available?
4. What are the access, licensing, commercial, target-foundry/process and implementation requirements?
5. Is a full CSS platform necessary for this POC, or would a smaller interconnect/peripheral integration answer the immediate question?

**Preliminary view:** CSS is a possible system-level alternative, not the default next step for the existing MIPS POC. No evidence currently establishes that it can be dropped into the present design.

## 3. Carbon Design System

### What it does

Carbon is IBM's open-source design system for building software user interfaces. Its official site documents reusable design assets and libraries, including React and Web Components.

Official sources:
- About Carbon: https://www.carbondesignsystem.com/getting-started/about-carbon
- Framework/support FAQ: https://www.carbondesignsystem.com/support/faqs
- Historical Arm/Carbon NIC-400 presentation: https://semiwiki.com/eda/2887-getting-the-most-out-of-the-arm-corelink-nic-400/

The historical article describes a joint presentation about optimizing NIC-400 using virtual prototyping and names speakers from Arm and Carbon Design Systems. This is evidence of collaboration around that presentation, **not evidence that Carbon is a hardware IP, an Arm interconnect dependency, or a required companion to NIC-400**.

### Fit for LOT

Carbon is relevant if the product needs a web-based configuration, monitoring or diagnostics dashboard. It does not implement a bus, connect RTL modules, or provide a CPU subsystem. If no UI is required for the POC, Carbon is outside the immediate hardware decision.

## 4. Other topics from the feedback

- **Windows customization/debloating:** Operating-system configuration and deployment. It does not determine the LOT on-chip interconnect.
- **Windows I/O:** Relevant if a Windows host application or device driver is a defined project requirement. Windows I/O APIs and driver models are separate from an SoC's internal hardware bus.
- **Local/cloud-free smart home:** A possible application scenario for LOT. It helps define device and networking requirements, but does not by itself select the CPU bus or interconnect.

These should be tracked as separate work items only if the project owner confirms they are in scope.

## 5. Simple decision table

| Option | Main purpose | Potential role in LOT | Main blocker to resolve | Preliminary status |
|---|---|---|---|---|
| Arm CoreLink NIC-400 | AMBA on-chip interconnect | Connect compatible CPU/peripheral interfaces | Actual MIPS bus, interface adapters, IP/tool access and license | Investigate first if AMBA-compatible |
| Arm CSS | Pre-integrated Arm compute subsystem | Alternative foundation for a broader Arm-based SoC | Whether changing/choosing an Arm platform is in scope; access, cost and platform fit | Explore only if a broader platform is wanted |
| IBM Carbon | Software UI design system | Optional web dashboard/configuration UI | Whether LOT needs a UI | Not part of hardware interconnect choice |
| Existing LOT fabric | Current custom simulation model | Baseline for functional POC | Integration gaps and no implementation measurements | Keep as baseline; do not claim production readiness |

## 6. Questions for the project owner

To make a decision without unnecessary work, please confirm:

1. Must the current MIPS core be retained, or can LOT move to an Arm-based subsystem?
2. Is the immediate deliverable a simulation POC, an FPGA demonstrator, or a production SoC design?
3. Is a software dashboard part of the LOT deliverable?
4. Who can contact Arm to confirm NIC-400/CSS access, licensing, tooling and support?
5. What target device, simulator/synthesis flow and budget constraints apply?

## Decision

**No candidate is selected by this report.** NIC-400 is the first interconnect candidate to check because its stated purpose matches the connectivity problem, but that is conditional on interface compatibility and acceptable access/licensing. CSS should be treated as a possible platform-level alternative. Carbon is an optional UI technology, not hardware IP.

The current repository remains a simulation-focused custom LOT fabric. This review changes documentation only; it does not modify RTL, prove compatibility, report new simulation results, or establish synthesis, timing, area, power or hardware performance.
