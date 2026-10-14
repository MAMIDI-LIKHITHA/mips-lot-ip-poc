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
