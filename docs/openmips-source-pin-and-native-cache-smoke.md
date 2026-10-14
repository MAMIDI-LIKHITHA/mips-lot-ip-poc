# OpenMIPS Source Pin and Native Cache-Port Smoke Test

## Source pin

- Repository: https://github.com/grantae/OpenMIPS
- Reviewed commit: [`d606b35e9d5260aef20de2a58660c8303a681e9c`](https://github.com/grantae/OpenMIPS/commit/d606b35e9d5260aef20de2a58660c8303a681e9c)
- Commit date: 2019-06-05
- License file at that revision: [LICENSE](https://github.com/grantae/OpenMIPS/blob/d606b35e9d5260aef20de2a58660c8303a681e9c/LICENSE), GNU LGPL v3.
- Primary module under test: `hardware/src/MIPS32/Cache/DCache/DataCache_2KB.v`.

The CI workflow checks out this exact SHA rather than the mutable `master` branch. Review LGPL-3.0 obligations before copying or distributing upstream RTL or a combined design.

## Native cache-port smoke test

Files in this repository:

- `tb/tb_openmips_native_cache_port.sv` — instantiates the actual upstream `DataCache_2KB` module and covers an uncacheable word read, cacheable line fill/hit, cacheable store/readback, and an uncacheable buffered word-store.
- `tb/models/openmips_bram_model.sv` — simulation-only behavioral replacement for the vendor-generated dual-port BRAM primitive used by the cache set.
- `.github/workflows/openmips-native-cache-port-smoke.yml` — checks out the pinned source, compiles the actual cache RTL and dependencies with Icarus Verilog, then runs the test.
- `tb/tb_openmips_write_buffer.sv` and `.github/workflows/openmips-write-buffer-smoke.yml` — isolate the uncacheable word-store payload, byte enables, and write-buffer retirement check.
- `tb/tb_openmips_dirty_eviction.sv` and `.github/workflows/openmips-dirty-eviction-smoke.yml` — fill both ways at one index, dirty the selected LRU candidate, and verify line writeback precedes replacement fill.

The test checks that the real cache asserts `ReadWord_M` for an uncacheable read and eventually produces a processor-side `Ready_C` completion after the memory model supplies a one-cycle `Ready_M` pulse. It then requests a different cacheable address, observes `ReadLine_M`, supplies four data words with offsets 0 through 3, and checks for the second processor-side completion. It also fails if line or write-buffer commands appear during the isolated uncacheable read.

## CI evidence

- [Native cache-port regression](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38550249273) — passed; cache fill/hit/store plus uncacheable buffered word-store payload and retirement.
- [Focused write-buffer regression](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38550412760) — passed; isolated word-store payload and retirement.
- [Dirty-line eviction regression](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38550727478) — passed; log observed dirty line payload `deadbeef111100011111000211110003` and confirmed replacement fill after the queued line writeback.

## Evidence and limitations

- These are **cache-module-level** tests, not a full `MIPS32` processor test and not CPU-to-LOT integration.
- The BRAM model is for simulation only; it is not vendor-equivalent sign-off and must not be used for synthesis.
- The dirty-eviction test covers one deterministic two-way replacement sequence. It is not exhaustive cache verification.
- These tests do not validate TLB/MMU qualification wiring, LOT error handling, reset coordination, synthesis, timing closure, or physical hardware behavior.
