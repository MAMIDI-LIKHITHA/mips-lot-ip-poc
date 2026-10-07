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

## Candidate response interface

The adapter now accepts:

- lot_rsp_valid / lot_rsp_ready
- lot_rsp_rdata
- lot_rsp_error

It holds the CPU response until rsp_ready and allows only one outstanding
request.

## Payload sizing

The candidate payload is explicitly sized as:

{write, address, write_data}

The LOT payload width is parameterized as ADDR_W + DATA_W/2 + 1 so the write
bit does not overlap the address field.

## Important limitation

This remains a candidate interface. A proper final implementation still needs
the confirmed MIPS protocol, final address map, endpoint response semantics,
transaction ID requirements, timeout behavior, and ordering/outstanding rules.

The reverse response path is now represented by a separate protocol-neutral
response router in docs/20_response_path.md and rtl/interconnect/lot_rsp_router.sv.
