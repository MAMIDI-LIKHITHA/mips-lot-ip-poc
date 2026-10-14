# OpenMIPS RTL Inspection — Data-Memory Boundary

**Status:** Source inspection completed; no adapter implemented yet.
**Reviewed candidate:** [grantae/OpenMIPS](https://github.com/grantae/OpenMIPS)
**Files inspected:** `hardware/src/MIPS32/MIPS32.v` and `hardware/src/MIPS32/Cache/DCache/DataCache_2KB.v`.

## Findings directly visible in the RTL

1. The top-level `MIPS32` module exposes separate instruction and data memory ports. Keep instruction fetch separate from the LOT MMIO path.
2. The data memory interface distinguishes cache-line reads (`DataMem_ReadLine`), single-word reads (`DataMem_ReadWord`), cache-line writes (`DataMem_WriteLineReady`), and single-word writes (`DataMem_WriteWordReady`).
3. The top-level data port has a 32-bit read-data input, a 2-bit incoming line-word offset, a 4-bit word byte-enable output, and a 128-bit write-data output. The 128-bit payload is used for line writes; word writes use the low 32 bits.
4. In `DataCache_2KB.v`, the RTL assigns `s_uncacheable = (CacheAttr_C == 3'b010)`. The state machine chooses `ReadWord_M` for an uncacheable read and `ReadLine_M` for a cacheable fill. This is a concrete RTL finding, but it must be confirmed against the core's cache-attribute definitions and address translation before system use.
5. The data-cache memory `Ready_M` input is documented as a one-cycle pulse for a valid read-data word or captured write-data. The cache-line interface therefore requires a sequence of word transfers, not a single 128-bit ready/valid handshake.
6. The `Address_M` signal is documented as a physical line address or word address depending on transaction type. Do not assume it is a byte address. A wrapper must convert units explicitly and preserve word offset information.
7. The cache has a write buffer and can emit cache writebacks as well as uncacheable word writes. A LOT bridge must distinguish the intended MMIO word access from cacheable line traffic; it must not forward every write-buffer entry to LOT.

## Adapter implications

- **Do not connect the existing LOT adapter directly** to this memory interface.
- A safe first scope is uncacheable, single-word MMIO reads/writes only, selected by an explicit physical-address region and verified cache attribute.
- Route normal memory and all cache-line transfers to a memory model/controller path.
- Preserve `DataMem_WriteWordBE`, 32-bit word data, address/offset semantics, and the one-cycle `DataMem_Ready` completion contract.
- Hold request metadata until the matching completion; the current LOT adapter's single-outstanding assumption must be reconciled with the core's request and ready timing.
- Confirm whether errors can be represented. The shown top-level memory interface has no explicit bus-error input, so the initial experiment should define a deterministic unmapped-address policy without pretending to signal a processor exception.

## Next required inspection

Before writing RTL, inspect `hardware/src/MIPS32/Core/MIPS_Defines.v` and the processor's physical-address/cache-attribute generation to confirm cache attribute encodings and address mapping. Then review the existing LOT request/response router and adapter contracts in this repository. Only after those contracts agree should we write a standalone wrapper and testbench.

## Validation status

This is a source-level review only. It does not prove OpenMIPS compiles in the current toolchain, that the cache-attribute setup for a selected address is correct, or that a LOT adapter works. The existing 12-test LOT regression remains the baseline; no new tests were run as part of this inspection.
