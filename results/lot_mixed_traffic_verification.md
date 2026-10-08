# Mixed Concurrent LOT Traffic Verification

## Testbench

- Testbench: `tb/tb_lot_mixed_traffic.sv`
- Simulator: ModelSim Intel FPGA Edition 2021.1
- Fabric: 4-source / 4-endpoint LOT request and response fabric

## Result

**PASS**

Observed simulation result:

- Accepted transactions: **16**
- Returned responses: **16**
- Contention cycles: **7**
- Backpressure cycles: **7**
- Simulation cycles: **15**
- Simulation errors: **0**
- Testbench result: **PASS**

## Verified scenarios

The testbench verifies mixed concurrent traffic across four independent sources and four endpoint adapters:

1. Four sources begin with a contended write to endpoint 2.
2. Each source then performs an independent write to its own endpoint.
3. Each source reads back its own endpoint register value.
4. Each source issues an invalid local-register write and verifies error propagation.
5. Endpoint ownership is captured at the actual request handshake using the arbitration grant.
6. Response source IDs are checked against the recorded request owner.
7. Response routing is checked at the source-indexed response outputs.
8. Response backpressure is deliberately exercised.
9. Data and error integrity are checked for every returned response.
10. Accepted and returned transaction counts are checked for complete transfer accounting.

## Observed ModelSim output

~~~text
=== MIXED CONCURRENT LOT FABRIC VERIFICATION ===
[1] Four sources begin with a contended write to endpoint 2
[2] Each source then performs an independent write/read/error sequence
[3] Mixed write/read/error responses verified
[4] Response backpressure and stability exercised
[5] Source mapping preserved under contention
Accepted transactions      : 16
Returned responses         : 16
Contention cycles          : 7
Backpressure cycles        : 7
TB RESULT: PASS - mixed concurrent LOT traffic, contention, writes, reads, error responses, backpressure and source mapping verified.
Simulation cycles          : 15
~~~

The final simulator stop is expected testbench termination after all checks pass; it is not a verification failure.

## Scope note

This is a behavioral simulation result. It does not claim timing closure, FPGA resource utilization, or implementation performance.
