# Is NIC-400 suitable as core LOT IP?

**For:** Mihai  
**From:** Likhitha  
**Original memo date:** 12 October 2026  
**Status:** Preliminary; conditional candidate only.

## Short answer

NIC-400 may be a good on-chip interconnect candidate if the selected MIPS subsystem exposes a compatible AXI/AHB-Lite interface, MobilFlex has access to NIC-400 and required tools under its Arm agreement, and an SPI controller plus GPIO are available for the radio. This is not an approved design choice.

## Findings and checks

| Question | Preliminary finding | Status |
|---|---|---|
| Does it match the CPU bus? | NIC-400 supports AXI3, AXI4 and AHB-Lite interfaces; it does not provide ACE cache coherency. | Likely fit only; confirm actual core |
| Can it reach the radio? | APB output ports can attach an APB SPI controller; reset, interrupt and wake GPIOs are also needed. | Interface described in manuals; target wiring open |
| Is it large enough? | It has more ports than a small LOT prototype needs. Check exact limits against the applicable manual revision. | Confirm against manual |
| What happens on an unmapped address? | DECERR-style error response is described in the manual. | Confirm configuration and integration behavior |
| How is it built? | Arm tools such as AMBA Designer or Socrates generate implementation collateral. | Tool access open |
| Are all features included? | Some related Arm interconnect features/products are separately licensed. | Confirm contract |
| Is it accessible? | Flexible Access coverage and manufacturing fees must be checked with Arm/MobilFlex. Use with the chosen CPU core also needs confirmation. | Open |
| Is it the most current fit? | Compare NIC-400 with newer Arm interconnect options before selection. | Open |

## Fallback

PULP axi_xbar is an open-source AXI crossbar candidate if AXI4 is confirmed. It avoids the same commercial access question but requires community-supported integration and likely additional bridges for APB peripherals.

## Next steps

1. Confirm the Flexible Access tier, included IP, tools, and manufacturing terms.
2. Ask Arm whether the intended use with the chosen MIPS subsystem is permitted and supported.
3. Confirm the MIPS core/bus and whether a compatible SPI controller/GPIO already exists.
4. Compare NIC-400 with current alternatives and document a decision only after these checks.

## Sources
- Arm NIC-400 technical reference manual: https://documentation-service.arm.com/static/5f5a411f235b3560a01eb5ce
- Arm, [NIC interconnect](https://www.arm.com/products/silicon-ip-system/corelink-interconnect/nic)
- Arm, [Flexible Access](https://www.arm.com/products/flexible-access)
- [PULP AXI](https://github.com/pulp-platform/axi)

> This Markdown version preserves the key decision and open checks; it is not a replacement for reviewing the source manual and commercial terms.
