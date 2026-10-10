# 07 — Crossbar Arbiter Walkthrough

## Purpose

The POC uses a simple per-output round-robin scheduler for a 4×4 crossbar. The goal is a deterministic, understandable baseline—not a claim that this is a production NoC scheduler.

## Signal path

1. **Build requests — `xbar_4x4.sv`**  
   Each input presents `in_valid`, a destination `in_dst`, and payload `in_data`. A request is placed in `req[input][destination]` when the source is valid and its destination encoding is in range. In the current baseline, downstream `out_ready` is also included in this request condition.

2. **Select winners — `xbar_scheduler.sv`**  
   Each output has its own `rr_ptr[output]`. For output `o`, the scheduler scans inputs starting at `rr_ptr[o]`, wraps around the end of the input range, and selects the first eligible requester. `used_input` prevents one input from being granted to more than one output in the same cycle.

3. **Route the payload — `xbar_4x4.sv`**  
   The grant matrix controls the output data mux. A granted input's payload is routed to the corresponding output. The baseline is combinational, so no register stage is added to the data path.

4. **Advance fairness state**  
   The scheduler computes `next_rr[o]` as the input after the selected winner, wrapping to input 0 after input `N-1`. The current baseline writes this next pointer on the clock edge. Because request generation currently includes `out_ready`, the selected grant is suppressed when the destination is stalled.

## Fairness example

With all four inputs continuously requesting output 0, and with output 0 ready, reset initializes the pointer to input 0. Consecutive successful cycles select inputs 0, 1, 2, and 3, then wrap back to 0. The directed testbench checks this deterministic progression.

## Current design limitation

The current request condition is:

```systemverilog
if (in_valid[i] && valid_dst[i] && out_ready[in_dst[i]])
    req[i][in_dst[i]] = 1'b1;
```

Consequently, `out_valid` can depend combinationally on `out_ready`. This is a known limitation of the functional baseline. A protocol-hardening iteration should form requests independently of `out_ready`, drive `out_valid` from arbitration, assert `in_ready` only for an accepted transfer, and advance each output's round-robin pointer only on its completed handshake. That change must also add checks that `out_valid` and `out_data` remain stable while `out_valid && !out_ready`.

Do not describe the current implementation as a fully timing-closed or production-ready ready/valid crossbar.

## What iSLIP would add

The current scheduler performs one simple round-robin selection per output with a shared input-exclusivity check. iSLIP is an iterative matching algorithm with request, grant, and accept phases. It coordinates input and output decisions over iterations and has specific pointer-update rules intended to improve matching under contention. It would add complexity and should be evaluated against this baseline using comparable traffic patterns and measured throughput/fairness—not added merely as a name.

## Suggested call explanation

> “I implemented a 4×4 combinational crossbar with one round-robin pointer per output. Each output scans from its pointer, grants the first eligible input, and the input-exclusivity mask prevents one source from being selected by multiple outputs. After a selected transfer, the pointer advances to the next input. This is a verified functional baseline. I documented the current ready/valid dependency as a limitation; a next iteration would make request generation independent of ready and update fairness state only on a completed handshake. iSLIP would be a separate iterative matching comparison.”
