# 06 — Scheduler

## Initial policy

Round-robin arbitration is the first POC policy because it is easy to reason about and provides a deterministic fairness baseline.

## Required invariants

1. An output cannot grant more than one input.
2. An input cannot be granted to more than one output in the same cycle.
3. A granted request must correspond to an asserted request.
4. Reset must remove all grants.
5. Arbitration state must advance only according to a defined grant policy.

## Backpressure and head-of-line behavior

The baseline crossbar uses ready/valid handshaking. An output transfer occurs only when both `out_valid` and `out_ready` are asserted.

In the current implementation, the selected grant drives `out_valid`, while downstream `out_ready` also participates in the combinational transfer path. This means the current crossbar can complete a transfer in the same simulation cycle when the selected request is valid and the destination is ready. It also creates a combinational ready/valid dependency that should be considered during synthesis and timing analysis.

This is intentional for the current functional POC, but it is not a claim about final implementation timing. If timing closure or interface integration requires it, the path can later be broken with registered/elastic buffering.

The current design is a simple single-request-per-source model rather than a buffered virtual-channel architecture. Because of that, a source that cannot make progress can limit the traffic behind it; this is a head-of-line blocking limitation to keep in mind when evaluating scalability. The POC does not claim to eliminate head-of-line blocking.

## Future evaluation

McKeown-style scheduling/iSLIP is a research and comparison topic. It should be implemented only after the baseline scheduler is understood and verified.

The repository will keep the baseline implementation separate from research notes so algorithm names are not used as a substitute for measured behavior.
