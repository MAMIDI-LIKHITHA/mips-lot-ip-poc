# 06 — Scheduler

## Initial policy

Round-robin arbitration is the first POC policy because it is easy to reason about and provides a deterministic fairness baseline.

## Required invariants

1. An output cannot grant more than one input.
2. An input cannot be granted to more than one output in the same cycle.
3. A granted request must correspond to an asserted request.
4. Reset must remove all grants.
5. Each output's round-robin pointer advances only when that output completes a valid/ready handshake.

## Ready/valid and backpressure

Requests are formed from source `in_valid` and a legal destination, independently of downstream `out_ready`. Arbitration can therefore assert `out_valid` while the destination is stalled. The selected input's `in_ready` is asserted only when its destination is ready, so the transfer occurs when VALID and READY are both high.

While `out_valid && !out_ready`, the source must hold its request and payload stable. With the pointer held on a stall, the same requester remains selected as long as it obeys that source-side ready/valid contract. The round-robin pointer advances after a completed transfer, not merely because a request is visible.

This RTL remains combinational from request/grant to output transfer; this change does not add pipeline registers or establish implementation timing/Fmax. If timing closure or interface integration requires it, registered or elastic buffering can later break long combinational paths.

## Head-of-line limitation

The current design is a simple single-request-per-source model rather than a buffered virtual-channel architecture. A source that cannot make progress can limit traffic behind it; the POC does not claim to eliminate head-of-line blocking.

## Future evaluation

McKeown-style scheduling/iSLIP is a research and comparison topic. Implement it only after the baseline is verified, then compare both designs with equivalent traffic for fairness and throughput.
