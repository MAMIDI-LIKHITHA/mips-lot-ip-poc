# 17 — Current Milestone

## Implemented in repository

- Generic transaction-level 4×4 request crossbar.
- Protocol-neutral internal LOT request transaction boundary.
- Round-robin output arbitration.
- Input exclusivity in the scheduler.
- Output backpressure awareness.
- Protocol-neutral 4×4 response router.
- Candidate single-outstanding MIPS MMIO adapter with request and response handshakes.
- Behavioral endpoint harness for an end-to-end candidate transaction.
- Self-checking request testbench with connectivity, contention, backpressure and round-robin fairness checks.
- Self-checking response testbench with routing, error propagation, contention and backpressure checks.
- End-to-end testbench covering candidate CPU request -> request XBAR -> endpoint -> response XBAR -> candidate CPU response.
- Icarus and ModelSim command scripts covering all three testbenches.

## Not yet implemented

- Confirmed MIPS bus adapter.
- MIPS address map.
- Register block.
- Thread/Wi-Fi/BLE/Ethernet endpoint adapters.
- Protocol-specific packet handling.
- Final system-level MIPS integration.
- McKeown/iSLIP scheduler.
- Synthesis/performance measurements.

## Important verification note

The testbenches have been written but their PASS results must only be reported
after they are actually executed in a compatible simulator. This repository
does not treat source-code inspection as simulation evidence.

## Current milestone

The protocol-neutral candidate path is now represented end to end in simulation
structure. The next engineering work should focus on replacing assumptions one
at a time: first confirm the actual MIPS bus, then define the real transaction
and response mapping, then connect the endpoint/protocol boundary.
