# Four-Endpoint LOT Fabric Verification

## Scope

Verified that all four independent LOT endpoint adapters are reachable through the shared 4x4 request crossbar and that each endpoint response returns through the shared response crossbar/router to the candidate MIPS-side adapter.

## Testbench

- `tb/tb_lot_multi_endpoint.sv`
- Four independent `lot_endpoint_adapter` instances at destinations 0, 1, 2 and 3.
- Candidate MIPS MMIO adapter as the single request source and response destination.
- Shared request and response fabrics.

## Test sequence

1. Endpoint 0 ID read
2. Endpoint 1 ID read
3. Endpoint 2 ID read
4. Endpoint 3 ID read
5. Endpoint isolation check

The endpoint ID register is `0x000C` and returns `32'h4C4F_5430` (`LOT0`).

## Result

```text
=== MULTI-ENDPOINT LOT FABRIC VERIFICATION ===
[1] Endpoint 0 ID read
[2] Endpoint 1 ID read
[3] Endpoint 2 ID read
[4] Endpoint 3 ID read
[5] Endpoint isolation check
TB RESULT: PASS - all four XBAR destinations reached independent LOT endpoint adapters and returned correct register responses through the shared response fabric.
Time: 186 ps
Errors: 0
Warnings: 0
```

## Conclusion

PASS. All four XBAR destinations were exercised with independent endpoint instances, correct ID responses were observed, the shared response path returned each transaction to the candidate CPU-side adapter, and no endpoint response remained asserted after the completed sequence.

This is a functional simulation result only; no FPGA Fmax, area, or resource-utilization claim is made.
