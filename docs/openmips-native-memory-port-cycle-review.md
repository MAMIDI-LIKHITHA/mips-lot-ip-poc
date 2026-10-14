# OpenMIPS Native Memory-Port Source Review — Cycle-Level Findings

**Review date:** 2026-10-14  
**Candidate source:** `grantae/OpenMIPS`, files `hardware/src/MIPS32/Cache/DCache/DataCache_2KB.v`, `hardware/src/MIPS32/MIPS32.v`, and `hardware/src/MIPS32/Core/Processor.v`.  
**Source retrieval:** public upstream `master` file URLs were inspected for this review. Because `master` is mutable, this is not a pinned-revision sign-off. Pin a commit SHA before implementing the wrapper.

## Findings visible in the retrieved cache RTL

1. **The external request outputs are state-derived, not a conventional valid/ready request.** The cache assigns `ReadLine_M = (state == FILL) & WB_Empty & ~s_uncacheable` and `ReadWord_M = (state == FILL) & WB_Empty & s_uncacheable`. The request indication is therefore tied to the cache FSM and whether the write buffer is empty.
2. **Buffered writes are represented by write-buffer occupancy and entry type.** `LineOutReady_M = ~WB_Empty & WB_DataOut[0]`; `WordOutReady_M = ~WB_Empty & ~WB_DataOut[0]`. `WordOutBE_M` comes from `WB_DataOut[36:33]`, and `DataOut_M` comes from `WB_DataOut[128:1]`. This confirms that the external word-write indication represents a buffered entry, not necessarily the store currently executing in the processor.
3. **The cache documents `Ready_M` as a one-cycle pulse.** Its port comment describes one valid read-data word or capture of write data. Do not hold it high as a level-sensitive bus-ready signal.
4. **Read completion is state-dependent.** In the visible FSM, `FILL_WAIT_1` waits until `Ready_M`; an uncacheable access then advances to `FILL_WAIT_WORD`, while a cacheable line fill advances to `FILL_WAIT_2`. `s_uncacheable_data` captures `DataIn_M` while the state is `FILL_WAIT_1`. A wrapper must therefore return read data and pulse completion with the exact timing expected by this FSM.
5. **Line fills are multiple word completions.** The cache has `FILL_WAIT_1` through `FILL_WAIT_4` states and a 2-bit `DataInOffset_M` input. A single 128-bit line response cannot be substituted for the native sequence without an explicit line adapter.
6. **Address interpretation depends on the transaction.** The cache interface comment describes `Address_M` as a physical line address or word address; read-line/write-line and word requests must be treated according to their command type. The current bridge's byte-address reconstruction is a candidate for the word path only and must be checked against the exact top-level slice and parameterization.
7. **Cache attribute encoding observed in the candidate source:** `s_uncacheable = (CacheAttr_C == 3'b010)`. Treat this as a candidate-specific finding until the selected revision's definitions, translation setup, and system memory map are pinned and reviewed.

## What this review does not establish

- It does not prove that the candidate bridge's current `data_ready` timing is compatible with the cache FSM in all cases.
- It does not establish whether write-buffer metadata retains all physical-address/cache-attribute information needed to classify a buffered word write safely.
- It does not resolve simultaneous command combinations, endpoint-error handling, reset with an outstanding LOT transaction, or the lack of a native CPU bus-error response.
- It does not demonstrate that the processor boots, that an instruction reaches the LOT aperture, or that CPU-to-LOT works end to end.
- It is not a substitute for a simulation of the actual OpenMIPS cache/core connected to the wrapper.

## Required next implementation step

Pin the exact upstream commit and license text, then create a small source-compatible test harness around the actual `DataCache_2KB` module (or full core if build dependencies require it). Instrument `state`, `WB_Empty`, `ReadWord_M`, `ReadLine_M`, `WordOutReady_M`, `LineOutReady_M`, `Ready_M`, `DataIn_M`, and `DataInOffset_M`. Use waveforms to establish request hold time, buffered-write retirement, uncacheable-read completion, and four-beat line-fill timing before changing the candidate bridge.

**Evidence classification:** upstream source inspection only; no new RTL simulation or CPU-to-LOT integration was run by this review.
