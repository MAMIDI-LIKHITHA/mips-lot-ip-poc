# Native OpenMIPS Cache-to-LOT Bridge Gap Review

**Status: integration blocker review; no cache-to-bridge wiring is claimed by this document.**

## Reviewed source

- OpenMIPS repository: https://github.com/grantae/OpenMIPS
- Pinned revision: https://github.com/grantae/OpenMIPS/commit/d606b35e9d5260aef20de2a58660c8303a681e9c
- Native cache module: hardware/src/MIPS32/Cache/DCache/DataCache_2KB.v
- Existing candidate bridge: ../rtl/mips_if/openmips_lot_memory_bridge.sv
- Existing native-cache test: ../tb/tb_openmips_native_cache_port.sv

## Confirmed native cache-port facts

The pinned DataCache_2KB declares PABITS=36 by default. Its Address_M[(PABITS-3):0] is a word address: the source comment says it represents physical line (bits 35:4) or word (bits 35:2) addressing. At PABITS=36, the port is 34 bits wide (Address_M[33:0]). The current bridge is deliberately restricted to PABITS=32 and accepts only data_addr[29:0]. Directly connecting Address_M[29:0] without checking the upper four bits would silently alias physical addresses above the 32-bit aperture.

The native cache exposes:
- ReadLine_M: a 128-bit cache-line read sequence.
- ReadWord_M: a single uncacheable 32-bit read.
- LineOutReady_M: a queued cache-line writeback.
- WordOutReady_M: a queued single-word write.
- WordOutBE_M: byte enables for the queued word write.
- DataOut_M[127:0]: queued write payload; line payload for line writes and low 32 bits for word writes.
- Ready_M: a one-cycle memory-side completion/beat pulse.

The current bridge's data_write_word_ready input corresponds most naturally to WordOutReady_M, and its line-write input to LineOutReady_M. These are queued write-buffer commands, not necessarily the same cycle's processor request.

## Blocking issue: qualification sidebands are not transaction-aligned

The candidate bridge currently classifies a word request using data_paddr_valid and data_cache_attr. At the native processor-facing cache interface, PAddressValid_C and CacheAttr_C describe the current processor-side request. But when the cache write buffer is non-empty, Address_M, WordOutReady_M, LineOutReady_M, WordOutBE_M, and DataOut_M can describe a previously queued write. Reusing the current processor-side sidebands to qualify that queued transaction can associate the wrong request's physical-address-valid or cache-attribute information with it.

The cache has an internal s_uncacheable service signal, but that internal signal is not a public output. Before safe wiring, the integration must either:
1. Expose a reviewed transaction-aligned qualification sideband for the memory-port transaction, including queued write-buffer entries; or
2. Change the bridge contract so it derives LOT eligibility only from a source demonstrably aligned with the exact memory-port command and address.

Do not tie the qualification inputs high or simply connect the current PAddressValid_C/CacheAttr_C signals without proving their cycle alignment.

## Required adapter contract before implementation

1. Preserve the complete 34-bit native word address until high-bit validation is performed.
2. For the initial 32-bit LOT/RAM map, reject or fault any memory-port address with Address_M[33:30] != 0; never silently truncate it.
3. Convert the validated 30-bit word address to a 32-bit byte address by appending 2'b00 exactly once.
4. Keep ReadLine_M and LineOutReady_M on the original RAM path, including four-beat line fills and dirty-line writebacks.
5. Route ReadWord_M and WordOutReady_M only after transaction-aligned physical-valid/cache-attribute qualification, aperture/alignment checks, and full-word byte-enable checks.
6. Preserve native one-cycle Ready_M semantics. A LOT write-buffer entry must not retire until its response is consumed; line and word write-buffer entries must not be acknowledged early.
7. Add a test that instantiates the actual pinned DataCache_2KB, the revised adapter/bridge, a delayed-response LOT endpoint model, and a RAM model. Exercise uncacheable LOT reads/writes, ordinary RAM reads, line fills, dirty writeback, backpressure, and qualification changes while a queued write is pending.

## Current conclusion

The existing bridge unit test proves the bridge's own classification and handshake contract. The native-cache smoke tests prove selected behavior of the upstream cache in isolation. They do not yet prove the cache and bridge can safely be wired together. The width mismatch and transaction-alignment issue above must be resolved before describing CPU-to-LOT integration as implemented.

## Progress: isolated address-width guard added

An isolated guard now preserves the native 34-bit word address until bits [33:30] have been checked, suppresses commands with nonzero upper bits, and only then exposes the lower 30 bits. Its dedicated Icarus workflow passed: [run 38552329183](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38552329183). See [native address guard contract](openmips-native-address-guard.md). This is an independently tested building block, not yet wired into the bridge; transaction-aligned qualification for queued writes remains unresolved.

## Qualification patch implemented and smoke-tested

The repository now carries a deterministic source transformation in `scripts/apply-openmips-cache-qualification.py`, applied in CI to the exact pinned OpenMIPS revision before compiling the actual `DataCache_2KB`. The patch:
- Latches the service request's cache attribute and physical-address-valid bit instead of consulting live processor-side sidebands while a transaction is pending.
- Extends the native write-buffer entry by one metadata bit and exports `WordOutPAddressValid_M` from the FIFO head for queued word writes.
- Exports `ReadWordPAddressValid_M` for the active uncacheable word-read command.
- Tests that changing live processor-side qualification after command issue does not change the qualification attached to the native read/write command.

The pinned-cache regression passed on 14 October 2026: [run 38554550754](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38554550754).

A first adapter module, `rtl/mips_if/openmips_native_cache_adapter.sv`, now combines those aligned sidebands with the 34-bit address guard and maps native word/line commands to bridge-facing signals. Its standalone CI is running separately. **The adapter is not yet wired into `openmips_lot_memory_bridge`, and there is not yet an actual-cache + adapter + bridge + delayed-LOT-endpoint end-to-end regression.** CPU-to-LOT integration therefore remains unproven.


## First actual-cache-to-LOT integration regression passed

The new wrapper `rtl/mips_if/openmips_native_cache_lot_wrapper.sv` connects the address/qualification adapter to the candidate bridge. `tb/tb_openmips_native_cache_lot.sv` instantiates the actual pinned `DataCache_2KB`, the wrapper, and a deliberately delayed LOT endpoint. It verifies:
- A native uncacheable read at `0x1F00_0000` becomes one LOT read request and the response data reaches the processor-facing cache interface.
- A native uncacheable full-word store at `0x1F00_0004` becomes a LOT write to destination 1 with the expected data.
- The queued store remains present while the LOT endpoint delays its response and retires after the response handshake.
- The tested LOT accesses do not leak to RAM and no address/protocol fault is raised.

End-to-end simulation passed in [CI run 38555604302](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38555604302). This is meaningful CPU-cache-port-to-LOT evidence, but it is **not full-core CPU program execution**. Remaining integration gates include exercising cache-line fills and dirty writebacks through the wrapper/RAM path in the same end-to-end test, high-address fail-stop behavior through the complete wrapper, reset with an outstanding LOT request, and the CPU error/fault policy. Synthesis, timing, area, and hardware validation remain outstanding.



## RAM response ownership fix (14 October 2026)

The integrated line-fill test exposed a real bridge defect: the native cache drops `ReadLine_M` after issuing the command, while four RAM response beats arrive later. The bridge previously recomputed RAM routing from the live command and therefore dropped those responses. The bridge now latches RAM ownership until a word response/acknowledgement completes or all four line-fill beats have been accepted. The bridge-level delayed-four-beat regression passed: [CI run 38557101949](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38557101949). The actual-cache wrapper regression also passed with a RAM line fill alongside LOT read/write: [CI run 38556981169](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38556981169).

The next extension is a two-way dirty-line eviction test through the same wrapper. Full-core program execution and hardware validation remain outstanding.


## Dirty-line eviction through the integrated wrapper passed

The actual-cache integration regression now fills both ways at a matching virtual index, dirties one line, adjusts the replacement state, and forces that dirty line to be evicted. The test confirms the writeback payload contains the updated `DEAD_BEEF` word, the 128-bit line write is acknowledged on the RAM path, and the subsequent replacement line is filled from RAM. The integrated test passed: [CI run 38557380566](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38557380566).

High-address rejection through the full wrapper and reset with a late LOT response are now added to the same regression and await CI.
