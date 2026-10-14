# OpenMIPS-to-LOT Integration Wiring Plan

**Status:** Source-level integration plan only. The candidate bridge and its unit test are not wired into a complete OpenMIPS processor top-level.

## 1. Current verified evidence

The candidate memory bridge smoke test passed in GitHub Actions on 14 October 2026:
- Workflow run: https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38545810076
- Commit: `7a2b742dcf56b108dbc265ac2550feab3dd76b21`
- Added coverage: STATUS register at offset `0x8` maps to destination 2; ID register at offset `0xC` maps to destination 3.

This verifies the dedicated classifier/bridge unit test only. It does not prove OpenMIPS boots, the native cache handshake matches the candidate bridge, or CPU-to-LOT works end to end.

## 2. Integration boundary and required signals

The proposed wrapper must connect the OpenMIPS data-memory interface to the candidate bridge while preserving the existing RAM path.

| Signal group | Source / destination | Integration rule |
|---|---|---|
| Word address | OpenMIPS data-memory address | It is word-addressed; reconstruct byte address as `{data_addr, 2'b00}`. Do not treat the port as a byte address. |
| Word read/write command | Data-cache / write-buffer command signals | Preserve the original timing and qualify command bundles; reject simultaneous incompatible commands. |
| Cache-line read/write | Native data-memory interface | Keep all line transfers on the RAM path. A line payload is 128 bits, not a LOT word. |
| Write byte enables | Native word-write interface | LOT writes are currently full-word only. Partial-byte writes must not be silently converted to full-word writes. |
| Physical-address valid | Internal core/cache sideband | Must be exposed from the reviewed core path. Do not tie to a constant. |
| Cache attribute | Internal core/cache sideband | Must be sourced from the real translated/cache attribute. The candidate uses `3'b010` to qualify the uncacheable MMIO path; confirm against the exact selected revision. |
| LOT request/response | Bridge ↔ LOT fabric | One outstanding LOT transaction is supported by the candidate bridge. Preserve response ownership until completion. |
| RAM return path | Bridge ↔ existing RAM subsystem | Preserve native RAM read data, ready, and offset semantics; do not replace line-fill behavior with a word-only stub. |
| Protocol fault | Bridge diagnostic output | Sticky fault is not a CPU exception. Define a system-level fault policy before product integration. |

The stock OpenMIPS top-level does not export all required qualification sidebands. A reviewed wrapper or deliberate core-port change is required before the bridge can be safely connected.

## 3. Address and routing contract

The current candidate test aperture is `0x1F00_0000–0x1F00_0FFF`, decoded with base `32'h1F00_0000` and mask `32'hFFFF_F000`. It is a test default, not an approved physical map.

Within that window, aligned full-word accesses map as follows:

| Byte offset | Destination | Register group |
|---:|---:|---|
| `0x0` | 0 | CONTROL |
| `0x4` | 1 | DATA |
| `0x8` | 2 | STATUS |
| `0xC` | 3 | ID |

Before integration, check the aperture against the selected TLB/cache-attribute configuration, RAM map, reset/exception vectors, and existing peripherals. Cache-line operations and ordinary RAM words must continue to use RAM.

## 4. Handshake questions that block full-core wiring

These questions must be answered against the exact OpenMIPS source revision, not assumed from the unit-test model:

1. Does the data-cache hold address, command, byte enables, and write data stable until `Ready_M`?
2. Does the write buffer retain its entry until the bridge's completion pulse, including when the LOT response is delayed?
3. Can a line command and a word/write-buffer command be asserted together in any legal cycle?
4. What exact cycle should return `DataMem_In`, `DataMem_Offset`, and `DataMem_Ready` for each read/write type?
5. Does the selected system reset both the bridge and LOT endpoints together? What happens to a late response if only one side resets?
6. How should a LOT error stop or recover the CPU when the native memory interface has no explicit error-response pin?

The candidate bridge assumes the upstream request remains valid and stable until completion; this assumption needs source-level timing confirmation and a cycle-level test. Do not infer native handshake compatibility from the passing unit test.

## 5. Reset and outstanding transaction policy

The bridge currently clears its pending state on reset. If the LOT fabric or endpoint can return a response after the bridge resets, that response may no longer have a matching owner. Before full integration, select and document one explicit system contract:

- **Coordinated reset:** bridge, request fabric, and endpoints reset together and guarantee that no pre-reset response can emerge afterward; or
- **Drain/quiesce reset:** stop accepting new requests and wait for accepted work to complete before clearing transaction state; or
- **Cancellation protocol:** explicitly cancel outstanding work and require downstream components to acknowledge cancellation.

Do not implement an assumed cancellation mechanism unless the fabric/endpoints actually support it. Add a test for reset asserted while a request is accepted and its response is delayed, and check both the chosen reset contract and any late-response behavior.

## 6. Recommended implementation sequence

1. Pin the exact OpenMIPS repository revision and review its license and redistribution obligations.
2. Build a minimal integration wrapper exposing the true physical-address-valid and cache-attribute signals, without changing functional behavior yet.
3. Add a source-revision-specific cycle-level test or instrumented simulation for native word reads, word writes, byte-enabled writes, line fills, dirty-line writebacks, and stalls.
4. Choose the reset contract and add the delayed-response reset test.
5. Connect the candidate bridge to the wrapper and preserve the original RAM controller path.
6. Run unit CI, native interface timing tests, and then a full-core simulation with a minimal program that performs RAM accesses and accesses each LOT register.
7. Only after functional CPU-level evidence, assess synthesis, timing, area, and hardware validation.

## 7. Acceptance criteria before claiming CPU-to-LOT integration

- Qualification sidebands come from real core signals, not constants.
- Ordinary RAM word operations, line fills, and dirty writebacks remain correct.
- LOT accesses are qualified by physical-address validity, cache attribute, alignment, aperture, and full-word semantics.
- Address/command/data remain stable according to the actual native handshake.
- Backpressure and delayed responses do not duplicate or lose transactions.
- Reset behavior is defined and tested with outstanding work.
- Errors have a documented system response.
- A full-core simulation demonstrates CPU-issued RAM and LOT operations.

Until these criteria are met, describe the bridge as **unit-tested candidate RTL**, not a completed CPU integration.


## New blocking findings from native cache-to-bridge review

See [Native OpenMIPS Cache-to-LOT Bridge Gap Review](openmips-native-cache-to-bridge-gap-review.md). The pinned native cache's default 36-bit physical-address configuration emits a 34-bit word address, while the current candidate bridge accepts a 30-bit word address for a 32-bit map. Upper address bits must be validated before any narrowing conversion. Also, processor-side PAddressValid_C and CacheAttr_C are not automatically transaction-aligned with a write-buffer entry exposed on WordOutReady_M/LineOutReady_M. Do not wire these sidebands directly to the bridge until qualification is carried with, or otherwise proven aligned to, the exact memory-port transaction.

**Next implementation gate:** design and test a source-revision-specific adapter that preserves the full native address and supplies transaction-aligned qualification for queued writes. Then connect the adapter to the bridge in a testbench that instantiates the actual pinned DataCache_2KB. Until that test passes, CPU-to-LOT remains unintegrated.


**Progress update:** an isolated [native OpenMIPS address guard](openmips-native-address-guard.md) now validates upper physical-address bits before narrowing the native word address; its dedicated Icarus CI passed ([run 38552329183](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38552329183)). The guard is wired through the adapter and wrapper. Actual-cache RAM/LOT integration and the full-core program-level LOT test now pass; the next gates are synthesis/timing, area estimation, and hardware validation.

## Qualification and adapter progress (14 October 2026)

A source-specific cache transformation now latches physical-address validity and cache attribute with the service request, then exposes the valid bit from the write-buffer head for queued word writes and from the active native uncacheable-read command. The actual pinned cache compiled and passed the regression that changes live sidebands after the original command is issued: [CI run 38554550754](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38554550754).

The initial `openmips_native_cache_adapter` now preserves the native 34-bit word address until upper-bit validation, keeps line commands on the RAM route, and forwards the transaction-aligned word qualification. Its standalone tests cover word read/write qualification, line routing, and fail-closed high-address rejection. The adapter is now connected to the candidate bridge. The actual pinned cache regression covers RAM line fills, dirty-line writeback, LOT read/write, address rejection, and reset/late-response behavior.


## End-to-end milestone update (14 October 2026)

The first regression that instantiates the actual pinned `DataCache_2KB` plus `openmips_native_cache_lot_wrapper` passed: [CI run 38555604302](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38555604302). A delayed LOT endpoint confirmed that a native uncacheable read at `0x1F00_0000` returns its data to the cache, and a full-word store at `0x1F00_0004` generates the expected LOT write and does not retire its queued write-buffer entry until the endpoint response handshake. Neither tested LOT command leaked to RAM.

This is the first actual-cache-to-bridge-to-LOT end-to-end proof in this POC, but it is not full-core CPU program execution. Next, extend the same integration bench with cache-line fill and dirty-line writeback through the RAM port, upper-address rejection, reset while LOT is outstanding, and then run a full-core program-level test before making broader integration claims.



## RAM response ownership fix (14 October 2026)

The bridge now latches RAM transaction ownership beyond the command pulse. Word responses/acks release ownership after one ready pulse; line reads keep the RAM route for four response beats. The delayed RAM line-response regression passed: [CI run 38557101949](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38557101949). The integrated actual-cache regression passed with a RAM line fill plus LOT read/write: [CI run 38556981169](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38556981169).

A two-way dirty-line eviction regression is now being added; full-core execution remains a separate gate.


## Dirty-line writeback verified end-to-end

The actual pinned cache regression now exercises a real two-way replacement: it fills two tags, dirties one line, makes it the replacement victim, and verifies the dirty 128-bit writeback contains the updated `DEAD_BEEF` word. The RAM writeback is acknowledged before the replacement fill completes. CI passed: [run 38557380566](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38557380566).

Full-wrapper high-address rejection and reset/late-response cases have been added to the next CI run. Full-core CPU program execution, synthesis, timing, area, and hardware validation remain outstanding.


## Full-wrapper address and reset tests passed

The actual-cache integration regression now covers: RAM line fills; a two-way dirty-line eviction/writeback; LOT read/write with delayed response; high physical-address rejection through the complete wrapper; and reset while a LOT request is outstanding followed by an injected late response. CI passed: [run 38557582605](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38557582605).

The next major gate is a full-core program-level test, followed by synthesis, timing/resource reports, and hardware validation.


## Full-core program test milestone

The integration now has a program-level test using the actual pinned MIPS32 top-level and caches. A short ROM program performs a LOT CONTROL read, a STATUS write using the returned value, and a DATA write. The delayed endpoint checks the exact physical addresses and write payloads. [CI run 38559781536 passed](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38559781536).

The test uses functional simulation models for generated BRAM/DSP IP; it is not synthesis or hardware validation. The full-core program now verifies cacheable RAM line fills, dirty-line writeback, and LOT MMIO. Next work is synthesis/timing/resource analysis.
