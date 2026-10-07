# 17 — Current Milestone

## Implemented in repository

- Generic transaction-level 4×4 crossbar.
- Round-robin output arbitration.
- Input exclusivity in the scheduler.
- Output backpressure awareness.
- Standalone self-checking testbench.
- Icarus and ModelSim command scripts.

## Not yet implemented

- Confirmed MIPS bus adapter.
- MIPS address map.
- Register block.
- Thread/Wi-Fi/BLE/Ethernet endpoint adapters.
- Protocol-specific packet handling.
- System-level MIPS integration.
- McKeown/iSLIP scheduler.
- Synthesis/performance measurements.

## Important verification note

The testbench has been written but its PASS result must only be reported after it is actually executed in a compatible simulator. This repository does not treat source-code inspection as simulation evidence.
