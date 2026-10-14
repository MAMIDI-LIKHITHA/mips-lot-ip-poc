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

- `tb/tb_openmips_native_cache_port.sv` — instantiates the actual upstream `DataCache_2KB` module and requests an uncacheable word read and then a cacheable line fill.
- `tb/models/openmips_bram_model.sv` — simulation-only behavioral replacement for the vendor-generated dual-port BRAM primitive used by the cache set.
- `.github/workflows/openmips-native-cache-port-smoke.yml` — checks out the pinned source, compiles the actual cache RTL and dependencies with Icarus Verilog, then runs the test.

The test checks that the real cache asserts `ReadWord_M` for an uncacheable read and eventually produces a processor-side `Ready_C` completion after the memory model supplies a one-cycle `Ready_M` pulse. It then requests a different cacheable address, observes `ReadLine_M`, supplies four data words with offsets 0 through 3, and checks for the second processor-side completion. It also fails if line or write-buffer commands appear during the isolated uncacheable read.

## Evidence and limitations

- This is a **cache-module-level** test, not a full `MIPS32` processor test and not CPU-to-LOT integration.
- The BRAM model is for simulation only; it is not vendor-equivalent sign-off and must not be used for synthesis.
- The smoke test covers an uncacheable read and a basic four-beat cache-line fill. It does not validate dirty-line writeback, write-buffer retirement for stores, TLB/MMU qualification wiring, LOT error handling, or reset coordination.
- The CI result must be checked on the workflow page before treating the new test as passing.
