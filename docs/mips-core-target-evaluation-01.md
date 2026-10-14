# MIPS Core Target Evaluation — Decision 01

**Status:** Recommended evaluation target; not yet an approved production target.
**Date:** 14 October 2026
**Purpose:** Select a real MIPS core for the next integration experiment without implying that the current LOT POC is already CPU-compatible.

## Recommendation

Use [grantae/OpenMIPS](https://github.com/grantae/OpenMIPS) as the **first reference core to evaluate** because its repository describes a Verilog implementation of the MIPS32 Release 1 ISA and documents extensive processor-level tests. Treat this as a provisional engineering choice for an integration experiment, not a claim that it is the correct core for an unspecified client/product.

The repository README reports an eight-stage in-order pipeline, separate instruction and data cache ports, a TLB, caches, and a legacy synthesis/test flow (including documented Xilinx ISE 14.7 dependencies). This is a substantially more complete MIPS32 implementation than a small teaching core, but it is also more complex to integrate. Confirm repository maintenance, license obligations, supported tools, and target requirements before adopting it in a deliverable.

## Why this target is useful

- It is explicitly described as MIPS32 Release 1 rather than merely a reduced educational subset.
- Its RTL is Verilog and the project describes a sizeable hardware/software verification suite.
- The top-level RTL exposes a distinct data-memory interface, which is the natural place to investigate memory-mapped peripheral traffic.

## Important integration constraints

The current LOT candidate adapter accepts a simple 32-bit address/data request and supports one outstanding transaction. OpenMIPS's top-level `MIPS32` interface is not that protocol:

- Instruction and data memory are separate.
- The data port includes line-read, word-read, line-write, word-write, ready, offset, byte-enable, and 128-bit line-data signals.
- The data cache may issue cache-line transactions as well as word transactions.
- The existing LOT request payload does not carry byte enables or a cache-line payload.

Therefore, **do not connect the OpenMIPS data port directly to the current LOT adapter**. First establish how the target's cache attributes select uncacheable MMIO accesses, and prove that LOT receives only supported word transactions. Keep instruction fetch and normal cacheable memory traffic on their existing memory path. Any line transaction must be handled by ordinary memory, not silently truncated into a LOT request.

## First integration experiment

1. Pin a reviewed commit of the OpenMIPS repository and record its license and build/test prerequisites.
2. Read the top-level `hardware/src/MIPS32/MIPS32.v` and relevant data-cache/cache-attribute logic.
3. Document the precise data-memory request/response timing, address units, cacheability rules, write-byte-enable semantics, and reset behavior.
4. Define an address-map region for uncacheable LOT MMIO only after confirming the core's supported cache attributes and physical-address mapping.
5. Build a standalone adapter testbench first. Cover read, full/partial-byte write, wait states, error/unmapped address, reset while pending, and request/response stability.
6. Only after these tests pass, connect a behavioral LOT endpoint and run an end-to-end CPU load/store program.
7. Run the existing 12-test LOT regression unchanged as a guardrail; then add the new core/adapter tests to the regression.

## Acceptance criteria before calling it integrated

- The exact core revision and license are recorded.
- Signal-level mapping and timing are documented from RTL, not inferred from the ISA name.
- Cacheable memory and instruction fetch remain functional and are not routed to LOT.
- MMIO byte enables and error semantics are preserved.
- Read/write transactions complete exactly once under stalls and reset.
- An executable MIPS test program performs a write/read round trip through a LOT endpoint.
- Existing LOT regression and new integration tests pass in the declared simulator.

## Decision boundary

This document chooses OpenMIPS as the **first candidate for evaluation only**. It does not establish client approval, successful integration, synthesis, timing closure, FPGA operation, or network interoperability. If the product requires a different core, ISA revision, license, toolchain, or bus contract, replace this candidate before implementing a core-specific adapter.
