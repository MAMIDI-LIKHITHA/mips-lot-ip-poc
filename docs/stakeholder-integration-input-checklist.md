# LOT Integration — Stakeholder Input Checklist

**Purpose:** Collect the minimum target-system facts needed to choose or reuse an interconnect and define the CPU-side adapter without guessing.

**Status:** Awaiting target-system details from the project owner. This checklist is a planning artifact; it does not approve an architecture or change RTL.

## 1. Blocking inputs — answer these first

| Question | Required evidence / answer | Why it blocks design |
|---|---|---|
| What exact MIPS core or subsystem is the target? | Vendor, product/core name, revision/configuration, and link to its manual or RTL/top-level wrapper. | Public references to other MIPS products do not establish this core's interface. |
| What native bus/interface does it expose? | Protocol and version, master/slave role, address/data widths, request/response handshakes, and error/wait-state semantics. | The current LOT router is a custom ready/valid payload fabric, not a demonstrated native MIPS, AXI, AHB, or APB interface. |
| What peripherals already exist? | Address map and inventory of memory-mapped SPI, UART, GPIO, timers, interrupt controller, and any existing bridges. | Reusing a compatible SPI controller may avoid unnecessary custom RTL if the selected wireless device uses SPI. |
| What is LOT expected to do at product level? | Choose/describe: route internal MMIO transactions; carry device commands/messages; bridge external networks; or a defined combination. | A crossbar routes on-chip transactions; it does not implement Matter/Thread or application-level message semantics by itself. |
| What wireless part/mode is under consideration? | Exact Silicon Labs part and board, NCP/RCP/SoC mode, SDK/example version, and documented host interface. If undecided, say so. | Host interface and software-stack placement differ by mode; the repo cannot claim compatibility before this is selected. |

## 2. Integration constraints

Fill in what is known; mark unknown items explicitly rather than guessing.

- **Target platform:** FPGA/ASIC/SoC and part number, if already selected.
- **Clock/reset:** clock frequency/source, reset polarity/sequencing, and whether endpoints use different clock domains.
- **Address map:** reserved ranges, address width, byte vs. word addressing, alignment, and destination decode ownership.
- **Transaction semantics:** reads/writes, byte enables, ordering, maximum outstanding requests, timeout/error behavior, and reset while a request is pending.
- **Traffic requirements:** number of initiators and endpoints, expected concurrency, and any measurable latency/throughput targets.
- **Tooling:** simulator, synthesis/implementation tool, versions, and required regression command.
- **Reuse constraints:** permitted licenses, commercial IP budget/entitlement, distribution model, and any vendor restrictions.

## 3. What the current POC demonstrates

- A parameterized request router and 4×4 ready/valid crossbar.
- A 65-bit candidate request payload in the end-to-end harness: `{write, address[31:0], write_data[31:0]}`.
- Behavioral endpoints and a candidate single-outstanding MMIO adapter.
- Local simulation regression results reported in the README.

## 4. What it does not yet establish

- Compatibility with the actual target MIPS core or its native bus.
- A selected or integrated production interconnect IP.
- Dynamic response-source tracking for a multi-initiator system; the documented end-to-end harness routes its response to source 0.
- Byte-write support in the current request payload.
- A selected Silicon Labs device/board/host mode or working physical link.
- Synthesis, timing closure, resource/power measurements, or hardware validation.

## 5. Decision gates

1. **Host identified:** core/subsystem and native bus backed by source documentation.
2. **Requirements frozen:** topology, transaction contract, address map, error semantics, clock/reset, and performance targets agreed.
3. **Reuse comparison:** compare only candidates compatible with the confirmed interface; check exact revision, feature support, verification evidence, maintenance, license, and integration dependencies.
4. **Adapter contract reviewed:** payload fields, valid/ready stability, response association, errors, reset behavior, and outstanding-transaction policy documented.
5. **Verification updated:** directed tests cover read/write, stalls, backpressure, invalid addresses/destinations, reset while pending, and source association appropriate to the chosen topology.
6. **Implementation measured:** run synthesis/timing/resource analysis only after a target and toolchain are known; hardware claims require board-level evidence.

## 6. Immediate next action

Ask the project owner for the exact MIPS core/subsystem documentation and current peripheral/address-map inventory. If those details are not yet available, keep the current RTL as a simulation reference and do not select an interconnect winner or start a protocol-specific adapter.

## Evidence boundary

This checklist summarizes open integration inputs from the current repository documentation. It is not a vendor compatibility claim, a licensing opinion, a hardware test report, or approval to change RTL.
