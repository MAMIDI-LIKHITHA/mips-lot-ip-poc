# Silicon Labs Host-Interface Research Notes

**Last reviewed:** 2026-10-11  
**Status:** Evidence summary for architecture exploration; exact target hardware not selected.

## Why this matters to LOT

The LOT POC is a local transaction-routing fabric. If a Silicon Labs wireless device is used as a network-connectivity NCP, the system needs a host interface between the processor subsystem and the radio device. A LOT crossbar alone does not implement SPI, UART, SDIO, Matter, Thread, or Wi-Fi.

## Findings

| Topic | Finding | Tag |
|---|---|---|
| NCP partitioning | Silicon Labs' EFR32-host guide describes an application running on an EFR32 host while the connectivity stack runs on a SiWx91x device in NCP mode. | [Confirmed — guide-specific] |
| Serial host interfaces | The guide describes SPI and UART examples for the host/NCP arrangement. | [Confirmed — guide-specific] |
| SPI/UART selection | The guide describes different board switch positions for SPI and UART in its example setup. Board labels and switch behavior must be checked against the exact board revision. | [Confirmed in guide; [Check] on intended hardware] |
| SPI protocol application note | The SiWx917 NCP SPI protocol note describes a host MCU with an SPI-main interface and an adapter-board prerequisite. | [Confirmed — scope is that SPI-protocol note] |
| Firmware update | Silicon Labs' firmware-update examples describe host communication options in the context of update flows. Do not treat firmware-update transport options as proof that every runtime NCP configuration supports the same set. | [Confirmed — guide-specific] |
| Interface support across all examples | Documentation can differ by application note, software release, device mode, and build configuration. An “SPI-only” statement in a specific SPI protocol note should not be generalized to all NCP modes; conversely, a list of possible interfaces should not be treated as proof that every SDK example supports each interface. | [Check — reconcile against exact SDK release and selected example] |
| Exact host kit and radio adapter | An EFR32MG24 kit such as xG24-PK6010A with a SiWx917 adapter is only an assumed reference pairing for investigation, not a MobilFlex decision. | [Check] |
| Pin mappings / electrical limits | Do not freeze pin numbers, SPI clock, UART flow control, or voltage assumptions from a generic guide. Verify the exact board schematic, user guide, SDK configuration and board revision. | [Check] |

## What this means for the LOT architecture

**[Inference — medium confidence]** If the selected wireless device is used as a SiWx917 NCP, the first architecture to investigate is:

```text
MIPS CPU
  |
  v
MIPS-side bus adapter
  |
  v
LOT transaction router + crossbar
  |
  v
Memory-mapped SPI controller
  |
  v
SPI wires / NCP host interface
  |
  v
SiWx917 NCP
```

Reuse an existing SPI controller if it is compatible with the target bus and NCP protocol. If no suitable controller exists, compare integrating a small SPI controller with building a custom LOT-to-serial bridge. A custom bridge should be selected only if the desired host protocol or transaction semantics require it.

The EFR32-host examples demonstrate a host/NCP pattern; they do **not** demonstrate that a MIPS core can connect directly to a SiWx917 without an appropriate controller/driver and software integration.

## Matter and Thread boundary

- Matter is an application-layer protocol and Thread is a networking technology; neither should be conflated with the local LOT crossbar.
- Silicon Labs' Thread RCP documentation describes a host/Radio Co-Processor arrangement used with an external host and OpenThread Border Router. That is a different integration pattern from a generic memory-mapped endpoint.
- For a Wi-Fi NCP, distinguish the host interface (such as SPI or UART, depending on the selected configuration) from the Wi-Fi connectivity stack running on the radio device.
- If the system goal is end-device connectivity, border-router functionality may be outside the LOT IP itself. Confirm which component owns Thread networking, Matter application logic, and border-router services.

## Questions to close before implementation

1. Is the target a SiWx917 NCP, a Silicon Labs SoC running the application locally, or a Thread RCP?
2. What exact board/adapter revisions and SDK version will be used?
3. Which NCP example/build configuration is selected, and what host interface does that exact configuration enable?
4. What is the exact runtime transport protocol and driver requirement—not only the firmware-update interface?
5. What are the SPI mode, supported clock, timing constraints, pin mux, reset sequencing, IRQ/handshake signals and electrical constraints for the selected boards?
6. Does the MIPS subsystem already have a compatible SPI controller and software driver?
7. Who implements the host-side NCP driver and how does it interact with the MIPS software stack?

## Primary sources

- Silicon Labs, [Matter Thread RCP](https://docs.silabs.com/matter/latest/matter-thread/matter-rcp) — Thread RCP context.
- Silicon Labs, [Matter Wi-Fi EFR32 NCP example](https://docs.silabs.com/matter/latest/matter-wifi-getting-started-example/getting-started-efx32-ncp) — EFR32-host NCP context.
- Silicon Labs, [NCP mode with EFR32 host](https://docs.silabs.com/wiseconnect/latest/wiseconnect-getting-started/getting-started-with-ncp-mode-with-efr32) — SPI/UART example setup.
- Silicon Labs, [SiWx917 NCP SPI protocol note prerequisites](https://docs.silabs.com/wifi-application-notes/1.0.1/wifi-siwx917-ncp-spi-protocol-application-note/prerequisites) — prerequisites for that SPI protocol example.
- Silicon Labs, [SiWx917 NCP firmware-update examples](https://docs.silabs.com/wifi-application-notes/latest/wifi-siw917-ncp-firmware-update-application-note/firmware-update-examples) — update-flow examples.
- Silicon Labs, [EFR32MG24 product page](https://www.silabs.com/wireless/zigbee/efr32mg24-series-2-socs) — product-level reference; select exact board documentation separately.
- Silicon Labs, [SiWx917 product page](https://www.silabs.com/wireless/wi-fi/siwx917-wireless-soc-series) — product-level reference; select exact device/module documentation separately.
- Silicon Labs, [BRD4187C user guide PDF](https://www.silabs.com/documents/public/user-guides/ug526-brd4187c-user-guide.pdf) — board-specific checks, only if this is the actual board.
- Silicon Labs, [BRD8045A schematic PDF](https://www.silabs.com/documents/public/schematic-files/BRD8045A-A01-schematic.pdf) — adapter-specific checks, only if this is the actual adapter.

## Important caution

The exact board pairing, pin mappings, SDK settings and interface limits are not yet verified for the target MobilFlex design. Do not present them as final design facts or claim board-level validation until the exact hardware and configuration have been identified and tested.
