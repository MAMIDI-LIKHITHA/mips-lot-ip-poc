# OpenMIPS Memory-Port Handshake Semantics — Integration Gate

**Status:** RTL-level follow-up inspection; adapter RTL still intentionally deferred.  
**Candidate:** [grantae/OpenMIPS](https://github.com/grantae/OpenMIPS) `MIPS32` top-level with `DataCache_2KB`.  
**Source files:** `hardware/src/MIPS32/MIPS32.v`, `hardware/src/MIPS32/Cache/DCache/DataCache_2KB.v`, `hardware/src/MIPS32/Core/Processor.v`, `hardware/src/MIPS32/Core/MIPS_Defines.v`.

## 1. Key conclusion

The OpenMIPS data-memory boundary is **not** a conventional request/ready-valid bus. It is a cache-to-memory interface with separate read-word, read-line, write-word, and write-line indications plus a one-cycle `DataMem_Ready` completion indication. The cache contains a write buffer, so the external memory request can be a buffered writeback rather than the CPU instruction's immediate store.

Do not connect `DataMem_WriteWordReady` or `DataMem_WriteLineReady` directly to LOT `valid` without a wrapper state machine and transaction classification.

## 2. Signals at the MIPS32 top level

| Signal | Meaning from source comments / assignments | Integration rule |
|---|---|---|
| `DataMem_Address` | Physical address expressed in word-address units; transaction meaning depends on word vs line command | Convert to byte address explicitly. Do not treat it as a byte-address bus. |
| `DataMem_ReadWord` | Read one word for an uncacheable access | Candidate for the initial LOT read path, after qualification. |
| `DataMem_ReadLine` | Read a cache line for a cacheable fill | Route to RAM only. |
| `DataMem_WriteWordReady` | A word write is waiting in the data-cache write buffer | Not a CPU-side valid/ready handshake by itself; capture the write before acknowledging completion. |
| `DataMem_WriteLineReady` | A line write is waiting in the data-cache write buffer | Route to RAM only. |
| `DataMem_Out[31:0]` | Low word-sized data portion of the cache output; for a word write use the low 32 bits | Latch data when accepting the buffered word-write command. |
| `DataMem_Out[127:0]` | 128-bit cache-line payload for line-write traffic | Do not truncate or route to LOT. |
| `DataMem_WriteWordBE[3:0]` | Byte enables for a buffered word write | Initial LOT scope should require `4'b1111`; otherwise explicitly reject/flag. |
| `DataMem_Offset[1:0]` | Word offset within a returned cache line | Used by cache-line response sequencing; it is not a byte strobe. |
| `DataMem_Ready` | Memory side reports a data word or captured write has completed; described as one-cycle | Generate according to the cache's exact sequence, not by holding it high like ready/valid. |
| `DataMem_In[31:0]` | Returned memory word | For a line fill, supply the words in the required sequence and drive the matching line offset. |

The top-level `MIPS32.v` wires these external pins to `DataCache_2KB`; `Processor.v` feeds the data cache with a valid physical address, cache attribute, read/write command, and write data. The external memory port is therefore one level below the CPU's decoded memory operation.

## 3. What the cache RTL confirms

In `DataCache_2KB.v`:

- `s_uncacheable = (CacheAttr_C == 3'b010)`.
- `ReadWord_M` is asserted in the fill state for an uncacheable access when the write buffer is empty.
- `ReadLine_M` is asserted for a cacheable fill when the write buffer is empty.
- `LineOutReady_M` and `WordOutReady_M` indicate the type of pending buffered write.
- `WordOutBE_M` is sourced from the write-buffer entry; `DataOut_M` is the buffered payload.
- The uncacheable read data is captured in `FILL_WAIT_1`, and the state machine moves to `FILL_WAIT_WORD` when `Ready_M` is seen for an uncacheable read.
- A dirty cache line can cause a writeback state before a miss/fill continues. The external wrapper must handle these cacheable writebacks as RAM traffic, not MMIO.

These findings establish why a bridge needs transaction type decoding and state; they do not, by themselves, prove a complete CPU-to-LOT timing implementation.

## 4. Required wrapper behavior

Use a memory-port wrapper that preserves a RAM path and a separate LOT path:

1. **Classify reads:** if `DataMem_ReadLine` is asserted, service the line through RAM. If `DataMem_ReadWord` is asserted, qualify the reconstructed physical byte address and cache attribute before deciding whether it is LOT MMIO or ordinary RAM.
2. **Classify writes:** if `DataMem_WriteLineReady` is asserted, service the line write through RAM. If `DataMem_WriteWordReady` is asserted, latch address, `DataMem_Out[31:0]`, and byte enables. Route it to LOT only if the physical region, uncacheable/write-buffer conditions, alignment, and full-word byte-enable policy all pass. Otherwise service through the correct RAM path or flag a contract violation.
3. **One outstanding LOT transaction:** latch the complete word request once; keep the LOT payload stable under backpressure; wait for its response; then generate the one-cycle cache-side completion at the right point in the cache state machine.
4. **Reads:** hold the LOT response data until it can be returned on `DataMem_In` at the appropriate cache-side completion cycle.
5. **Line operations:** keep line fills and line writebacks entirely on the RAM path. Do not convert a line operation to one LOT word.
6. **Addressing:** because `DataMem_Address` is word-addressed, reconstruct byte address consistently for region decode (for the ordinary word address, the low two byte-address bits are zero). For line operations, preserve line and word-offset sequencing.

## 5. Timing must be validated before implementation

The following remain implementation gates rather than assumptions:

- Exact cycle in which `DataMem_ReadWord` is first asserted and how long it remains asserted.
- Exact write-buffer behavior around `DataMem_WriteWordReady` and when a write can be dequeued.
- Whether `DataMem_Ready` is required for a read response, a buffered write completion, or both in each state.
- How `DataMem_In` and `DataMem_Offset` must be driven during four-word cache-line fills.
- Whether cache write-buffer entries preserve sufficient metadata to distinguish uncacheable MMIO stores from cacheable writebacks in every state.
- How unsupported LOT operations or endpoint errors can be represented, given the memory interface has no explicit error response pin.
- How the CPU's physical address and cache attribute are held stable through stalls and flushes.

The next RTL change should be a small memory-port wrapper plus a dedicated testbench that exercises RAM line traffic, uncacheable word reads/writes, write-buffer backpressure, and reset. Do not wire in the real processor until those wrapper tests pass and the source timing has been checked cycle-by-cycle.

## 6. License and provenance gate

The upstream OpenMIPS repository identifies its project license as LGPL-3.0. Before copying any upstream processor source into this repository or distributing a combined design, review the exact license text, notices, modification obligations, and the intended distribution model. This note does not vendor or modify upstream code.

## 7. Evidence boundary

This is a source inspection and integration plan. No OpenMIPS source was copied into the LOT repository, no wrapper RTL was added, and no CPU-to-LOT simulation was run. The current LOT regression remains the prior 12-test baseline; it does not validate this proposed processor bridge.
