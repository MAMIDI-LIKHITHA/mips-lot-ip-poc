# 19 — Candidate MIPS Adapter

## Status

Candidate only — not verified and not the final MIPS interface.

The available project material does not specify the actual MIPS core bus. The
repository therefore contains a concrete adapter skeleton that shows where the
CPU-facing protocol will connect without claiming that its signals match the
real MIPS implementation.

## Candidate CPU-side handshake

- req_valid / req_ready: request handshake.
- req_write: read/write operation.
- req_addr: byte address.
- req_wdata: write data.
- rsp_valid / rsp_ready: response handshake.
- rsp_rdata: read response.
- rsp_error: response error.

## Candidate LOT-side request

The adapter converts a CPU request into lot_valid, lot_ready, lot_dst and
lot_payload. The destination is selected from configurable address regions.

Default candidate regions:

- 0x0000_0000 -> destination 0
- 0x0001_0000 -> destination 1
- 0x0002_0000 -> destination 2
- 0x0003_0000 -> destination 3

These addresses are placeholders, not the project's final address map.

## Important limitation

The existing XBAR is request-only. It has no reverse response network.
Therefore this adapter does not claim complete CPU read/write transaction
completion. A proper implementation still needs the confirmed MIPS protocol,
final address map, request format, endpoint response semantics, reverse response
routing, error/timeout behavior, and ordering/outstanding-transaction rules.

The next integration decision is whether the LOT fabric should use a separate
response XBAR or another response-routing mechanism.
