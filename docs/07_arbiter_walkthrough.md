# 07 — Crossbar Arbiter Walkthrough

## Purpose

The POC uses a simple per-output round-robin scheduler for a 4×4 crossbar. It is a deterministic functional baseline, not a production NoC scheduler.

## Signal path

1. **Build requests — `xbar_4x4.sv`**: each input presents `in_valid`, `in_dst`, and `in_data`. A request is formed when the source is valid and its destination encoding is legal. Request generation does not depend on `out_ready`.
2. **Select winners — `xbar_scheduler.sv`**: each output has its own `rr_ptr[output]`. It scans from that pointer, wraps around, and selects the first eligible requester. `used_input` prevents an input from being granted to multiple outputs in the same cycle.
3. **Route payload**: the grant matrix routes the selected input payload to the output. `out_valid` stays asserted for a selected request even while the destination is not ready.
4. **Handshake and pointer update**: `in_ready` is asserted for a selected source only when its destination is ready. The output transfer is complete when `out_valid && out_ready`; only then does that output's round-robin pointer advance past the winner.

## Fairness example

With all four inputs continuously requesting output 0 and output 0 ready, reset starts the pointer at input 0. Consecutive successful transfers select inputs 0, 1, 2, and 3, then wrap to 0. If output 0 is stalled, its pointer does not advance and the selected request/data must remain stable under the source ready/valid contract.

## Verification focus

The testbench suite should check connectivity, arbitration uniqueness, fairness under sustained contention, output VALID persistence during backpressure, stable output payload while stalled, and recovery after READY returns.

## What iSLIP would add

The current scheduler performs one simple round-robin selection per output with an input-exclusivity mask. iSLIP uses iterative request, grant, and accept phases with coordinated matching and specific pointer-update rules. It adds scheduler complexity, so it should be compared against this baseline using equivalent traffic and measured throughput/fairness.

## Suggested call explanation

> “Each output has a round-robin pointer. It scans requesters from that pointer, and an input-exclusivity mask prevents one source from being selected by multiple outputs. VALID is independent of READY, so a selected request remains visible during backpressure; the pointer advances only after a completed handshake. This is a functional baseline. iSLIP would be a separate iterative matching comparison.”
