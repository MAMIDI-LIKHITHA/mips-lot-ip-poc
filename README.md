# MIPS LOT IP POC

A structured RTL/verification project for studying and prototyping an insertable **LAN of Things (LOT) IP block** around a MIPS-based architecture.

## Project objective

The goal is to turn the LOT concept into a simulation-oriented engineering POC:

**MIPS Core → MIPS/Bus Adapter → Interconnect/Transaction Layer → 4×4 Crossbar → Endpoint Adapters → Networking/MAC-facing interfaces**

The repository deliberately separates confirmed requirements from assumptions and implementation status. The final MIPS-facing bus, target technology, LOT role, endpoint mapping, address map, and performance targets remain to be confirmed before treating the architecture as final.

## Status

| Area | Status |
|---|---|
| Project scope | Defined from available POC documents |
| System architecture | Conceptual |
| MIPS bus/interface | To verify |
| 4×4 crossbar | Initial implementation planned |
| Arbitration/scheduler | Initial implementation planned |
| Matter/networking study | Research/planning |
| Silicon Labs DVKs | Evaluation pending |
| Endpoint adapters | Not finalised |
| Full system integration | Not started |
| Verification | Plan defined; implementation in progress |
| Performance targets | To verify |
| IP/license/toolchain review | To verify |

### Status labels

- **Confirmed** — explicitly supported by the current project material.
- **Assumption** — temporary engineering assumption, not a MIPS requirement.
- **To Verify** — requires confirmation or additional evidence.
- **Implemented** — present in RTL/tests in this repository.
- **Verified** — backed by reproducible simulation/test evidence.

## Repository structure

```
rtl/           RTL implementation
tb/            Testbenches and directed tests
verification/  Assertions, scoreboards and coverage
docs/          Architecture and requirements
research/      Crossbar, scheduler, Matter and Silicon Labs notes
sim/           Simulator scripts/configuration
results/       Reproducible simulation/synthesis/performance evidence
```

## Engineering rule

Do not claim that the LOT IP is complete, simulation-proven, or production-ready until the required interface, endpoint, arbitration, reset/error, backpressure, configuration, and system-level tests have actually passed.

## Current architecture boundary

The four network-side technologies under study are:

- Thread
- Wi-Fi
- BLE
- Ethernet

Their exact role and mapping to the four crossbar ports are **not yet final**.

## Next milestone

Build and verify the standalone transaction/interconnect foundation first:

1. Define a generic internal transaction interface.
2. Implement a 4×4 crossbar.
3. Implement arbitration that prevents an input from being granted to multiple outputs in one cycle.
4. Add directed connectivity and contention tests.
5. Only then connect the MIPS adapter and endpoint adapters once their interfaces are confirmed.

## Source basis

The project is based on the available LOT IP POC and next-steps planning documents supplied for this work. Those documents explicitly leave several architectural decisions open; this repository therefore records decisions as they are made rather than presenting assumptions as requirements.
