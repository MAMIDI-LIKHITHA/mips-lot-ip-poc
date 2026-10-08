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
| MIPS bus/interface | Candidate adapter implemented; final interface To Verify |
| 4×4 crossbar | **Implemented and Verified** |
| Arbitration/scheduler | **Implemented and Verified** |
| Matter/networking study | Research/planning |
| Silicon Labs DVKs | Evaluation pending |
| Endpoint adapters | Behavioral endpoint model only |
| Full system integration | **Candidate path verified** |
| Verification | **Crossbar + end-to-end candidate verification passed** |
| Performance targets | To verify |
| IP/license/toolchain review | To verify |

### Verified 4×4 crossbar result

The standalone 4×4 crossbar testbench `tb/tb_xbar_4x4.sv` was compiled and simulated with ModelSim Intel FPGA Edition.

**Result: PASS**

Verified behaviors:

- 4×4 connectivity/routing
- Multiple inputs contending for the same output
- Input exclusivity
- Output backpressure / ready-valid behavior
- Round-robin arbitration fairness
- No simulation errors

Observed ModelSim result:

- Compilation: **0 errors**
- Simulation: **0 errors**
- Testbench result: **PASS**
- Simulation completion: **85 ps**

Detailed evidence is recorded in `results/xbar_4x4_verification.md`.

### Verified end-to-end candidate result

The candidate system path in `tb/tb_end_to_end_candidate.sv` was compiled and simulated with ModelSim Intel FPGA Edition.

**Result: PASS**

Verified path:

**Candidate CPU request → MIPS MMIO adapter → LOT transaction router → 4×4 request XBAR → behavioral endpoint 2 → response XBAR → LOT response router → MIPS MMIO adapter → CPU response**

Verified behaviors:

- Candidate CPU request accepted
- Address `32'h0002_0040` decoded to endpoint/destination 2
- Request traversed the request XBAR
- Endpoint 2 accepted the transaction
- Deterministic endpoint response generated
- Response returned through the response XBAR
- CPU received expected response `32'h0040_ABCD`
- No endpoint error
- End-to-end test completed successfully

Observed ModelSim result:

- Testbench result: **PASS**
- Simulation completion: **46 ps**
- No simulation errors reported

Detailed evidence is recorded in `results/end_to_end_candidate_verification.md`.

### Status labels

- **Confirmed** — explicitly supported by the current project material.
- **Assumption** — temporary engineering assumption, not a MIPS requirement.
- **To Verify** — requires confirmation or additional evidence.
- **Implemented** — present in RTL/tests in this repository.
- **Verified** — backed by reproducible simulation/test evidence.

## Repository structure

```text
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

With the standalone crossbar now verified, the next milestone is to verify the transaction/interconnect path:

1. Verify the LOT transaction router.
2. Verify the LOT response router.
3. Run the existing end-to-end candidate testbench.
4. Check reset, response routing, backpressure, and error behavior.
5. Only then connect additional MIPS and endpoint functionality once their interfaces are confirmed.

## Source basis

The project is based on the available LOT IP POC and next-steps planning documents supplied for this work. Those documents explicitly leave several architectural decisions open; this repository therefore records decisions as they are made rather than presenting assumptions as requirements.
