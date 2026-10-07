# 17 — Current Milestone

## Implemented in repository

- Generic transaction-level 4×4 request crossbar.
- Protocol-neutral internal LOT request transaction boundary.
- Round-robin output arbitration.
- Input exclusivity in the scheduler.
- Output backpressure awareness.
- Protocol-neutral 4×4 response router.
- Candidate single-outstanding MIPS MMIO adapter with request and response handshakes.
- Self-checking request testbench with connectivity, contention, backpressure and round-robin fairness checks.
- Self-checking response testbench with routing, error propagation, contention and backpressure checks.
- Icarus and ModelSim command scripts covering the request and response testbenches.

## Not yet implemented

- Confirmed MIPS bus adapter.
- MIPS address map.
- Register block.
- Thread/Wi-Fi/BLE/Ethernet endpoint adapters.
- Protocol-specific packet handling.
- End-to-end MIPS-to-endpoint system integration.
- McKeown/iSLIP scheduler.
- Synthesis/performance measurements.

## Important verification note

The testbenches have been written but their PASS results must only be reported
after they are actually executed in a compatible simulator. This repository
does not treat source-code inspection as simulation evidence.

## Next engineering step

Connect the candidate MIPS request path and response path through a small
behavioral endpoint test harness. That will provide an end-to-end protocol-
neutral transaction demonstration before committing to the final MIPS bus or
network endpoint protocols.
