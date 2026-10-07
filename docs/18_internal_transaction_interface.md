# 18 — Internal Transaction Interface

## Purpose

The LOT fabric now has a stable protocol-neutral transaction boundary before the actual MIPS-side protocol is known.

Signals:

- src_valid[N]: source has a valid one-beat transaction.
- src_ready[N]: source may transfer this cycle.
- src_dst[N]: destination index.
- src_data[N]: transaction payload.
- dst_valid[N]: destination has a valid transaction.
- dst_ready[N]: destination can accept this cycle.
- dst_data[N]: transaction payload.

A transfer occurs when valid and ready are both high.

## Current behavior

- One source requests one destination per cycle.
- One destination accepts at most one source per cycle.
- Arbitration is round-robin per output.
- A destination that is not ready is not requested.
- An invalid destination index produces no request or grant.
- Current implementation is single-beat.
- No burst or outstanding transaction tracking is implemented.

## Integration boundary

MIPS core -> confirmed MIPS/bus adapter -> LOT transaction interface -> 4x4 XBAR -> endpoint adapter

The MIPS adapter remains unimplemented because the available project material does not identify the exact MIPS bus protocol.

This separates fabric verification from MIPS integration: the fabric can be verified now, while the MIPS adapter waits for the actual bus specification.
