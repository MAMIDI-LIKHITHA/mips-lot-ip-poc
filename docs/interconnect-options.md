# Interconnect Options and Conditional Candidate Comparison

**Status:** research comparison only; no final IP selected.  
**Last reviewed:** 14 October 2026

## Starting point

The current POC has a custom request/response contract and a 4×4 ready/valid crossbar. This is useful for exploring transaction routing, but it does not establish that a custom fabric is the best final integration choice. The target MIPS core, native bus, and peripheral inventory must be known before making that decision.

The guiding rule is to reuse compatible existing IP where possible. Any vendor-IP preference below is conditional on interface fit, tool/IP access, licensing, and stakeholder confirmation.

## What LOT needs

1. Connect a MIPS-based subsystem to roughly four endpoints, including a Silicon Labs connectivity device.
2. Reach an SPI controller and GPIO signals (reset, interrupt, wake); these may be exposed through a peripheral bus such as APB.
3. Return an error for unmapped addresses rather than hanging.
4. Be viable for eventual ASIC use, not only FPGA prototyping.
5. Have usable documentation, verification collateral, and a support/maintenance path.

## Candidate comparison

| Candidate | Type / protocols | Potential fit | Main limitations and checks |
|---|---|---|---|
| **Arm CoreLink NIC-400** | Commercial; AXI3, AXI4 or AHB-Lite inputs, AXI/AHB-Lite/APB outputs | Conditional candidate if the selected CPU interface is compatible; APB ports could attach a memory-mapped SPI controller | Confirm Flexible Access tier, tool availability, manufacture fees, use with the selected subsystem, and whether a newer Arm fabric is more suitable. NIC-400 does not provide ACE coherency. |
| **PULP axi_xbar** | Open-source AXI4 crossbar and separate AXI4-Lite crossbar; Solderpad Hardware License 0.51 | Fallback if AXI4 is confirmed and community-supported RTL is acceptable | No vendor support; APB peripherals require suitable bridge/conversion logic. Verify current features and integration needs. |
| **dpretet/axi-crossbar** | Open-source AXI4 and AXI4-Lite | Alternative if AXI4 is selected | Check maintenance, supported features, verification, and bridge requirements. |
| **alexforencich/verilog-axi** | Open-source AXI components | Reference material may be useful | Project is marked deprecated; evaluate its successor and current maintenance before adoption. |
| **ZipCPU/wb2axip** | AXI, AXI-Lite and Wishbone-related components | Possible candidate if interface and features fit | Review exact license and compatibility before adoption. |
| **FPGA-vendor generated fabrics** | Tool-generated vendor-specific fabrics | Useful for FPGA prototypes within the relevant tool ecosystem | Generally not a portable ASIC interconnect choice. |
| **Custom 4×4 crossbar in this repo** | Local ready/valid protocol | Keep as simulation reference and learning artifact | No standard-bus bridges, silicon history, synthesis results, or production verification yet. |

## Functional needs matrix

| Need | NIC-400 | PULP axi_xbar | Custom POC |
|---|---|---|---|
| CPU-side interface | AXI variants/AHB-Lite; confirm exact fit | AXI4 | Requires adapter/bridge |
| APB peripheral connectivity | APB outputs available | Separate bridge needed | Bridge needed |
| Unmapped-address error | DECERR behavior described in manual | Check error-slave configuration | Review current simulation behavior against final contract |
| Generated collateral / vendor support | Tools and vendor support, subject to access | Community | Local project only |
| Silicon evidence in this repository | None | None | None |

## Recommendation and decision gates

**No final interconnect selection is approved by this document.** NIC-400 is a conditional candidate, not a committed design choice. PULP axi_xbar is a possible open-source fallback if AXI4 is confirmed.

1. Identify the exact MIPS core/subsystem and native bus (protocol variant, widths, ordering, and outstanding-transaction needs).
2. Inventory existing bridges, SPI controller, GPIO, clock/reset domains, and drivers.
3. Confirm the intended Silicon Labs part and NCP/RCP/SoC mode.
4. Verify license, commercial access, tool access, support, and integration effort for each viable candidate.
5. Keep the current RTL as a functional reference until a replacement demonstrates required behavior.
6. After selection, run equivalent regression tests, synthesis, timing analysis, and eventually hardware validation.

## Open checks

| Check | Status |
|---|---|
| Flexible Access tier includes NIC-400 and required tools | Open |
| Exact MIPS core and bus protocol | Open |
| Existing SPI controller and GPIO availability | Open |
| Whether NIC-450 or NI-700 is a better current option | Open |
| License and maintenance review for open-source candidates | Open |
| Synthesis, timing, area, power, and hardware measurements | Not performed |

## Sources

- Arm, [AMBA overview](https://www.arm.com/architecture/system-architectures/amba)
- Arm, [AMBA specifications](https://www.arm.com/architecture/system-architectures/amba/amba-specifications)
- Arm, [NIC interconnect](https://www.arm.com/products/silicon-ip-system/corelink-interconnect/nic)
- Arm, [Flexible Access](https://www.arm.com/products/flexible-access)
- Arm NIC-400 technical reference manual: https://documentation-service.arm.com/static/5f5a411f235b3560a01eb5ce
- [PULP AXI](https://github.com/pulp-platform/axi)
- [dpretet/axi-crossbar](https://github.com/dpretet/axi-crossbar)
- [alexforencich/verilog-axi](https://github.com/alexforencich/verilog-axi)
- [ZipCPU/wb2axip](https://github.com/ZipCPU/wb2axip)
- Silicon Labs, [SiWx917 host-interface guidance](https://docs.silabs.com/wiseconnect/latest/wiseconnect-developers-guide/migr-porting-steps/implement-hardware-abstraction)

## Non-claims

This comparison does not establish that the selected MIPS core uses AXI, that any candidate is compatible without modification, or that any option has been synthesized, timed, or hardware-validated in this repository.
