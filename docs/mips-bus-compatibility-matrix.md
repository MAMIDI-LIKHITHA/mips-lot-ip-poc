# MIPS Bus Compatibility and Adapter Decision Matrix

**Status:** Preliminary integration research; no target MIPS core has been identified.  
**Scope:** Define what must be checked before selecting a CPU-side adapter or changing LOT RTL.

## Executive result

**[Confirmed — current repository]** The present LOT transaction router is a protocol-neutral ready/valid fabric wrapper. In `rtl/interconnect/lot_txn_router.sv`, its interface exposes clock/reset, per-source valid/ready, destination selection, data payload, per-destination valid/ready/data, and grants. The router itself does not expose a complete AXI/AHB/APB or MIPS-specific request/response interface.

**[Inference — medium confidence]** Keep the LOT fabric behind a dedicated adapter boundary until the target CPU bus is known. Do not label the current router “AXI-compatible,” “AHB-compatible,” or “MIPS-bus-compatible” without a signal-level mapping and tests.

**[Check — blocking]** The repository does not identify the exact MIPS core, its native bus, bus widths, timing/handshake rules, or a real peripheral map. Consequently, there is no evidence yet for selecting one standard bus or a specific adapter implementation.

## Compatibility matrix

| Candidate interface | What must be true | Adapter work to evaluate | Decision status |
|---|---|---|---|
| Existing native MIPS-side bus | Core RTL/manual identifies request, response, address/data widths, wait/stall behavior, errors, reset and clock rules. | Map one native transaction into a LOT request and return exactly one corresponding response; preserve stalls and error semantics. | **First choice to investigate**; core unknown. |
| AMBA AXI / AXI-Lite | Target subsystem already exposes AXI, or a justified bridge is available. | Handle independent address/data channels (for full AXI), response channels, IDs/outstanding transactions as applicable, byte strobes, burst rules, and ordering. AXI-Lite is simpler but still has distinct read/write channels and response semantics. | **Conditional**; do not assume the MIPS core uses it. |
| AMBA AHB / AHB-Lite | Existing CPU/peripheral subsystem exposes a compatible AHB variant. | Respect address/control phase, transfer sequencing, ready/wait states, response/error behavior, and data-phase association. | **Conditional**; check exact variant and timing. |
| AMBA APB | Intended target is a simple peripheral interface and a bridge/master path exists. | Handle setup/access phases, select/enable, ready wait states, read/write controls, and error response if implemented. APB is usually a peripheral-side interface, not a universal CPU bus replacement. | **Likely peripheral-side option only**, depending on subsystem. |
| Custom minimal MMIO request/response | No existing standard interface can be reused, and the custom contract is accepted by the integrator. | Specify request acceptance, response validity, one-outstanding vs multiple-outstanding, byte enables, timeout/error behavior, alignment, and reset recovery. | **Possible**, but requires an explicit contract first. |

Standards reference: [Arm AMBA overview](https://www.arm.com/architecture/system-architectures/amba) and [AMBA specifications](https://www.arm.com/architecture/system-architectures/amba/amba-specifications). These describe the protocols; they do **not** establish which protocol the target MIPS subsystem uses.

## What the existing RTL does—and does not—prove

- **[Confirmed]** `lot_txn_router.sv` forwards a destination-selected payload over a ready/valid-style fabric and exposes grants.
- **[Confirmed]** The current README describes a candidate MMIO adapter and behavioral endpoints for simulation.
- **[Check]** Trace the exact top-level path and payload packing from the candidate adapter into the fabric. Confirm where address, write/read operation, write data, byte enables, transaction IDs, and error status are represented.
- **[Check]** Confirm whether the return path preserves source association under contention and backpressure for the intended CPU bus.
- **[Not established]** A direct connection to a real MIPS core, a standards-compliant bus bridge, a physical SPI controller, or a radio device.

The current crossbar's ready/valid behavior is a useful internal transport contract, but it is not by itself a complete CPU bus protocol.

## Required discovery checklist

Complete this from the actual target RTL, integration guide, or core manual—not from assumptions:

1. **Core identity:** vendor, product/core name, version, configuration, and whether source RTL or only a subsystem wrapper is available.
2. **Native bus:** protocol and revision; master/slave role; address and data widths; endianness; alignment; byte enables; bursts; transaction IDs; maximum outstanding requests.
3. **Handshake:** what accepts a request; how wait states are represented; whether reads and writes can progress independently; how responses are matched to requests.
4. **Errors and timeouts:** unmapped addresses, access faults, slave errors, timeout handling, and reset during a pending transaction.
5. **Clock/reset:** source clocks, asynchronous crossings, reset polarity and sequencing, and whether a CDC bridge is required.
6. **Address map:** existing RAM/ROM and peripheral ranges; where LOT fits; address decode ownership and aliasing rules.
7. **Existing peripherals:** SPI controller presence, register map, FIFO, interrupts, DMA requirements, clock divider, supported modes, pin mux and board connection.
8. **Integration constraints:** synthesis tool/version, target FPGA/ASIC, licensing, timing goals, and testbench/simulation environment.

## Minimal adapter contract to agree before RTL changes

The adapter design review should decide these items explicitly:

- **Request payload:** destination/address, read/write, write data, byte enables, and any required transaction tag.
- **Request handshake:** precisely when a request is accepted; no duplicate issue while stalled.
- **Response payload:** read data, success/error status, and transaction tag if more than one request can be outstanding.
- **Ordering:** whether only one request can be outstanding; if multiple, how response ordering and ID association work.
- **Addressing:** byte vs word addresses, alignment checks, address decode, and unmapped-target behavior.
- **Reset/clock:** reset state, pending-request cancellation/recovery, and CDC requirements.
- **Verification:** directed tests for read/write, wait states, backpressure, simultaneous requests, errors, reset mid-transaction, invalid addresses, and data integrity.

A single-outstanding adapter is a reasonable **starting experiment** only if the target CPU interface permits it and throughput/latency requirements accept the restriction. It is not yet a requirement or a measured performance choice.

## Recommended decision sequence

1. Identify the exact MIPS core and native bus from the target project or integration documentation.
2. Inventory existing bridges and peripherals, especially a memory-mapped SPI controller.
3. Compare the native bus with the LOT payload/handshake contract and document any semantic gaps.
4. Select the smallest correct adapter or existing bridge; avoid redesigning the LOT fabric to imitate a standard protocol unless a concrete integration need justifies it.
5. Add adapter-level tests first, then end-to-end simulation against behavioral bus/peripheral models.
6. Only after the target and toolchain are known, run synthesis/timing/resource analysis and board tests.

## Evidence boundary

This document is research guidance, not proof of target compatibility. It adds no RTL or testbench changes and does not claim synthesis, timing closure, hardware validation, or interoperability.
