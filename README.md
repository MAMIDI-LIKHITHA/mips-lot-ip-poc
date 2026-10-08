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
| LOT transaction router | **Implemented and Verified** |
| LOT response router | **Implemented and Verified** |
| Matter/networking study | Research/planning |
| Silicon Labs DVKs | Evaluation pending |
| Endpoint adapters | **Behavioral endpoint adapter implemented and verified** |
| Full system integration | **Candidate path + four independent endpoint register integration verified** |
| Verification | **Crossbar + transaction router + response router + endpoint-integrated end-to-end path + reset + invalid-destination + sustained backpressure + multi-output + functional coverage + stress/latency verification passed** |
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

### Verified LOT transaction-router result

The standalone LOT transaction-router testbench `tb/tb_lot_txn_router.sv` was compiled and simulated with ModelSim Intel FPGA Edition.

**Result: PASS**

Verified behaviors:

- Source-to-destination routing
- Payload/data integrity
- Destination backpressure
- Multiple-source contention
- Input exclusivity under contention
- Round-robin arbitration progression
- Ready/valid transfer behavior

Observed ModelSim result:

- Compilation: **0 errors**
- Simulation: **0 errors**
- Testbench result: **PASS**
- Simulation completion: **76 ps**

Detailed evidence is recorded in `results/lot_txn_router_verification.md`.

### Verified LOT response-router result

The standalone LOT response-router testbench `tb/tb_lot_rsp_router.sv` was simulated with ModelSim Intel FPGA Edition.

**Result: PASS**

Verified behaviors:

- Response routing
- Response payload transfer
- Error propagation
- Multiple-source contention
- Backpressure behavior
- Ready/valid response transfer

Observed ModelSim result:

- Simulation: **0 errors, 0 warnings**
- Testbench result: **PASS**
- Simulation completion: **19 ps**

Detailed evidence is recorded in `results/lot_rsp_router_verification.md`.

### Verified end-to-end candidate result

The candidate system path in `tb/tb_end_to_end_candidate.sv` was compiled and simulated with ModelSim Intel FPGA Edition.

**Result: PASS**

Verified path:

**Candidate CPU request → MIPS MMIO adapter → LOT transaction router → 4×4 request XBAR → LOT endpoint register adapter → response XBAR → LOT response router → MIPS MMIO adapter → CPU response**

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
- Endpoint 2 CONTROL/DATA writes and readbacks verified
- STATUS and ID register reads verified
- Invalid local-register error propagated back to the CPU response
- CPU response backpressure and response-data stability verified

Observed ModelSim result:

- Testbench result: **PASS**
- Simulation completion: **46 ps**
- No simulation errors reported

Detailed evidence is recorded in `results/end_to_end_candidate_verification.md`.

### Verified end-to-end LOT endpoint integration

The endpoint-integrated `tb/tb_end_to_end_candidate.sv` was compiled and simulated with ModelSim Intel FPGA Edition 2021.1.

**Result: PASS**

Verified the complete protocol-neutral path through the real `lot_endpoint_adapter`, including CONTROL/DATA register writes and readbacks, STATUS/ID reads, invalid-register error propagation, and CPU response backpressure stability.

Observed ModelSim result:

- Compilation: **0 errors**
- Simulation: **0 errors, 0 warnings**
- Testbench result: **PASS**
- Simulation completion: **296 ps**

Detailed evidence is recorded in `results/end_to_end_lot_endpoint_integration_verification.md`.

### Verified reset behavior

The crossbar reset testbench `tb/tb_xbar_reset.sv` was compiled and simulated with ModelSim Intel FPGA Edition.

**Result: PASS**

Verified behaviors:

- Reset quiescence
- Traffic suppression while reset is asserted
- Post-reset traffic recovery
- Repeated reset behavior

Observed ModelSim result:

- Compilation: **0 errors**
- Simulation: **0 errors**
- Testbench result: **PASS**
- Simulation completion: **26 ps**

Detailed evidence is recorded in `results/xbar_reset_verification.md`.

### Verification matrix

| Verification target | Result | Evidence |
|---|---|---|
| 4×4 request crossbar | **PASS** | `results/xbar_4x4_verification.md` |
| LOT transaction router | **PASS** | `results/lot_txn_router_verification.md` |
| LOT response router | **PASS** | `results/lot_rsp_router_verification.md` |
| End-to-end candidate path | **PASS** | `results/end_to_end_candidate_verification.md` |
| End-to-end LOT endpoint integration | **PASS — register access, error propagation, response backpressure** | `results/end_to_end_lot_endpoint_integration_verification.md` |
| Crossbar reset behavior | **PASS** | `results/xbar_reset_verification.md` |
| Invalid destination handling | **PASS** | `tb/tb_xbar_invalid_dst.sv` |
| Sustained backpressure / ready-valid stability | **PASS** | `results/xbar_backpressure_verification.md` |\n| Simultaneous multi-output traffic | **PASS** | `results/xbar_multi_output_verification.md` |
| Functional coverage | **PASS — 16/16 routes, contention, multi-output, backpressure, reset** | `results/xbar_functional_coverage.md` |

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

The core candidate interconnect path, crossbar reset behavior, functional coverage, and deterministic stress/latency verification are now verified. The next milestone is robustness and implementation-oriented verification:

1. Error propagation and invalid/corner-case transactions. **Invalid destination suppression verified.**
2. Sustained backpressure and ready/valid stability. **Verified.**
3. Simultaneous multi-output traffic and additional contention cases. **Multi-output traffic verified.**
4. Functional coverage. **16/16 routes plus contention, multi-output, backpressure and reset verified.**
5. Stress and latency verification. **500-cycle stress test passed with 1002/1002 transfer accounting, contention, backpressure, four-output traffic and 0-cycle combinational latency.**
6. Timing/synthesis checks and implementation-oriented measurements when a suitable implementation toolchain is available.
7. Then connect additional MIPS and endpoint functionality once their interfaces are confirmed.

## Source basis

The project is based on the available LOT IP POC and next-steps planning documents supplied for this work. Those documents explicitly leave several architectural decisions open; this repository therefore records decisions as they are made rather than presenting assumptions as requirements.
