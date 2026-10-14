# OpenMIPS LOT Access Classifier — Candidate Block

**Status:** Preliminary RTL and unit test committed; CI result must be checked separately.  
**Not a complete processor bridge:** This block classifies access types only. It does not implement the OpenMIPS cache-side completion timing, RAM controller, cache-line sequencing, or CPU exception behavior.

## Files

- RTL: [`rtl/mips_if/openmips_lot_access_classifier.sv`](../rtl/mips_if/openmips_lot_access_classifier.sv)
- Testbench: [`tb/tb_openmips_lot_access_classifier.sv`](../tb/tb_openmips_lot_access_classifier.sv)
- CI workflow: [`.github/workflows/openmips-classifier-smoke.yml`](../.github/workflows/openmips-classifier-smoke.yml)

## Classification policy

The classifier receives a byte address, physical-address-valid indication, cache attribute, and decoded word/line command flags.

- A word request in the configurable LOT window routes to LOT only when the physical address is valid, cache attribute is `3'b010`, address is word-aligned, and any write is a full-word write (`BE=4'b1111`).
- A word request outside the LOT window routes to RAM.
- Cache-line reads and writes always route to RAM.
- A LOT-window word access with an invalid physical address, wrong cache attribute, misalignment, or partial write is rejected rather than silently truncated or rerouted.
- Simultaneous word and line command flags are rejected.
- Default test window: `0x1F00_0000–0x1F00_0FFF`. This is only a classifier test default, **not an approved OpenMIPS physical map**. Change the parameters only after boot/vector/RAM/peripheral overlap review.

## Unit test coverage

The testbench covers qualified LOT read/write, partial-write rejection, misalignment, cache-attribute mismatch, invalid physical address, normal RAM word access, line read/write routing, and conflicting command rejection.

## Required next integration work

1. Validate the classifier input meanings against the exact OpenMIPS revision and configured `PABITS`.
2. Reconstruct the byte address from the candidate core's physical address and word-addressed external memory signals in a wrapper with explicit address-unit conversion.
3. Implement and verify the RAM-side line fill/writeback path and LOT request/response state machine.
4. Confirm when `DataMem_Ready` must pulse for word reads, line beats, and buffered writes.
5. Define endpoint-error handling because the candidate memory interface does not expose a conventional error input.
6. Connect the actual processor only after standalone wrapper tests and a cycle-by-cycle interface review pass.

## Evidence boundary

A unit-test pass verifies only this classifier. It does not prove that the selected OpenMIPS core boots, that the test physical map is conflict-free, or that CPU-to-LOT transactions work end to end.
