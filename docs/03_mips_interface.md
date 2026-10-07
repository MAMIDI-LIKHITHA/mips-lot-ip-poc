# 03 — MIPS Interface

## Current state

The exact MIPS-side bus/transaction interface is **not confirmed** by the available planning material.

## Questions to resolve

- Which existing MIPS core/IP is being integrated?
- Which bus protocol is exposed by the core?
- Address and data widths?
- Byte enables?
- Read/write handshake?
- Response/error signaling?
- IDs or tags?
- Outstanding requests?
- Burst transactions?
- Ordering guarantees?
- Clock/reset domains?
- Memory map and LOT register window?

## Integration rule

The generic POC transaction interface must not be described as the final MIPS interface until these questions are answered.

## Planned adapter

`rtl/mips_if/mips_bus_adapter.sv` will translate the confirmed MIPS-side protocol into the internal LOT transaction interface.
