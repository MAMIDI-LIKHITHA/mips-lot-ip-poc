# MIPS LOT IP POC

A simulation-focused RTL proof of concept for exploring an insertable **LAN of Things (LOT) IP block** around a MIPS-based architecture. The repository currently demonstrates a candidate CPU-side memory-mapped interface, transaction routing, a 4×4 crossbar, behavioral endpoints, and response routing in functional simulation.

> **Scope:** this is a functional RTL simulation POC. It is not yet a production-ready IP block, and no FPGA synthesis, place-and-route, timing closure, or hardware validation is claimed.

## Architecture at a glance

```text
Candidate MIPS MMIO adapter
          |
          v
   LOT transaction router
          |
          v
   4×4 ready/valid crossbar
   (round-robin arbitration)
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

The candidate CPU adapter converts a simple memory-mapped request into a protocol-neutral LOT transaction containing write direction, a 32-bit address, and 32-bit write data. Behavioral endpoint adapters expose CONTROL, DATA, STATUS, and ID registers so the request/response path can be tested end to end without assuming that the final MIPS bus or network protocol has been selected.

The request fabric uses ready/valid handshakes and per-output round-robin arbitration. The crossbar is currently combinational, so zero-cycle transfers can occur in simulation; this is not an FPGA timing or achievable-frequency claim.

## Current verification status

**Latest local run on merged `main`: ModelSim Intel FPGA Edition 2021.1 — 10 passed, 0 failed.**

| Verification area | Result |
|---|---|
| Regression harness | **PASS** — requires an explicit `TB RESULT: PASS` marker from every testbench |
| Compilation | **0 errors, 14 warnings** in the reported run |
| Crossbar functional route coverage | **16/16 routes (100%)** |
| Crossbar connectivity, contention, input exclusivity, fairness | **PASS** |
| Backpressure stability and handshake recovery | **PASS** |
| Multi-output routing and partial backpressure | **PASS** |
| Invalid destination and reset behavior | **PASS** |
| LOT transaction router and response router | **PASS** |
| End-to-end candidate CPU/LOT/endpoint path | **PASS** |
| Stress test | **500 cycles; 1,175 accepted and 1,175 delivered transfers** |
| Synthesis, timing closure, area/resource measurements | **Not yet performed** |
| FPGA or ASIC hardware validation | **Not yet performed** |
| Final MIPS bus and network-facing protocol mapping | **Open / to be defined** |

The stress run also exercised 407 contention cycles, 200 output backpressure stalls, and 32 cycles with four simultaneous outputs. The measured zero-cycle crossbar latency is a property of the current combinational simulation model, not a post-synthesis timing result.

### Running the ModelSim regression

From the repository root in ModelSim Intel FPGA Edition 2021.1, run:

```tcl
do sim/modelsim/run.do
```

The regression script compiles the RTL and testbenches, runs all ten testbenches, checks each test-specific transcript for the explicit `TB RESULT: PASS` marker, and prints a final summary. A successful run ends with output equivalent to:

```text
REGRESSION SUMMARY: 10 passed, 0 failed
REGRESSION RESULT: PASS
Per-test transcripts: sim/modelsim/regression_<testbench>.log
```

The per-test transcripts are generated locally and are not required to be committed. Warning counts can depend on simulator settings; investigate any compilation or simulation errors rather than treating a PASS summary as a substitute for reviewing new warnings.

## Repository structure

```text
rtl/           RTL implementation
tb/            SystemVerilog testbenches
verification/  Assertions and functional coverage
sim/           Simulator scripts and configuration
docs/          Architecture, requirements, and research notes
results/       Checked-in verification evidence, where available
```

## Open engineering questions and next steps

1. **Freeze interface requirements:** select the target MIPS core/bus protocol, define address decoding and error behavior, and document transaction semantics.
2. **Specify endpoint contracts:** define the register map, reset values, access permissions, and behavior for unmapped addresses.
3. **Clarify network integration:** evaluate how LOT transactions map to intended Thread, Wi-Fi, BLE, or Ethernet-connected endpoints; do not treat these technologies as implemented by this POC.
4. **Expand verification:** add requirements-driven corner cases and tool-compatible assertion checking; document any simulator limitations around concurrent SystemVerilog assertions.
5. **Measure implementation results:** once the target device and implementation flow are selected, run synthesis and implementation to obtain resource use and timing data.
6. **Validate on hardware:** only after implementation and board-level tests should hardware-operation claims be made.

## Engineering boundary

The current evidence establishes **functional behavior in simulation only**. It does not establish a final CPU interface, network interoperability, synthesis quality, FPGA Fmax, post-implementation latency, resource utilization, power, or production readiness. Keep these limitations explicit in reviews and project updates.
