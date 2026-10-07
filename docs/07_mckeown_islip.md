# 07 — McKeown / iSLIP Study

## Purpose

Study input/output queued switching and iterative scheduling approaches relevant to the LOT interconnect.

## Questions

- What scheduling problem is the algorithm solving?
- How does it handle input/output contention?
- What state is maintained?
- What is the arbitration latency?
- What throughput/fairness trade-offs exist?
- Can the algorithm fit the intended FPGA/silicon target?
- What verification complexity does it introduce?

## Current status

Research item. No final scheduler selection is claimed.

The baseline RTL starts with round-robin arbitration so there is a concrete reference point for later comparison.
