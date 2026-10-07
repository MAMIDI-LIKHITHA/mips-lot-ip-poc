# 06 — Scheduler

## Initial policy

Round-robin arbitration is the first POC policy because it is easy to reason about and provides a deterministic fairness baseline.

## Required invariants

1. An output cannot grant more than one input.
2. An input cannot be granted to more than one output in the same cycle.
3. A granted request must correspond to an asserted request.
4. Reset must remove all grants.
5. Arbitration state must advance only according to a defined grant policy.

## Future evaluation

McKeown-style scheduling/iSLIP is a research and comparison topic. It should be implemented only after the baseline scheduler is understood and verified.

The repository will keep the baseline implementation separate from research notes so algorithm names are not used as a substitute for measured behavior.
