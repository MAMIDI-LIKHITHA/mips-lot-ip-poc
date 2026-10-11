# LOT IP Research Brief

**Status:** Working research note; architecture not frozen  
**Repository:** [mips-lot-ip-poc](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc)  
**Last reviewed:** 2026-10-11  
**Purpose:** Support MobilFlex's early architecture decision for a candidate MIPS-based LAN of Things (LOT) block.

## Decision question

What should the current 4×4 LOT crossbar connect to, and how should a MIPS-side memory-mapped transaction reach a Silicon Labs wireless connectivity device if that family is selected?

## Executive recommendation

**[Inference — medium confidence]** Keep LOT as an on-chip transaction-routing layer and initially investigate this path:

```text
MIPS core / selected bus master
          |
          v
CPU-bus adapter + address decode
          |
          v
LOT transaction router
          |
          v
LOT 4x4 crossbar
          |
          v
Memory-mapped SPI controller (reuse if present)
          |
          v
SPI host interface
          |
          v
SiWx917 NCP (candidate wireless connectivity device)
```

This is a research hypothesis, not a confirmed target design. The current POC uses a candidate MMIO adapter and behavioral endpoints; it does not yet connect to a real MIPS subsystem, a specific SPI controller, or Silicon Labs hardware. The key first check is whether the selected MIPS subsystem already has a compatible memory-mapped SPI controller and what bus protocol it exposes.

## What is established vs. not established

| Finding | Evidence / tag |
|---|---|
| The current repository implements a simulation-focused candidate MIPS-MMIO → LOT transaction router → 4×4 ready/valid crossbar → behavioral endpoints → response router path. | [Confirmed — repository RTL and README](../README.md) |
| The latest user-reported ModelSim Intel FPGA Edition 2021.1 regression passed all 10 testbenches; 16/16 routes were exercised in the reported coverage run. | [Confirmed as reported local evidence — README](../README.md). This is not a CI result. |
| Silicon Labs documents an EFR32-host / SiWx91x-NCP setup with SPI and UART connection examples. | [Confirmed — Silicon Labs NCP guide](https://docs.silabs.com/wiseconnect/latest/wiseconnect-getting-started/getting-started-with-ncp-mode-with-efr32) |
| Arm AMBA describes AXI for high-frequency/high-bandwidth interconnects, AHB for embedded/low-latency use, and APB for low-bandwidth/control peripheral traffic. | [Confirmed — Arm AMBA overview](https://www.arm.com/architecture/system-architectures/amba) |
| A small memory-mapped SPI controller is the most likely first integration point between LOT and an SPI NCP, provided one exists in the target subsystem. | [Inference — validate against the selected MIPS SoC/RTL and board] |
| The final target is a SiWx917 NCP, with a particular EFR32 host board and expansion board. | [Check — not decided by MobilFlex] |
| The selected MIPS core's bus protocol, clock/reset domains, address map, and peripheral inventory are known. | [Check — inspect target MIPS integration] |
| A specific SPI mode, clock limit, pin mapping, and SDK configuration are correct for the intended board revision and firmware build. | [Check — verify exact product guide, schematic, SDK example/configuration, and board revision] |

## Candidate options

| Option | Description | Benefits | Main risks / checks | Current position |
|---|---|---|---|---|
| A. Reuse an existing SPI controller | LOT routes MMIO transactions to a memory-mapped SPI controller; the controller drives the NCP's SPI interface. | Clear separation between bus routing and serial protocol; avoids unnecessary custom serial logic. | Must confirm controller exists, bus compatibility, register interface, FIFO/interrupt/DMA needs, SPI mode/clock, reset and pin mux. | **Preferred first investigation** [Inference] |
| B. Add a small SPI controller | Same path as A, but implement or integrate an SPI controller if the subsystem has none. | Keeps the LOT crossbar protocol-neutral; serial protocol stays in a distinct block. | Additional RTL, register map, verification, timing and integration work; licensing must be checked if reusing external IP. | Fallback if A is unavailable [Inference] |
| C. Add a LOT-to-SPI/UART bridge | A custom bridge converts LOT transactions into serial commands. | Can fit a genuinely custom LOT endpoint contract. | Duplicates responsibilities if a normal SPI controller can be reused; requires protocol definition, timeout/error handling, buffering and verification. | Do not choose before defining the need [Inference] |
| D. Treat radio as a direct LOT endpoint | Crossbar sends a native transaction directly to the radio block. | Potentially simple in a purely abstract model. | A radio NCP normally exposes a host interface; the crossbar cannot directly replace SPI/UART/SDIO controller behavior without a defined hardware/protocol boundary. | Not recommended without a concrete interface spec [Inference] |
| E. Use a standard bus interconnect rather than custom LOT routing | Evaluate AXI/AHB/APB-compatible infrastructure if the CPU-side bus and target integration already use it. | Standardized interfaces and potential reuse of existing bridges/IP. | Depends on MIPS core bus, IP availability/licensing, address map and whether custom LOT semantics add value. | Compare before freezing the interface [Inference] |

## Recommended next steps

1. **Freeze the boundary, not the implementation:** write a short LOT bus contract (request/response fields, address width, byte enables if needed, IDs, error responses, ready/valid rules, reset, clocking).
2. **Inspect the actual MIPS subsystem:** identify the core, bus protocol, data/address widths, existing SPI/UART controllers, memory map, clock/reset domains, and interrupt model.
3. **Check controller reuse:** if an existing memory-mapped SPI controller fits, use it as a LOT target; otherwise compare a small SPI controller against a custom bridge.
4. **Choose real endpoints only after the architecture is clear:** CONTROL/DATA/STATUS/ID behavioral endpoints are useful for fabric verification, but they are not a claim that the final design has four physical boards or radio endpoints.
5. **Verify at each layer:** unit-test bus adapter, transaction router, crossbar, controller, and behavioral SPI target separately; then run end-to-end simulation including reset, busy/backpressure, timeout/error and response handling.
6. **Do not claim hardware validation yet:** run synthesis, timing/resource analysis, and board tests only after selecting the exact MIPS subsystem, device, boards, toolchain and firmware configuration.

## Questions the research should resolve

- Which MIPS core/subsystem and bus protocol are actually in scope?
- Does it already include a memory-mapped SPI controller? If so, what is its register interface and clock/reset behavior?
- Is the Silicon Labs device intended to be an NCP or an SoC running the application locally?
- Which exact radio/module/board revision and SDK version are in scope?
- What is the intended traffic: control-plane register access, bulk data transfer, or a separately specified data-plane interface?
- Is the goal an architectural demonstrator, synthesizable reusable IP, or a board-validated prototype?

## Scope boundary

This brief recommends a path to investigate; it does not finalize the system architecture. Matter/Thread/Wi-Fi are higher-level networking/connectivity technologies. The LOT crossbar routes local transactions; it should not be described as a Matter/Thread packet router unless a separate packet-level function is explicitly specified.

## Primary sources

1. Arm, [AMBA system architecture overview](https://www.arm.com/architecture/system-architectures/amba) — protocol positioning for AXI/AHB/APB.
2. Arm, [AMBA specifications](https://www.arm.com/architecture/system-architectures/amba/amba-specifications) — specification index; exact protocol/version should be selected from the target system requirements.
3. Silicon Labs, [Getting started with NCP mode with EFR32](https://docs.silabs.com/wiseconnect/latest/wiseconnect-getting-started/getting-started-with-ncp-mode-with-efr32) — host/NCP architecture and SPI/UART examples.
4. Silicon Labs, [SiWx917 NCP SPI protocol application note prerequisites](https://docs.silabs.com/wifi-application-notes/1.0.1/wifi-siwx917-ncp-spi-protocol-application-note/prerequisites) — NCP host-interface prerequisites; read in the context of that specific SPI-protocol application note.
5. Silicon Labs, [SiWx917 NCP firmware-update examples](https://docs.silabs.com/wifi-application-notes/latest/wifi-siw917-ncp-firmware-update-application-note/firmware-update-examples) — examples involving host communication for firmware update; not a substitute for the runtime application interface specification.
6. Open-source candidate, [dpretet/axi-crossbar](https://github.com/dpretet/axi-crossbar) — parametric AXI4 crossbar implementation; review its current license, supported features, verification and maintenance state before adoption.

## Change log

- 2026-10-11: Added a source-linked architecture hypothesis, options, evidence labels, and verification boundary. No RTL behavior changed.
