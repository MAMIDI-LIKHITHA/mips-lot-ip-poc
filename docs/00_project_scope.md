# 00 — Project Scope

## Purpose

Develop a simulation-oriented LOT IP building block intended to be insertable into an existing MIPS-based architecture.

## Source-derived scope

The available project planning material describes the intended path as:

MIPS Core → MIPS/Bus Interface → Interconnect Fabric → 4×4 Crossbar → protocol/MAC-facing interfaces

The final implementation boundary is not yet frozen.

## Required workstreams

1. MIPS interface study and definition
2. Interconnect architecture
3. 4×4 crossbar and arbitration
4. Configuration/register interface
5. Thread/Wi-Fi/BLE/Ethernet interface study
6. Silicon Labs DVK evaluation
7. Verification
8. Performance measurement
9. IP/license/toolchain due diligence
10. Final integration package

## Non-goals for the current stage

- Do not assume the LOT block is a Matter border router.
- Do not assume each crossbar port maps one-to-one to Thread/Wi-Fi/BLE/Ethernet.
- Do not select a final third-party crossbar before protocol and target requirements are confirmed.
- Do not claim system-level verification before the MIPS-side and endpoint interfaces exist and are tested.
