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

The baseline crossbar uses ready/valid handshaking. An output transfer occurs only when both `out_valid` and `out_ready` are asserted. Therefore, downstream backpressure can prevent a selected transfer from completing.

The current design is a simple single-request-per-source model rather than a buffered virtual-channel architecture. Because of that, a source that cannot make progress can limit the traffic behind it; this is a head-of-line blocking limitation to keep in mind when evaluating scalability. The POC does not claim to eliminate head-of-line blocking.

## Future evaluation

McKeown-style scheduling/iSLIP is a research and comparison topic. It should be implemented only after the baseline scheduler is understood and verified.

The repository will keep the baseline implementation separate from research notes so algorithm names are not used as a substitute for measured behavior.
