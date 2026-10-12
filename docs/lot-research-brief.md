# LOT IP Research Brief

**Status:** Working research note; architecture not frozen  
**Repository:** [mips-lot-ip-poc](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc)  
**Last reviewed:** 2026-10-12  
**Purpose:** Support MobilFlex's early architecture decision for a candidate LAN of Things (LOT) block and distinguish public product intent from a confirmed implementation specification.

## Decision question

What should the current 4×4 LOT crossbar connect to, and how should a host transaction reach a real endpoint once the target host subsystem and endpoint are selected?

## Executive recommendation

**[Inference — medium confidence]** Keep LOT as an on-chip transaction-routing layer and investigate this path only as a hypothesis:

```text
Confirmed host core / bus master
          |
          v
Host-bus adapter + address decode
          |
          v
LOT transaction router
          |
          v
LOT 4x4 crossbar
          |
          v
Confirmed peripheral controller / endpoint
          |
          v
Physical interface or behavioral target
```

This deliberately avoids selecting a MIPS core, Arm subsystem, SPI controller, wireless part, or bus protocol before the project owner confirms the target. An earlier Silicon Labs SiWx917 NCP/SPI path remains one possible example, not an approved target.

The current POC uses a candidate MMIO adapter and behavioral endpoints; it does not yet connect to a real host subsystem, a specific peripheral controller, or hardware. The first check is to obtain the target subsystem/interface specification and define the intended POC use case and acceptance metrics.

## Public MobilFlex intent versus an engineering specification

Public MobilFlex material describes LOT as a connectivity layer / accelerator intended to unify currently separate device networks, support concurrent machine-to-machine (M2M) transactions, and reduce I/O-related work on the host. Its presentations describe **up to 16 concurrent M2M transactions** and identify the connectivity-layer implementation as a practical POC direction. These are statements of product intent and claimed goals, **not verified results from this repository and not a complete RTL interface contract**.

Sources:
- [MobilFlex official website](https://mobil-flex.com/) — public positioning of LOT and the Personal Data Center.
- [MobilFlex Investors Presentation 2025](https://pt.slideshare.net/slideshow/mobilflex-investors-presentation-2025/278381545) — describes connectivity-layer use and claims up to 16 concurrent M2M transactions.
- [MobilFlex BP Presentation, December 2025](https://es.slideshare.net/slideshow/mobilflex-bp-presentation-december-2025-gc/284954229) — describes LOT use cases and the distinction between connectivity-layer and chipset implementations.

### What those public claims imply we should ask the owner

| Publicly described goal | POC question to resolve | Evidence required before claiming success |
|---|---|---|
| Up to 16 concurrent M2M transactions | Does “concurrent” mean 16 accepted/in-flight transactions, 16 independent routes, or 16 end-to-end device exchanges? What are the sources, destinations, and transaction completion rules? | Written definition plus a test that drives the agreed concurrency level and checks every request/response for loss, duplication, and misrouting. |
| Interoperability across different device networks/protocols | Which concrete device types and protocols are in the first demonstrator? Which controller/bridge owns each external protocol? | A selected endpoint list and interface contracts; behavioral simulation first, then hardware evidence if required. |
| LOT as a connectivity layer | Is the POC intended to be a standalone/insertable fabric attached to an existing host, or part of a larger chipset/subsystem? | Owner-approved block diagram and scope statement. |
| Improved host utilization / reduced I/O bottlenecks | What baseline workload, host model, and metric should be compared? | Reproducible before/after workload and measurement method. RTL functional tests alone cannot prove CPU utilization or system-level performance claims. |
| A simulation-based POC may be useful | Is simulation sufficient for this milestone, or is emulation/physical hardware required? | Explicit acceptance criteria and agreed deliverables. |

Do not turn the public “up to 16” statement into a claim that the current 4×4 crossbar has demonstrated 16 concurrent end-to-end M2M transactions. The current regression's 16/16 route coverage means every source/destination route was exercised; it is not the same as proving 16 transactions are simultaneously in flight.

## What is established vs. not established

| Finding | Evidence / tag |
|---|---|
| The repository contains a simulation-focused candidate MMIO → LOT transaction router → 4×4 ready/valid crossbar → behavioral endpoints → response-router path. | [Confirmed — repository RTL and README](../README.md) |
| The latest user-reported ModelSim Intel FPGA Edition 2021.1 regression passed all **12 testbenches** with 0 failures; local logs showed PASS markers, and all 16 crossbar routes were exercised by the coverage test. | [Confirmed as user-reported local evidence — regression transcript, 2026-10-12]. Not a CI result and not an end-to-end concurrency benchmark. |
| MobilFlex publicly positions LOT as a connectivity layer/accelerator and describes up to 16 concurrent M2M transactions as a product goal/claim. | [Confirmed — public company material linked above]. Not independently validated by this repository. |
| The exact host core, native bus protocol, widths, timing/handshake rules, and peripheral map are known. | **[Check — blocking; not established]** |
| A specific Silicon Labs device, NCP/SoC mode, host board, SPI controller, and SDK are the selected target. | **[Check — not decided in the available project material]** |
| A memory-mapped SPI controller is the best endpoint integration point. | [Inference only if a selected endpoint uses SPI and a compatible controller exists in the target subsystem.] |
| The current RTL has been synthesized, timed, or validated on hardware. | **[Not established — do not claim]** |

## Candidate options

| Option | Description | Benefits | Main risks / checks | Current position |
|---|---|---|---|---|
| A. Reuse an existing controller | LOT routes transactions to a compatible memory-mapped controller, which drives the endpoint's physical interface. | Reuses tested protocol-specific logic and keeps the fabric separate from device details. | Confirm controller exists, bus compatibility, register interface, FIFO/interrupt/DMA needs, clocks, reset, pin mux, and license. | **First option to investigate** [Inference] |
| B. Add or integrate a controller | Add a controller if the selected subsystem has none. | Clear separation between transaction routing and physical protocol. | More RTL/integration, register-map, timing, licensing and verification work. | Fallback only after target confirmation [Inference] |
| C. Add a custom LOT-to-endpoint bridge | Translate the agreed LOT contract into a target-specific protocol. | May fit a genuinely custom interface. | Requires an explicit contract, buffering, timeout/error semantics and targeted verification. | Do not choose before defining the need |
| D. Connect a physical device directly to the crossbar | Treat the device as a direct LOT target. | Simple only for a behavioral abstraction. | Physical devices normally require their specified host/controller interface; a generic crossbar does not replace that controller. | Not recommended without a defined interface |
| E. Reuse a standard interconnect/bridge | Evaluate standard-bus infrastructure if the confirmed host already exposes a compatible bus. | May reduce custom bridge work and improve interoperability. | Depends on actual core bus, IP availability, licensing, feature support, and integration tooling. | Compare only after target confirmation |

## Recommended next steps

1. **Obtain the project-owner contract:** identify the host core/subsystem, native bus and version, address/data widths, byte enables, response/error behavior, outstanding/burst/ordering behavior, clock/reset, and address map.
2. **Clarify the POC use case:** connectivity-layer vs. co-processor/chipset; simulation vs. emulation/hardware; first concrete endpoint(s); what “16 concurrent M2M transactions” means; and the acceptance workload/metrics.
3. **Inventory existing peripherals:** confirm whether a compatible controller already exists and identify its register map, interrupts, clock/reset, and physical interface.
4. **Record the agreed contract** in [the MIPS interface note](03_mips_interface.md) (or rename/generalize it if the owner confirms that the host is not MIPS). Update the compatibility matrix only with viable candidates.
5. **Design the adapter only after the contract is confirmed.** Verify request acceptance, response association, backpressure, invalid addresses, errors, reset during a pending transaction, and any agreed concurrency level.
6. **Separate route coverage from concurrency/performance claims.** Add a directed test and scoreboard for the owner-defined in-flight transaction target; benchmark system-level claims only with an agreed baseline and measurement method.
7. **Do not claim hardware validation yet:** synthesis, timing/resource analysis, and board testing require a selected target, toolchain, board, and firmware configuration.

## Questions the research should resolve

- Which exact host core/subsystem is in scope, and is MIPS a hard requirement?
- What native bus protocol and revision does it expose?
- What precisely does the POC need to demonstrate, and what is the acceptance definition for “16 concurrent M2M transactions”?
- Which endpoint/device protocols are in the first scope, and what controllers already exist?
- Is the required deliverable simulation-only, emulated, or hardware-demonstrated?
- Which performance metric and baseline, if any, are required to substantiate host-utilization or throughput claims?

## Scope boundary

This brief records research and open decisions; it does not finalize the architecture. Matter, Thread, Wi-Fi, and BLE are networking/connectivity technologies, not substitutes for a defined on-chip transaction bus. The LOT crossbar routes local transactions; do not describe it as a packet router or as production-ready without a separate specified and verified function.

## Primary sources

1. MobilFlex, [official website](https://mobil-flex.com/) — public product positioning.
2. MobilFlex, [Investors Presentation 2025](https://pt.slideshare.net/slideshow/mobilflex-investors-presentation-2025/278381545) — public LOT use cases and concurrency claims.
3. MobilFlex, [BP Presentation, December 2025](https://es.slideshare.net/slideshow/mobilflex-bp-presentation-december-2025-gc/284954229) — public implementation options and stated goals.
4. Arm, [AMBA system architecture overview](https://www.arm.com/architecture/system-architectures/amba) and [AMBA specifications](https://www.arm.com/architecture/system-architectures/amba/amba-specifications) — protocol context only; neither identifies the target host bus.
5. Silicon Labs, [Getting started with NCP mode with EFR32](https://docs.silabs.com/wiseconnect/latest/wiseconnect-getting-started/getting-started-with-ncp-mode-with-efr32) — relevant only if that host/NCP path is selected.
6. Silicon Labs, [SiWx917 NCP SPI protocol application note prerequisites](https://docs.silabs.com/wifi-application-notes/1.0.1/wifi-siwx917-ncp-spi-protocol-application-note/prerequisites) — relevant only if the SiWx917 SPI protocol is selected.
7. Open-source candidate, [dpretet/axi-crossbar](https://github.com/dpretet/axi-crossbar) — a candidate to review only if the confirmed interface makes AXI infrastructure relevant; verify license, supported features, and maintenance before adoption.

## Change log

- 2026-10-12: Corrected the reported regression count to 12; added a public-source summary of MobilFlex's stated LOT goals and a checklist separating product claims from measurable POC acceptance criteria. No RTL behavior changed.
- 2026-10-11: Added a source-linked architecture hypothesis, options, evidence labels, and verification boundary. No RTL behavior changed.
