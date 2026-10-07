# 12 — Verification Plan

## Level 1 — Unit

- scheduler
- crossbar
- destination decoder
- register block
- endpoint adapters

## Level 2 — Subsystem

- adapter + interconnect + crossbar
- response routing
- backpressure
- invalid destinations

## Level 3 — System

- confirmed MIPS interface
- endpoint adapters
- configuration
- representative traffic

## Required directed scenarios

1. reset/idle
2. each input to each output
3. simultaneous non-conflicting traffic
4. many inputs targeting one output
5. one input presenting conflicting requests
6. repeated contention/fairness
7. read transaction
8. write transaction
9. response routing
10. backpressure
11. invalid destination
12. configuration access

## Evidence

Every claimed verification result should have:

- test name
- simulator/tool version
- command/script
- expected result
- observed result
- reproducible log or waveform reference
