# MIPS LOT IP POC

A simulation-focused RTL proof of concept exploring an insertable **LAN of Things (LOT) IP block** around a MIPS-based architecture.

> **Scope:** This repository demonstrates functional RTL behavior in simulation. It is not a production-ready IP block. FPGA/ASIC synthesis, place-and-route, timing closure, resource measurement, and hardware validation have not yet been performed.

## Architecture

```text
Candidate MIPS MMIO adapter
          |
          v
   LOT transaction router
          |
          v
   4×4 ready/valid crossbar
   (per-output round-robin arbitration)
     |      |      |      |
     v      v      v      v
 CONTROL   DATA   STATUS   ID
 endpoint endpoint endpoint endpoint
     |      |      |      |
     +------+---+--+------+
                |
                v
      LOT response router
                |
                v
 Candidate MIPS MMIO adapter
```

The candidate CPU-side adapter translates a simple memory-mapped request into a protocol-neutral LOT transaction containing a write flag, a 32-bit address, and 32-bit write data. Behavioral endpoints expose CONTROL, DATA, STATUS, and ID registers, allowing the request and response path to be exercised end to end without assuming that the final MIPS bus or network protocol has been selected.

The request fabric uses ready/valid handshakes. Its crossbar is currently combinational, so transfers can occur in the same simulation cycle. This is a property of the current model—not a claim about achievable FPGA frequency or implemented latency.

## Verification status

**Latest reported local run:** ModelSim Intel FPGA Edition 2021.1 on `main` — **10 passed, 0 failed**.

| Verification area | Result |
|---|---|
| Regression harness | **PASS** — checks for an explicit `TB RESULT: PASS` marker from every testbench |
| Compilation | **0 errors, 14 warnings** in the reported run |
| Crossbar route coverage | **16/16 routes (100%)** |
| Connectivity, contention, input exclusivity, round-robin fairness | **PASS** |
| Backpressure stability and handshake recovery | **PASS** |
| Multi-output routing and partial backpressure | **PASS** |
| Reset and invalid-destination behavior | **PASS** |
| LOT transaction and response routers | **PASS** |
| End-to-end candidate CPU/LOT/endpoint path | **PASS** |
| Deterministic stress test | **500 cycles; 1,175 accepted and 1,175 delivered transfers** |
| Synthesis, timing closure, area/resource measurements | **Not performed** |
| FPGA/ASIC hardware validation | **Not performed** |
| Final MIPS bus and network-facing protocol mapping | **Open / to be defined** |

The stress run also exercised 407 contention cycles, 200 output backpressure stalls, and 32 cycles with four simultaneous outputs. These are simulation counters, not post-implementation performance measurements.

## Run the ModelSim regression

From the repository root in ModelSim Intel FPGA Edition 2021.1, run:

```tcl
do sim/modelsim/run.do
```

A successful run ends with output similar to:

```text
REGRESSION SUMMARY: 10 passed, 0 failed
REGRESSION RESULT: PASS
Per-test transcripts: sim/modelsim/regression_<testbench>.log
```

The regression script compiles the RTL and testbenches, runs all ten testbenches, checks each test-specific transcript for its explicit pass marker, and prints the final summary. Per-test transcripts are generated locally and do not need to be committed. Warning counts can vary with simulator settings; investigate new warnings and any compile or simulation errors rather than relying on the summary alone.

## Repository layout

```text
rtl/           RTL implementation
tb/            SystemVerilog testbenches
verification/  Assertions and functional coverage
sim/           Simulator scripts and configuration
docs/          Architecture, requirements, and research notes
results/       Checked-in verification evidence, where available
```

## Open engineering questions

1. **Freeze the CPU interface:** choose the target MIPS core and bus protocol; define address decoding, transaction semantics, and error behavior.
2. **Specify endpoint contracts:** document the register map, reset values, access permissions, and unmapped-address behavior.
3. **Define network integration:** determine how LOT transactions should map to Thread, Wi-Fi, BLE, or Ethernet-connected endpoints. These technologies are not implemented by this POC.
4. **Expand verification:** add requirements-driven corner cases and tool-compatible assertion checks; document simulator limitations for concurrent SystemVerilog assertions.
5. **Measure implementation results:** after selecting a target device and implementation flow, run synthesis and implementation to obtain timing and resource data.
6. **Validate on hardware:** make hardware-operation claims only after implementation and board-level testing.

## Engineering boundary

The current evidence supports **functional behavior in simulation only**. It does not establish a finalized CPU interface, network interoperability, synthesis quality, FPGA Fmax, post-implementation latency, resource utilization, power, or production readiness.
