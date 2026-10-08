# End-to-End Candidate Verification

## Testbench

- Testbench: `tb/tb_end_to_end_candidate.sv`
- DUT path: candidate CPU request through LOT interconnect to endpoint 2 and back
- Simulator: ModelSim Intel FPGA Edition 2021.1

## Flow verified

```text
Candidate CPU request
        ↓
MIPS MMIO adapter
        ↓
LOT transaction router
        ↓
4×4 request XBAR
        ↓
Behavioral endpoint 2
        ↓
Response XBAR
        ↓
LOT response router
        ↓
MIPS MMIO adapter
        ↓
Candidate CPU response
```

## Test stimulus

The testbench issues a write request with:

- Address: `32'h0002_0040`
- Write data: `32'h1234_ABCD`
- Expected destination: endpoint 2
- Expected response data: `32'h0040_ABCD`
- Expected error: `0`

The endpoint model derives the deterministic response from the LOT payload using `{address[15:0], write_data[15:0]}`.

## Result

**PASS**

Observed ModelSim result:

```text
TB RESULT: PASS - CPU request reached endpoint 2 and response returned through response XBAR.
** Note: $stop    : tb/tb_end_to_end_candidate.sv(351)
Time: 296 ns
Errors: 0, Warnings: 0
```

The `$stop` note and resulting break message are expected because the testbench intentionally stops the simulation after the checks pass.

## Verified behaviors

| Check | Result |
|---|---|
| CPU request accepted | PASS |
| Address decoded to destination 2 | PASS |
| Request routed through request XBAR | PASS |
| Endpoint 2 accepted request | PASS |
| Endpoint response generated | PASS |
| Response routed through response XBAR | PASS |
| CPU received `0040_ABCD` | PASS |
| Error remained deasserted | PASS |
| End-to-end completion | PASS |

## Scope

This result verifies the current **candidate** integration path and behavioral endpoint model. It does not establish the final MIPS bus protocol, production endpoint interfaces, network protocol mapping, timing closure, silicon readiness, or full system verification.

## Next verification work

1. Standalone LOT transaction-router directed tests.
2. Standalone LOT response-router directed tests.
3. Reset behavior.
4. Response backpressure and held-valid behavior.
5. Error propagation.
6. Additional request/response corner cases.
