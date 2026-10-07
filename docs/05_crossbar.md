# 05 — 4×4 Crossbar

## Role

The crossbar provides programmable/deterministic routing between four transaction inputs and four transaction outputs.

Core functions:

- destination-based routing
- arbitration under contention
- one-input/one-output grant constraints
- data/control forwarding
- response path
- reset-safe idle behavior
- invalid-destination handling

## Arbitration requirement

A naive independent arbiter per output can grant the same input to multiple outputs in the same cycle. The scheduler must therefore enforce **input exclusivity** in addition to output exclusivity.

## Current POC policy

Round-robin arbitration is used as the initial fairness policy. The implementation is intentionally modular so a different scheduler can be evaluated later.

## Verification targets

- 1→1 connectivity
- all input/output pairs
- two or more inputs targeting one output
- one input requesting multiple outputs
- simultaneous independent traffic
- fairness over repeated contention
- reset
- invalid destination
- response routing
