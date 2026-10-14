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

See the [MIPS core target evaluation 01](docs/mips-core-target-evaluation-01.md) for the provisional OpenMIPS reference-core recommendation, integration risks, and acceptance criteria. The [OpenMIPS data-memory RTL inspection](docs/openmips-data-memory-rtl-inspection.md) records the signals and cache-line versus word-transfer distinction. The [cache-attribute/MMIO mapping review](docs/openmips-cache-attribute-mmio-mapping.md) documents how the TLB-derived cache attribute reaches the data-cache interface. The new [OpenMIPS CPU-to-LOT test map and transaction contract](docs/openmips-cpu-to-lot-test-map-and-contract.md) defines the proposed first integration test without freezing an unverified physical address map. The [OpenMIPS memory-port handshake semantics review](docs/openmips-memory-port-handshake-semantics.md) records the cache-side word/line signals, buffered-write implications, and timing questions that must be resolved before adapter RTL. A preliminary [OpenMIPS LOT access classifier](docs/openmips-lot-access-classifier.md) and focused unit test now cover routing policy; this classifier is not yet the native memory-port bridge. The [candidate OpenMIPS LOT memory-port bridge](docs/openmips-lot-memory-bridge.md) adds a RAM/LOT mux and a focused unit testbench; the expanded Icarus regression now passes, including reset during an accepted outstanding request. The actual-cache wrapper and full-core program-level simulation now exercise the qualification sidebands; synthesis, timing, and hardware validation remain pending. See the [OpenMIPS-to-LOT integration wiring plan](docs/openmips-to-lot-integration-wiring-plan.md) for required signal mapping and remaining acceptance criteria. The production MIPS core remains unapproved until the target requirements, license, and toolchain are confirmed. See the [reviewed LOT Connectivity Research Report 01](docs/research/lot-connectivity-report-01-reviewed.md) for the five open questions, source-linked candidate shortlist, review findings, and decision gates. See the [updated stakeholder research report](docs/research/lot-connectivity-report-01-updated.md), the [LOT research brief](docs/lot-research-brief.md), [source-linked interconnect and connectivity IP shortlist](docs/research/existing-interconnect-and-connectivity-ip.md), [Silicon Labs host-interface notes](docs/silicon-labs-host-interface-research.md), [interconnect options](docs/interconnect-options.md), [MIPS bus compatibility matrix](docs/mips-bus-compatibility-matrix.md), [signal-level interface map](docs/lot-signal-level-interface-map.md), and [end-to-end integration trace](docs/lot-end-to-end-integration-trace.md) for details, evidence, and unresolved questions. The [proposed LOT Internal Interface Contract v0.1](docs/lot-internal-interface-contract-v0.1.md) makes the current 65-bit request, response routing, handshake, reset, and single-outstanding assumptions explicit without pretending a target MIPS bus has been selected. Use the [stakeholder integration input checklist](docs/stakeholder-integration-input-checklist.md) to collect the target MIPS core/bus, peripheral inventory, connectivity mode, and implementation constraints before choosing IP or changing RTL. See the [next verification plan](docs/next-verification-plan.md) for prioritized tests covering stalls, reset during transactions, response-source association, invalid IDs, and back-to-back traffic. The [contract verification matrix](docs/contract-verification-matrix.md) maps the proposed interface contract to existing testbenches and records remaining gaps.

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

**Latest confirmed full ModelSim regression (14 October 2026):** ModelSim Intel FPGA Edition 2021.1 — **12 passed, 0 failed**. The user's run output showed **0 compilation errors and 14 warnings**, and all twelve testbenches emitted `TB RESULT: PASS`. This is local simulation evidence, not a GitHub Actions result.

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
| OpenMIPS LOT access classifier unit test | **PASS** — Icarus Verilog smoke test ([workflow run](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38545094138)) |
| OpenMIPS LOT memory bridge unit test | **PASS** — expanded Icarus regression covers backpressure, error, fault reset, unmapped offsets, STATUS/ID routing, and reset during an accepted outstanding request ([latest run](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38546466798)). Unit-level only, not full-core integration |
| End-to-end candidate CPU/LOT/endpoint path | **PASS in the confirmed 12-test ModelSim regression (14 October 2026)** |
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
REGRESSION SUMMARY: 12 passed, 0 failed
REGRESSION RESULT: PASS
Per-test transcripts: sim/modelsim/regression_<testbench>.log
```

The regression script compiles the RTL and testbenches, lists twelve testbenches, checks each test-specific transcript for its explicit pass marker, and prints the final summary. On 14 October 2026, the user ran the current script in ModelSim Intel FPGA Edition 2021.1 and reported `REGRESSION SUMMARY: 12 passed, 0 failed` and `REGRESSION RESULT: PASS`. The run reported 0 compilation errors and 14 warnings. The GitHub Actions Icarus job validates only the candidate adapter unit test; it is not a substitute for the full ModelSim run. Per-test transcripts are generated locally and do not need to be committed. Investigate warnings rather than assuming they are harmless, and continue to distinguish functional simulation from synthesis, timing closure, and hardware validation.

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


## OpenMIPS integration verification

- [OpenMIPS memory-port cycle-level verification matrix](docs/openmips-memory-port-cycle-level-verification-matrix.md) — planned native-cache timing scenarios, waveform evidence requirements, and gates before full CPU-to-LOT wiring.
- [OpenMIPS-to-LOT integration wiring plan](docs/openmips-to-lot-integration-wiring-plan.md) — wrapper boundary, address mapping, reset contract options, and end-to-end acceptance criteria.
- [OpenMIPS memory-port handshake semantics](docs/openmips-memory-port-handshake-semantics.md) — source-inspection findings and unresolved native timing questions.

These documents are verification plans and source-inspection notes. They do not claim native OpenMIPS cycle-level testing or full CPU-to-LOT integration.

- [OpenMIPS native memory-port cycle review](docs/openmips-native-memory-port-cycle-review.md) — source-level observations about cache-FSM request assertions, write-buffer indicators, `Ready_M`, and line-fill sequencing; upstream `master` is not yet pinned to a reviewed commit.

- [OpenMIPS source pin and native cache-port smoke test](docs/openmips-source-pin-and-native-cache-smoke.md) — pins upstream OpenMIPS to `d606b35e9d5260aef20de2a58660c8303a681e9c` and documents the CI harness that instantiates the actual `DataCache_2KB` RTL.

- [Native OpenMIPS address guard](docs/openmips-native-address-guard.md) — isolated 34-bit-to-30-bit native word-address guard with dedicated passing Icarus CI ([run 38552329183](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38552329183)); not yet connected to the bridge.

### Native cache qualification adapter progress

- The pinned OpenMIPS cache smoke test now applies `scripts/apply-openmips-cache-qualification.py` to preserve the active cache attribute semantics and capture physical-address validity with queued word-write entries. The actual-cache regression passed: [CI run 38554550754](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38554550754).
- `rtl/mips_if/openmips_native_cache_adapter.sv` combines the active uncacheable-read qualification and FIFO-aligned queued-write validity with 34-bit address guarding and separates word commands from cache-line traffic.
- Full cache-to-bridge CPU-to-LOT operation is not yet verified; adapter standalone CI and an actual-cache + bridge + delayed endpoint end-to-end regression are the remaining gates.


### First actual-cache-to-LOT end-to-end proof

- Added `openmips_native_cache_lot_wrapper.sv` to wire the pinned native cache adapter into the candidate bridge.
- Added `tb/tb_openmips_native_cache_lot.sv` with the real pinned `DataCache_2KB` and a delayed LOT endpoint.
- Verified one uncacheable read at `0x1F00_0000`, one full-word store at `0x1F00_0004`, expected destination/payload, response data return, delayed write-buffer retirement, and no RAM leakage for these LOT commands.
- CI passed: [run 38555604302](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38555604302).

This does not yet prove full-core CPU program execution or all memory-path behavior. Cache-line fill/writeback through the wrapper, outstanding-request reset behavior, system fault handling, synthesis/timing/area, and hardware validation remain open.


### RAM response ownership fix

The bridge now holds RAM routing after a command deasserts and keeps it through all four beats of a cache-line fill. Delayed-response tests passed: [bridge CI run 38557101949](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38557101949) and [actual-cache integration run 38556981169](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38556981169). Dirty-line eviction and full-core program execution are the next verification gates.


### Dirty-line eviction verified

The actual cache + wrapper test now forces a two-way dirty-line eviction, checks the updated word is present in the 128-bit RAM writeback, acknowledges the writeback, and completes the replacement fill. [CI run 38557380566 passed](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38557380566). Full-wrapper high-address and reset/late-response checks are being validated next.


### Full-wrapper guard and reset checks

The actual-cache + adapter + bridge regression passed RAM line fill, two-way dirty writeback, LOT read/write, high physical-address rejection, and reset/late-response checks: [CI run 38557582605](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38557582605). This is not yet full-core program execution or hardware validation.


### Full-core program-level LOT test passed

The new [`tb/tb_openmips_full_core_lot_program.sv`](tb/tb_openmips_full_core_lot_program.sv) instantiates the pinned MIPS32 top-level core, both caches, the cache qualification patch, the LOT wrapper/bridge, a ROM instruction model, and a delayed LOT endpoint. The test program executes:
- `lw` from virtual `0xBF000000` (physical `0x1F000000`, CONTROL), receiving `0x0BAD_C0DE`.
- A data-dependent `sw` to virtual `0xBF000008` (physical `0x1F000008`, STATUS), verifying the returned value reaches the write transaction.
- A `sw` to virtual `0xBF000004` (physical `0x1F000004`, DATA), verifying the expected little-endian memory-bus payload `0x78563412` for the program's `0x12345678` register value.

**Full-core program simulation passed:** [CI run 38559781536](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38559781536). The complete MIPS32 core and caches also compile with the checked-in simulation-only models for generated BRAM/DSP IP: [compile run 38559048706](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38559048706).

These are functional RTL simulations, not vendor timing models or hardware results. The full-core program now also covers three cacheable RAM line fills and a dirty-line writeback. Synthesis, timing/resource reports, and hardware validation remain future work.


### Generic synthesis smoke passed

The integrated top `openmips_mips32_lot_system` completed a Yosys generic synthesis pass: [CI run 38560068393](https://github.com/MAMIDI-LIKHITHA/mips-lot-ip-poc/actions/runs/38560068393). The hierarchy reported 70,353 generic cells. Generated BRAM/DSP IP was treated as black boxes and ABC technology mapping was disabled, so this is only a synthesis-flow check—not an area, LUT, gate-equivalent, or timing estimate. See [generic synthesis limitations and next steps](docs/openmips-generic-synthesis.md).
