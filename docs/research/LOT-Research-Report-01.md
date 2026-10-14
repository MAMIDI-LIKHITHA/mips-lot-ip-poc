# LOT Connectivity Layer — Research Report 01 (text summary)

**Prepared for:** Mihai Buta and Swapnil (MobilFlex)  
**Author:** Likhitha Mamidi  
**Source review date in original report:** 11 October 2026  
**Status:** Preliminary research. Nothing here is a decided design; no hardware tests were performed.

> Repository-friendly summary of the supplied PDF report. Review the original report and cited sources before making decisions.

## Summary

The research compares possible Silicon Labs connectivity modes, the role of Matter/Thread border routing, the uncertain MIPS-side bus, network-stack ownership, and vendor support/customization questions.

- **Silicon Labs mode:** Not decided. The original report uses a Wi-Fi NCP arrangement (EFR32 host plus SiWx917 radio) as a research reference because it has a clear host-to-radio link. Thread RCP and single-chip Wi-Fi SoC are alternatives.
- **Border router:** Needed to connect Thread to other IP networks, but not inherently required for a Matter-over-Wi-Fi end device. Whether LOT should be a border router is a product-scope decision.
- **MIPS-side bus:** Public 2022 eVocore material described ACE or AXI-class system interfaces. This is historical evidence, not confirmation of the actual target core/bus; stakeholder confirmation is required.
- **Network-stack ownership:** Depends on mode. In NCP mode the connectivity chip runs the relevant stack; in RCP mode the host runs the higher-level stack; in SoC mode the single chip hosts the stack.
- **Customization and licensing:** Public factory-programming information does not prove that internal silicon IP can be changed or licensed. Confirm directly with the vendor.

## Connectivity modes considered

| Mode | Typical connection | Potential relevance | Trade-off / open point |
|---|---|---|---|
| Wi-Fi NCP (EFR32 host + SiWx917 radio) | SPI or UART; SDIO may be listed for particular configurations | Clear host-to-radio boundary for an inserted LOT block | Two boards/chips; exact board, SDK, and host protocol must be confirmed |
| Thread RCP | Host link such as USB/serial in documented setups | Relevant if LOT is intended to support a Thread border-router role | Host owns more of the stack; host software load needs review |
| Wi-Fi SoC (SiWx917) | No separate host-to-radio link inside the single-chip product | Simplest hardware arrangement to evaluate | Less useful for demonstrating an external LOT-to-radio bridge |

## Interconnect implications

A crossbar is an on-chip transaction switch; it does not replace Wi-Fi, Thread, Matter, or a radio host protocol. If the target MIPS subsystem has a compatible AXI interface, an AXI-class interconnect is worth evaluating. Do not infer compatibility from historical public core announcements alone. Confirm the exact CPU, protocol variant, SPI controller, GPIO, address map, and transaction requirements first.

The supplied decision memo treats Arm NIC-400 as a **conditional** candidate if the CPU bus fits, the required IP/tools are covered by the commercial access tier, and an SPI controller plus GPIO are available. PULP axi_xbar is an open-source fallback candidate if AXI4 is confirmed. Neither is selected or validated by this report.

## Recommended next steps

1. Ask stakeholders to confirm the target MIPS core/subsystem and native bus.
2. Choose the Silicon Labs device and NCP/RCP/SoC mode for the proof of concept.
3. Inventory available SPI controller, GPIO, bridge, clock/reset, and driver support.
4. Verify Arm IP/tool access, manufacturing fees, and permitted use; compare a current alternative if relevant.
5. Keep findings tagged **Confirmed**, **Inference**, or **Check**, and link each claim to a primary source.
6. Test the chosen integration in simulation before making synthesis, timing, or hardware claims.

## Primary-source starting points
- Arm, [NIC interconnect](https://www.arm.com/products/silicon-ip-system/corelink-interconnect/nic)
- Arm, [Flexible Access](https://www.arm.com/products/flexible-access)
- Arm, [AMBA specifications](https://www.arm.com/architecture/system-architectures/amba/amba-specifications)
- [PULP AXI](https://github.com/pulp-platform/axi)
- Silicon Labs, [SiWx917 host-interface guidance](https://docs.silabs.com/wiseconnect/latest/wiseconnect-developers-guide/migr-porting-steps/implement-hardware-abstraction)

For detailed evidence, tables, and source notes, consult the supplied PDF before making a product or licensing decision.
