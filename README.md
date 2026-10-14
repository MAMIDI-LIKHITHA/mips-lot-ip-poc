# MIPS LOT IP POC

A simulation-focused RTL proof of concept exploring an insertable **LAN of Things (LOT) IP block** around a MIPS-based architecture.

> **Scope:** This repository demonstrates functional RTL behavior in simulation. It is not a production-ready IP block. FPGA/ASIC synthesis, place-and-route, timing closure, resource measurement, and hardware validation have not yet been performed.

## Visual overview for architecture review

Start here if you prefer block diagrams before reading RTL. **Solid blocks indicate the current simulation POC; dashed blocks or TBD labels indicate proposed or unselected integration.** These are conceptual/architecture drawings, not a cycle-accurate timing specification.

| Diagram | What it answers |
|---|---|
| [1. Current LOT RTL POC architecture](docs/images/lot-poc-current-architecture.svg) | What is currently present in simulation versus future integration? |
| [2. LOT transaction lifecycle](docs/images/lot-transaction-lifecycle.svg) | How does a request travel to an endpoint and how does the response return? |
| [3. Connectivity research and selection map](docs/images/lot-connectivity-research-map.svg) | Which problem is the on-chip interconnect, and which is external networking? |
| [4. Reusable interconnect evaluation scorecard](docs/images/interconnect-ip-evaluation-scorecard.svg) | What evidence is needed before choosing or reusing an interconnect? |
| [5. Silicon Labs / Matter integration boundary](docs/images/lot-silicon-labs-matter-boundary.svg) | Where would the host interface end and the external connectivity device/network begin? |

### Decision status at a glance

- **Implemented and simulated:** custom LOT request router, 4×4 ready/valid crossbar, behavioral endpoints, response router, and a candidate single-outstanding MMIO path in the testbench.
- **Not yet selected:** actual MIPS core/native bus, reusable production interconnect, Silicon Labs part and SoC/NCP mode, host interface, and network stack ownership.
- **Do not conflate:** Matter/Thread/Wi-Fi/BLE are not substitutes for an on-chip bus crossbar. An NCP requires a defined host interface and matching controller/driver.
- **Current recommendation:** inspect the real MIPS subsystem and its existing peripherals first; compare only interface-compatible IP, and reuse a compatible memory-mapped SPI controller if one is already available for a selected NCP design. This is a working hypothesis, not an approved design.

See the [reviewed LOT Connectivity Research Report 01](docs/research/lot-connectivity-report-01-reviewed.md) for the five open questions, source-linked candidate shortlist, review findings, and decision gates. See the [updated stakeholder research report](docs/research/lot-connectivity-report-01-updated.md), the [LOT research brief](docs/lot-research-brief.md), [source-linked interconnect and connectivity IP shortlist](docs/research/existing-interconnect-and-connectivity-ip.md), [Silicon Labs host-interface notes](docs/silicon-labs-host-interface-research.md), [interconnect options](docs/interconnect-options.md), [MIPS bus compatibility matrix](docs/mips-bus-compatibility-matrix.md), [signal-level interface map](docs/lot-signal-level-interface-map.md), and [end-to-end integration trace](docs/lot-end-to-end-integration-trace.md) for details, evidence, and unresolved questions. Use the [stakeholder integration input checklist](docs/stakeholder-integration-input-checklist.md) to collect the target MIPS core/bus, peripheral inventory, connectivity mode, and implementation constraints before choosing IP or changing RTL. See the [next verification plan](docs/next-verification-plan.md) for prioritized tests covering stalls, reset during transactions, response-source association, invalid IDs, and back-to-back traffic.

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

**Latest user-reported full ModelSim regression (12 October 2026):** ModelSim Intel FPGA Edition 2021.1 — **11 passed, 0 failed**. The user ran `do sim/modelsim/run.do` locally and confirmed `REGRESSION RESULT: PASS`; all 11 saved per-test logs contained `TB RESULT: PASS`. This is local simulation evidence, not a GitHub Actions result. The earlier 10-test result below is historical.

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
| Candidate MIPS MMIO adapter unit test (Icarus Verilog, GitHub Actions) | **PASS** — all six sections; `TB RESULT: PASS` ([workflow run](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38209876697)) |
| End-to-end candidate CPU/LOT/endpoint path | **PASS in the latest user-reported 11-test ModelSim regression** |
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

A successful run of the current script should end with output similar to:

```text
REGRESSION SUMMARY: 11 passed, 0 failed
REGRESSION RESULT: PASS
Per-test transcripts: sim/modelsim/regression_<testbench>.log
```

The regression script compiles the RTL and testbenches, runs eleven testbenches, checks each test-specific transcript for its explicit pass marker, and prints the final summary. On 12 October 2026, the user reported running the current full script in ModelSim and confirmed 11 passed, 0 failed; the saved per-test logs were checked for PASS markers. The GitHub Actions Icarus job validates only the candidate adapter unit test; it is not a substitute for the full ModelSim run. Per-test transcripts are generated locally and do not need to be committed. Warning counts can vary with simulator settings; investigate new warnings and any compile or simulation errors rather than relying on the summary alone.

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

1. **Identify the actual MIPS subsystem and bus:** record core/version, native protocol, widths, request/response semantics, clock/reset, address map, and available peripherals.
2. **Freeze the LOT contract:** specify address decoding, request acceptance, response association, read/write semantics, byte enables, error behavior, reset cancellation, and outstanding-transaction policy.
3. **Compare existing interconnect IP against requirements:** document supported interface variants, features, upstream verification, maintenance, integration dependencies, and the exact license/commercial terms. Do not select a candidate until the host interface is known.
4. **Check the SPI path:** determine whether the target subsystem already contains a compatible memory-mapped SPI controller and driver before considering a custom LOT-to-serial bridge.
5. **Confirm external connectivity:** select the Silicon Labs part and SoC/NCP mode, host protocol, exact SDK/board configuration, and ownership of the Matter/Thread/network stack.
6. **Close integration and verification gaps:** especially unmapped-destination response behavior and dynamic response-source association if multiple initiators are intended.
7. **Measure implementation results:** after selecting a target device and implementation flow, run synthesis and implementation to obtain timing and resource data.
8. **Validate on hardware:** make hardware-operation claims only after implementation and board-level testing.

## Engineering boundary

The current evidence supports **functional behavior in simulation only**. It does not establish a finalized CPU interface, network interoperability, synthesis quality, FPGA Fmax, post-implementation latency, resource utilization, power, or production readiness.

The research documents are evidence-gathering artifacts, not approval of a final architecture. Record vendor answers and the eventual decision with dates and supporting sources before integrating third-party IP.


## Additional LOT research package

The latest research additions are summarized here; all choices remain conditional until the target MIPS bus, connectivity mode, and licensing are confirmed.

- [Interconnect options and conditional candidate comparison](docs/interconnect-options.md) — merged with the existing interconnect options note to avoid duplicate documents.
- [LOT Connectivity Layer — Research Report 01 (Markdown summary)](docs/research/LOT-Research-Report-01.md) — Silicon Labs NCP/RCP/SoC modes, Matter border-router scope, MIPS bus questions, and next steps.
- [NIC-400 decision memo (Markdown)](docs/research/NIC-400-decision-memo.md) — conditional candidate assessment and open checks.
- [LOT research templates](docs/research/LOT-Research-Templates.md) — source-linked brief and comparison templates.

These research notes are preliminary and do not supersede the engineering boundary above: the current RTL is simulation evidence only, with no synthesis, timing closure, or hardware validation claimed.


## Research package and diagrams

- [Candidate reference architecture (SVG)](docs/images/candidate-reference-architecture.svg)
- [NIC-400 in the LOT architecture (SVG)](docs/images/nic400-in-the-lot-picture.svg)
- [Silicon Labs NCP / RCP / SoC operating modes (SVG)](docs/images/silicon-labs-operating-modes.svg)
- [NIC-400 decision memo — Markdown summary](docs/research/NIC-400-decision-memo.md)
- [LOT Connectivity Research Report 01 — Markdown summary](docs/research/LOT-Research-Report-01.md)
- [LOT research templates](docs/research/LOT-Research-Templates.md)
- [Interconnect options and LOT-specific decision matrix](docs/interconnect-options.md)

The SVG diagrams are repository-native redraws based on the supplied asset names and the project research context. The original PNG and PDF files from `repo-additions.zip` have not been committed as binary assets; the two PDFs are represented by Markdown summaries, not byte-for-byte PDF copies. NIC-400 remains a conditional candidate pending interface, license, and tool-access checks.
