# OpenMIPS CPU-to-LOT Test Map and Transaction Contract

**Status:** Proposed testbench plan only; no RTL changed by this document.  
**Target:** Provisional `grantae/OpenMIPS` evaluation candidate.  
**Purpose:** Define the smallest safe experiment before writing a CPU-side adapter.

## 1. Scope of the first integration test

The first test should prove only that a CPU-originated, aligned, full-word, **uncacheable** MMIO read or write can reach one behavioral LOT endpoint and return a response.

In scope:

- One CPU-side initiator.
- One outstanding MMIO transaction at a time.
- 32-bit byte address and 32-bit data.
- Aligned word operations only (`address[1:0] == 2'b00`).
- Full-word writes only; no partial byte/halfword writes.
- LOT endpoint response data and error observed by the adapter/testbench.
- Normal instruction fetches, ordinary data loads/stores, and cache-line transfers remain on the RAM model.

Out of scope: cacheable accesses to LOT, bursts/cache-line transfers to LOT, multiple outstanding transactions, interrupts, physical wireless hardware, and performance claims.

## 2. Address-map policy

**Do not freeze a physical MMIO base address yet.** The reference core's RAM layout, boot/exception vectors, translation setup, and any existing peripheral ranges must be established first. The current LOT candidate's low-address test regions are not evidence that those addresses are free in an OpenMIPS system.

The integration testbench should use named parameters rather than scattering literals:

| Parameter | Meaning | Initial value |
|---|---|---|
| `TEST_RAM_BASE` | Base of behavioral RAM | Set after confirming the core's boot/test memory layout |
| `TEST_RAM_LIMIT` | End of RAM range, with documented inclusive/exclusive convention | Set with RAM model |
| `TEST_LOT_BASE` | Base of the LOT MMIO window | **TBD — choose only after overlap review** |
| `TEST_LOT_SIZE` | Size of the test-only MMIO window | 4 KiB is a reasonable testbench proposal, not a product requirement |
| `TEST_LOT_ENDPOINT` | LOT destination index for the selected endpoint | Match the actual instantiated endpoint index |

Before simulation, assert or check that the RAM and LOT ranges do not overlap, and record how the testbench handles addresses outside both regions. If the existing LOT fabric expects four 64-KiB destination regions, add an explicit adapter-side mapping from the chosen physical MMIO window to the selected endpoint; do not silently assume that the core's physical address equals the LOT endpoint's local offset.

## 3. Endpoint register behavior

The current behavioral endpoint documents these local offsets:

| Local offset | Access | Expected behavior |
|---|---|---|
| `0x0000` CONTROL | Read/write | Read current control value; write updates it |
| `0x0004` DATA | Read/write | Read current data value; write updates it |
| `0x0008` STATUS | Read only | Read returns `0x00000001`; write reports error |
| `0x000C` ID | Read only | Read returns `0x4C4F5430`; write reports error |
| Other offsets | Read/write | Endpoint reports error |

These are local behavioral-model offsets, not a finalized software ABI. The adapter must convert the physical MMIO address into the expected endpoint address without losing alignment or offset bits.

## 4. Required request qualification

A CPU memory operation must not be sent to LOT solely because its address falls in the chosen window. The adapter/testbench must establish all of the following for the same request:

1. The core reports a valid physical address.
2. The physical address matches the LOT test window.
3. The cache attribute is the documented uncacheable encoding (`3'b010` in the inspected candidate cache RTL).
4. The operation is a supported single-word read or write.
5. The address is word-aligned.
6. The adapter is not already holding an uncompleted request.

If a LOT-window access arrives with an unexpected cache attribute, unsupported operation, or misalignment, fail the test loudly and define an explicit error/fault strategy before treating it as a supported transaction. Do not quietly route it to RAM or reinterpret a cache-line operation as a word operation.

## 5. Keep RAM traffic separate

The adapter must preserve the core's normal memory behavior:

- Instruction fetches stay on the RAM/instruction-memory path.
- Cacheable data accesses stay on the RAM/data-memory path.
- Cache-line fills and writebacks stay on the RAM path.
- Only the specifically qualified uncacheable MMIO word operation enters LOT.
- The testbench must detect accidental LOT routing of a cache-line request or normal RAM request.

The OpenMIPS interface distinguishes word and line transactions and carries byte-enable/offset information. The current LOT request contract has no byte-enable field. Therefore, this first experiment must reject or flag partial writes instead of dropping byte enables or using read-modify-write on side-effecting registers.

## 6. One-outstanding transaction sequence

Use this conceptual sequence for the first adapter:

1. Observe a valid, qualified CPU MMIO request.
2. Latch its physical address, read/write command, write data, and any metadata needed to complete the CPU-side operation.
3. Present one stable LOT request until the LOT request handshake occurs.
4. Wait for the matching LOT response; do not issue a second request in the meantime.
5. Return read data or the defined error outcome to the CPU-side memory interface.
6. Retire the latched request only when the CPU-side interface's documented completion condition is met.

The exact acceptance and completion signals must be confirmed from the chosen OpenMIPS RTL before implementing this sequence. Do not infer them from signal names alone. Since the inspected top-level interface does not expose a conventional explicit bus-error input, determine how an endpoint error or unsupported request is reported to the core; if no safe fault mechanism exists, keep error cases testbench-visible and do not claim architectural exception support.

## 7. Boot and cache-attribute setup checklist

Before connecting the processor:

- [ ] Confirm the reference core revision and applicable license.
- [ ] Identify reset vector, exception vectors, RAM initialization format, and the minimal program-loading method.
- [ ] Trace how the test program's virtual address becomes the intended physical address.
- [ ] Confirm the required TLB/direct-mapped configuration and how the cache attribute is set to `3'b010`.
- [ ] Confirm the exact timing and semantics of `DataMem_PAddressValid`, read/write commands, word offset, byte enables, and completion.
- [ ] Confirm whether cache write-buffer traffic can represent an ordinary store, a writeback, or either.
- [ ] Choose a physical LOT window only after checking RAM, vectors, and existing peripheral regions.
- [ ] Document the unmapped-address and endpoint-error behavior.

## 8. Acceptance tests for the first CPU-to-LOT simulation

| Test | Expected result |
|---|---|
| Read ID at the LOT window | Endpoint returns `0x4C4F5430`; one LOT request accepted |
| Write CONTROL then read CONTROL | Readback matches written full word |
| Write DATA then read DATA | Readback matches written full word |
| Read STATUS | Returns `0x00000001` |
| Normal RAM load/store | Served by RAM model; zero LOT requests |
| Instruction fetch while MMIO is idle | Served by instruction/RAM model |
| Cacheable access to a normal RAM address | Served by RAM path |
| Misaligned or partial MMIO operation | Explicitly rejected/flagged; never silently truncated |
| LOT request backpressure | Request payload remains stable until accepted |
| LOT response backpressure | Response is retained until consumed |
| Reset during a pending transaction | Behavior is explicitly checked against the chosen core interface contract |

Do not mark the CPU-to-LOT integration complete until the tests above run in a simulator with the actual candidate core and adapter. The existing 12-test LOT regression remains the baseline and must be rerun after RTL changes.

## 9. Evidence boundary

This document is a test plan and contract proposal. It does not establish a conflict-free physical address, a working OpenMIPS boot image, a completed adapter, an executed CPU-to-LOT simulation, or new regression results. The address map and native-interface timing remain open until confirmed from the actual core configuration and RTL.
