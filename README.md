# MIPS LOT IP POC

A simulation-oriented RTL POC for studying an insertable **LAN of Things (LOT) IP block** around a MIPS-based architecture.

## What I built

The current candidate path is:

**MIPS-side candidate adapter → LOT transaction router → 4 independent endpoint adapters → LOT response router → MIPS-side candidate adapter**

The transaction router is a 4×4 ready/valid crossbar with per-output round-robin arbitration. Each output can select one requesting input, while an input can win at most one output in a cycle.

The candidate adapter converts a simple memory-mapped CPU request into a protocol-neutral LOT transaction:

**{write, address[31:0], write_data[31:0]}**

The four endpoint adapters provide a small behavioral register map (CONTROL, DATA, STATUS, ID) so the interconnect can be exercised end-to-end without pretending that a final MIPS or network protocol has already been agreed.

## Current status

| Area | Status |
|---|---|
| 4×4 crossbar | **Verified (directed simulation)** |
| Round-robin arbitration | **Verified (directed simulation)** |
| LOT transaction router | **Verified (directed simulation)** |
| LOT response router | **Verified (directed simulation)** |
| Endpoint adapter | **Verified (directed simulation)** |
| Four independent endpoints | **Integrated and verified (directed simulation)** |
| Candidate MIPS MMIO adapter | **Verified (directed simulation)** |
| Concurrent / mixed traffic | **Verified by simulation** |
| Assertions / functional coverage | **Verified by available ModelSim flow** |
| Stress traffic | **500-cycle deterministic stress run passed** |
| Final MIPS bus protocol | **To Verify** |
| Matter / Thread / Wi-Fi / BLE / Ethernet interfaces | **Research / To Verify** |
| Synthesis, timing and resource measurements | **Pending suitable implementation toolchain** |
| Production-ready IP | **Not claimed** |

## Verification evidence

Detailed logs and test descriptions are under `results/`. The headline results are:

- 4×4 connectivity, contention, input exclusivity, backpressure and round-robin fairness — **PASS**
- 16/16 crossbar routes exercised in functional coverage — **100% route coverage**
- Sustained backpressure and held-data stability — **PASS**
- Simultaneous four-output traffic — **PASS**
- Reset and invalid-destination behavior — **PASS**
- Four concurrent sources and mixed concurrent LOT traffic — **PASS**
- Candidate MIPS adapter decode, payload encoding, single-outstanding behavior, error handling and reset — **PASS**
- Candidate MIPS path through the LOT fabric to all four independent endpoints — **PASS**
- The four-endpoint integration run used a **10 ns (100 MHz) simulation clock** and completed at **306 ns**, with **0 simulation errors and 0 warnings**

### Important measurement note

The crossbar is currently combinational from request/grant to output transfer, so a transfer can occur in the same simulation cycle. This is **not** a claim about achievable FPGA clock frequency or implementation timing. Critical-path, Fmax, utilization and resource measurements remain unverified until synthesis/implementation is run.

Testbenches use an explicit `1ns/1ps` simulation timescale. Results should be discussed primarily in **cycles and verified behaviors**, not raw simulator timestamps.

## Architecture boundary

The current MIPS adapter and endpoint protocol are deliberately **candidate/protocol-neutral**. The final MIPS bus, address map, endpoint requirements, target technology and network-facing interfaces are still subject to confirmation.

The four network technologies under study are:

- Thread
- Wi-Fi
- BLE
- Ethernet

No production-readiness or final performance claim is made from the current simulation-only evidence.

## Repository structure

```text
rtl/           RTL implementation
tb/            Testbenches
verification/  Assertions and coverage
docs/          Architecture / requirements
research/      Crossbar, scheduler and networking notes
sim/           Simulator scripts/configuration
results/       Verification evidence
```

## Engineering rule

**Do not claim completion where the interface, implementation result or verification evidence has not actually been established.**

The next concrete step is implementation-oriented checks when an appropriate synthesis/place-and-route toolchain is available, while the final MIPS bus and network-facing interfaces remain open.