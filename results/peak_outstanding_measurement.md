# Peak Outstanding Measurement — Mixed-Traffic Test

**Status:** Instrumentation added for review; simulation result pending  
**Testbench:** `tb/tb_lot_mixed_traffic.sv`  
**Target:** Current four-source behavioral LOT fabric

## What changed

The mixed-traffic testbench now tracks:

- `accepted_count`: requests accepted at the endpoint request handshake.
- `response_count`: responses completed at the source-facing response handshake.
- `outstanding_count`: accepted requests minus completed responses.
- `max_outstanding`: highest observed outstanding count during the test.

The test prints the peak and final outstanding counts and fails if the count becomes negative or is nonzero at successful completion.

## How to run

From the repository root in ModelSim Intel FPGA Edition, compile the required files and run the testbench. Example:

```tcl
vlog -sv rtl/crossbar/xbar_scheduler.sv rtl/crossbar/xbar_4x4.sv rtl/interconnect/lot_txn_router.sv rtl/interconnect/lot_rsp_router.sv rtl/endpoints/lot_endpoint_adapter.sv tb/tb_lot_mixed_traffic.sv
vsim work.tb_lot_mixed_traffic
run -all
```

Capture the transcript and record the exact simulator/version, result, accepted count, returned-response count, peak outstanding count, and final outstanding count. If the testbench ends with `$stop`, continue or quit the simulator as appropriate after capturing the result.

## Interpretation

This metric is a **baseline measurement for the existing four-source mixed-traffic scenario**. It does not by itself prove support for 16 outstanding transactions. The count starts at the endpoint request acceptance handshake and ends at the source-facing response completion handshake, so it spans the modeled endpoint response latency and response routing. It is not a count of physical device-level M2M exchanges.

Do not infer a passing concurrency requirement from the printed peak until the project owner defines the required number and the exact acceptance/completion boundaries. This testbench's endpoint-owner and response-source association are still testbench bookkeeping; they are not a substitute for a production transaction-ID/response-association design.

## Validation status

No simulator result is claimed by this change. Run the test locally before treating the instrumentation as validated. After confirming it compiles and passes, update this document with the actual observed output and then decide whether a separate directed test should target 16 outstanding transactions.
