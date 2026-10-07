# 04 — Interconnect

## Responsibilities

The interconnect layer sits between the MIPS-facing adapter and the switching fabric.

It is responsible for:

- transaction normalization
- destination selection
- request/response flow
- backpressure propagation
- isolation of endpoint-specific protocol logic

## Initial implementation

The first implementation uses a generic single-beat transaction interface. It intentionally avoids claiming AXI/AHB/Wishbone/MIPS-specific compliance.

## Later work

Once the MIPS bus is confirmed, this layer will be updated with a protocol-specific adapter and compliance tests.
