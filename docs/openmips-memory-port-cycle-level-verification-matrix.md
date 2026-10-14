# OpenMIPS Memory-Port Cycle-Level Verification Matrix

**Status:** Verification specification; not evidence that the candidate processor has been simulated with the LOT bridge.  
**Candidate:** `grantae/OpenMIPS`, MIPS32 + `DataCache_2KB`.  
**Purpose:** Convert the source-inspection findings into observable cycle-level checks before connecting the real core.

## 1. Boundary under test

The unit under test should be the memory-port wrapper between the OpenMIPS data-cache memory interface and (a) the existing RAM controller/model and (b) the LOT request/response fabric. The first test must not require the processor to boot.

Capture, at minimum, these signals on every rising edge:

- Native request: `DataMem_Address`, `DataMem_ReadWord`, `DataMem_ReadLine`, `DataMem_WriteWordReady`, `DataMem_WriteLineReady`, `DataMem_WriteWordBE`, `DataMem_Out`.
- Native return: `DataMem_In`, `DataMem_Offset`, `DataMem_Ready`.
- Qualification: physical-address-valid and cache attribute from the actual internal core/cache path.
- Wrapper outputs: RAM command/address/data/byte-enable and LOT valid/destination/payload.
- LOT return: ready, response-valid, response-ready, response-data, response-error.
- Wrapper state and sticky diagnostic outputs.

Do not substitute the existing candidate bridge's unit-test driver for native-source evidence. The native request timing must be observed from the selected RTL revision or a simulation that instantiates the actual cache/core.

## 2. Required cycle-level scenarios

| ID | Stimulus | Cycle-level checks | Pass condition |
|---|---|---|---|
| CP-01 | Uncacheable aligned word read in the selected LOT window | Record first assertion of `DataMem_ReadWord`; confirm address/qualification stability until completion; delay LOT response | Exactly one LOT request handshake; response data appears with the native completion pulse; no RAM read is issued |
| CP-02 | Uncacheable aligned full-word write in LOT window | Observe `DataMem_WriteWordReady`, data, byte enables, and write-buffer state across backpressure | One stable LOT write; no write-buffer dequeue/completion before matching LOT response |
| CP-03 | Ordinary uncached word read outside LOT window | Hold RAM response off for multiple cycles | RAM command remains correctly represented; LOT remains inactive; one native completion occurs when RAM returns data |
| CP-04 | Cache-line fill | Return all required words using the native `DataMem_Offset` sequence | All line traffic stays on RAM; no line request is truncated to 32 bits or sent to LOT |
| CP-05 | Dirty-line writeback | Exercise the cache path that emits `DataMem_WriteLineReady` | Full 128-bit writeback payload reaches RAM unchanged; LOT remains inactive |
| CP-06 | LOT-window access with unexpected cache attribute or invalid physical address | Inject the mismatch only in the wrapper test; in the core test observe genuine sidebands | No LOT request; diagnostic/fault behavior matches the documented integration policy |
| CP-07 | Partial-byte write in LOT window | Drive each supported byte-enable pattern other than `4'b1111` | No full-word LOT side effect and no silent widening; explicit reject/fault behavior |
| CP-08 | Downstream LOT backpressure | Hold LOT ready low for several cycles | LOT valid, destination, and payload remain stable; no duplicate request |
| CP-09 | Delayed LOT response | Accept request, delay response, and keep observing native cache/write-buffer state | No early native completion; response is associated with the accepted request only |
| CP-10 | LOT endpoint error | Return an error response | Diagnostic is raised and the system's documented error policy is exercised; do not claim CPU exception support without an actual exception path |
| CP-11 | Reset with a request outstanding | Assert reset after LOT request acceptance, then attempt a late response | Behavior matches the chosen coordinated-reset, drain, or cancellation contract; no unowned response is silently accepted |
| CP-12 | Simultaneous/conflicting native commands | Exercise only combinations shown legal by the source, and inject illegal combinations in wrapper-only tests | Legal traffic is preserved; illegal bundles are detected without duplicate RAM/LOT side effects |

## 3. Native source instrumentation questions

Answer these with waveforms from the exact selected OpenMIPS revision before freezing adapter state transitions:

1. On which state and edge is `ReadWord_M` asserted for an uncacheable read, and how is it deasserted after `Ready_M`?
2. When does `WordOutReady_M` represent a stable write-buffer entry, and what event advances/dequeues that entry?
3. Is the buffered word-write address and cache attribute stored together with the data/byte enables? If not, can the wrapper reliably distinguish an uncacheable MMIO store from a cacheable writeback?
4. Does `Ready_M` complete an uncacheable write only after the external side has captured the request, or after the operation itself has completed? Compare the actual cache state transition and write-buffer update.
5. For line fills, what is the precise order of `DataMem_Offset`, `DataMem_In`, and `DataMem_Ready`, and how many completion pulses are required?
6. How does reset affect the cache state, write buffer, and memory commands? Is coordinated reset across the LOT fabric guaranteed by the system?
7. What safe architectural action is possible after an endpoint error, given the native memory port has no explicit error response pin?

Record the repository URL, exact commit SHA, simulator/version, testbench revision, and waveform/log artifact for every answer. A source comment or a testbench that only models the expected behavior is not sufficient evidence for the native cycle timing.

## 4. Integration gates

Do not wire the bridge into the full processor until all of these are true:

- [ ] Exact OpenMIPS commit is pinned and license/provenance review is recorded.
- [ ] The actual internal physical-address-valid and cache-attribute signals are exposed by a minimal wrapper; neither is tied to a constant.
- [ ] CP-01 through CP-12 are implemented, with core-native scenarios distinguished from wrapper-only negative tests.
- [ ] The source timing questions above are answered with RTL references and waveforms.
- [ ] RAM word, line-fill, and dirty-line writeback paths preserve the native protocol.
- [ ] Reset ownership and error policy are explicitly selected.
- [ ] A minimal program can access RAM and each LOT register in a full-core simulation.

## 5. Evidence boundary

This document specifies the next verification work. It does not claim that the candidate bridge has passed these native-cycle tests, that OpenMIPS boots in this repository, or that CPU-to-LOT end-to-end integration is complete. The existing bridge CI only verifies the standalone classifier/bridge testbench.
