# 01 — Requirements

## Confirmed / source-supported

- The project is an insertable LOT IP building block for an existing MIPS architecture.
- Interconnect functionality includes destination/address decode, request generation, arbitration, routing of address/control/data, response routing and backpressure.
- Reset and configuration support are required.
- Verification must cover connectivity, concurrent traffic, contention/arbitration, read/write behavior, response routing, backpressure, invalid addresses, reset/error behavior and configuration.
- Final evidence must be simulation-based and reproducible.

## To Verify

| Requirement | Current status |
|---|---|
| MIPS bus protocol | To Verify |
| Address width | To Verify |
| Data width | To Verify |
| Transaction ID support | To Verify |
| Read/write ordering | To Verify |
| Outstanding transactions | To Verify |
| Burst support | To Verify |
| Clock frequency | To Verify |
| Latency target | To Verify |
| Throughput target | To Verify |
| Fairness/QoS target | To Verify |
| CDC boundaries | To Verify |
| Target FPGA/silicon | To Verify |
| Four final endpoints | To Verify |
| Address map | To Verify |

## Temporary POC assumptions

The initial crossbar RTL will use a small generic single-beat request/response transaction abstraction. This is an engineering vehicle for proving routing/arbitration behavior, not a claim about the final MIPS bus.
