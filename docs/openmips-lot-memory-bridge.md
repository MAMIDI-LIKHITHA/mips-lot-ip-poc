# OpenMIPS LOT Memory-Port Bridge — Candidate RTL

**Status:** Candidate bridge RTL and focused testbench pass the dedicated Icarus Verilog GitHub Actions smoke test, including expanded backpressure, error-response, reset, and unmapped-offset checks ([run](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38545601674)).  
**Integration status:** Not connected to the unmodified OpenMIPS top-level. This is not evidence that the processor boots or that CPU-to-LOT works end to end.

## Files

- [Bridge RTL](../rtl/mips_if/openmips_lot_memory_bridge.sv)
- [Access classifier](../rtl/mips_if/openmips_lot_access_classifier.sv)
- [Bridge testbench](../tb/tb_openmips_lot_memory_bridge.sv)
- [Icarus CI workflow](../.github/workflows/openmips-memory-bridge-smoke.yml)

## What it implements

- Preserves the RAM-side interface for ordinary word accesses and all cache-line reads/writes.
- Reconstructs the byte address from the OpenMIPS word-address port by appending `2'b00`.
- Routes a qualified, aligned, full-word access in the configured LOT window to one of the current four LOT destinations: CONTROL, DATA, STATUS, or ID at offsets `0x0`, `0x4`, `0x8`, and `0xC`.
- Holds one LOT request outstanding at a time; it does not reissue while waiting for the matching response.
- Returns LOT read data and emits the cache-side `data_ready` completion pulse only when the LOT response is available. For writes, it similarly withholds completion until the response, so the write-buffer entry is not dequeued early.
- Raises a sticky `protocol_fault` on invalid LOT qualification, unsupported offsets, or a LOT error response. The native OpenMIPS memory port has no explicit error input, so the bridge does not pretend to raise a CPU exception.

## Mandatory wiring limitation

The stock OpenMIPS `MIPS32` top-level exposes `DataMem_Address`, read/line/write-buffer signals, and data/ready/offset return signals, but it does **not** export the data cache's physical-address-valid and cache-attribute sidebands. The bridge therefore requires `data_paddr_valid` and `data_cache_attr` from the internal core/cache path. These must be exposed by a reviewed integration top or a deliberate core wrapper change; do not tie them to constants to make the design appear to work.

The module currently supports `PABITS=32` only and uses a default test aperture of `0x1F00_0000–0x1F00_0FFF`. The aperture must be checked against the chosen TLB/cache-attribute setup, reset vectors, RAM map, and peripherals before system integration.

## Known limitations / next checks

1. Confirm the exact timing of `ReadWord_M`, buffered `WordOutReady_M`, and `Ready_M` on the selected OpenMIPS revision using a source-level timing test or full-core simulation.
2. Review simultaneous line and word commands against the cache write-buffer behavior. The classifier rejects conflicting command bundles.
3. Decide how a protocol fault should stop or recover the CPU; a sticky output alone is diagnostic, not architectural exception handling.
4. Test reset during an already accepted outstanding LOT transaction and define how a late/orphan response is handled; current unit coverage verifies fault reset, not reset cancellation semantics.
5. Add the bridge to a full-core integration top only after sideband wiring and RAM controller semantics are explicit.
6. Keep the passing unit-test evidence separate from full-core validation. The passing workflow proves only the bridge/classifier testbench behavior under Icarus, not native OpenMIPS handshake compatibility or CPU boot.

## Evidence boundary

The unit test targets routing and the simplified request/response handshake. It does not implement a RAM controller, four-beat line-fill engine, CPU exception path, boot ROM, or a complete OpenMIPS integration.
