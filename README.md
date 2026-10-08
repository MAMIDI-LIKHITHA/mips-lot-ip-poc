# MIPS LOT IP POC

A simulation-focused RTL POC for studying an insertable **LAN of Things (LOT) IP block** around a MIPS-based architecture.

## What I built

**MIPS-side candidate adapter → LOT transaction router → 4 independent endpoints → LOT response router → MIPS-side candidate adapter**

The request fabric is a **4×4 ready/valid crossbar** with per-output round-robin arbitration. The candidate CPU adapter converts a simple memory-mapped request into a protocol-neutral LOT transaction:

**{write, address[31:0], write_data[31:0]}**

Behavioral endpoint adapters provide CONTROL, DATA, STATUS and ID registers so the complete path can be exercised without claiming that the final MIPS or network protocol is already defined.

## Current status

| Area | Status |
|---|---|
| 4×4 crossbar + round-robin arbitration | **Verified (directed simulation)** |
| LOT transaction / response routers | **Verified (directed simulation)** |
| Endpoint adapter + four-endpoint fabric | **Verified (directed simulation)** |
| Candidate MIPS MMIO adapter | **Verified (directed simulation)** |
| Concurrent / mixed traffic | **Verified by simulation** |
| Assertions / functional coverage | **Verified by available ModelSim flow** |
| Stress traffic | **500-cycle deterministic stress run passed** |
| Final MIPS bus protocol | **To Verify** |
| Thread / Wi-Fi / BLE / Ethernet interfaces | **Research / To Verify** |
| Synthesis, timing and resource measurements | **Pending suitable implementation toolchain** |
| Production-ready IP | **Not claimed** |

## Verification evidence

Detailed logs are in `results/`.

- **16/16 crossbar routes** exercised — 100% route coverage
- Connectivity, contention, input exclusivity, backpressure and round-robin fairness — **PASS**
- Reset and invalid-destination behavior — **PASS**
- Four-output simultaneous traffic — **PASS**
- Sustained backpressure and held-data stability — **PASS**
- Four concurrent sources and mixed LOT traffic — **PASS**
- Candidate MIPS request/response path through all four endpoints — **PASS**
- End-to-end register access, error propagation and CPU response backpressure — **PASS**

Testbenches use an explicit `1ns/1ps` simulation timescale. Raw simulator timestamps are not used as FPGA timing claims.

## Important boundary

This is a **functional simulation POC**, not a finished implementation. The final MIPS bus, address-map requirements, endpoint interfaces and network-facing protocol mapping are still open.

The current crossbar is combinational from request/grant to output transfer, so same-cycle transfers are possible in simulation. This does **not** establish achievable FPGA Fmax, latency after implementation, area or resource utilization.

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

**Engineering rule:** do not claim completion where the interface, implementation result or verification evidence has not actually been established.
