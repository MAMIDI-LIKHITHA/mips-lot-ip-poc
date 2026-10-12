# Current RTL Concurrency Capability Audit

**Status:** Static RTL/testbench review; not a new simulation result  
**Reviewed:** 2026-10-12  
**Purpose:** Identify what the existing candidate fabric demonstrates today, and what must be added or clarified before claiming the MobilFlex goal of 16 concurrent M2M transactions.

## Executive finding

The current design demonstrates a **4-port request/response fabric with concurrent traffic and contention tests**, but the RTL reviewed here does **not establish support for 16 simultaneously outstanding end-to-end transactions**.

The 4×4 crossbar has four input request channels and four output request channels. It can transfer up to four request beats in a cycle when all four sources target distinct ready destinations. A 4×4 topology has 16 possible source/destination pairs; that is route coverage, not 16 in-flight transaction capacity.

## Evidence from the current RTL

### Request path

File: `rtl/interconnect/lot_txn_router.sv`

- The module is a thin wrapper around `xbar_4x4`.
- Each source supplies `valid`, `dst`, and payload data, and receives `ready`.
- There is no request queue, outstanding-transaction counter, transaction ID, or response-association table in this router.
- The comment explicitly describes one transaction as one beat.

File: `rtl/crossbar/xbar_4x4.sv`

- Four input channels arbitrate for four output channels.
- The scheduler selects grants; the input sees ready when its selected destination is ready.
- There are no per-source outstanding-transaction buffers in this module.

### Endpoint behavior

File: `rtl/endpoints/lot_endpoint_adapter.sv`

- Each behavioral endpoint has a single `response_pending` bit and one response-data/error register.
- `req_ready` is deasserted while that response is pending.
- This is a single-pending-response endpoint model, not a queue of multiple outstanding requests.

### Response path

File: `rtl/interconnect/lot_rsp_router.sv`

- The response router uses the supplied `src_id` as the return destination and routes response data plus an error bit.
- It does not itself store request-to-response ownership or recover a transaction ID from the request path.
- The end-to-end testbench must provide a valid response source ID. In `tb/tb_lot_mixed_traffic.sv`, endpoint ownership is captured by testbench scoreboard logic at request acceptance and then used to assign the response source ID. That bookkeeping is verification scaffolding, not a production transaction-association block in the RTL.

### Existing concurrent tests

- `tb/tb_lot_concurrent_fabric.sv` drives four sources to four independent endpoints and checks four returned responses.
- `tb/tb_lot_mixed_traffic.sv` exercises four sources, contention, read/write/error traffic and response backpressure, with source ownership tracked in the testbench.
- These tests are valuable evidence for four-port concurrent fabric behavior. They do not demonstrate 16 outstanding requests at once.

## Current capability statement

| Capability | Evidence-based status |
|---|---|
| 4×4 source/destination routing | Implemented and covered by the reported route tests |
| Up to four independent request beats accepted in the same cycle | Architecturally possible when four sources select distinct ready destinations; verify through a cycle-level assertion/test |
| Contention and ready/valid backpressure | Existing targeted testbenches cover these behaviors |
| Response payload/error routing | Response-router test covers routing and error propagation |
| 16 route combinations exercised | Reported route-coverage test exercises all 16 combinations |
| 16 outstanding transactions | **Not established**; no evidence here of 16-entry outstanding capacity |
| Multiple outstanding transactions per source | **Not established**; request source interface has no visible transaction IDs/queue, and endpoint model allows one pending response |
| End-to-end M2M device concurrency | **Not established**; no selected physical endpoint/controller contract |
| Native MIPS bus compatibility | **Not established**; the candidate adapter is not connected to an owner-confirmed core interface |
| CPU-utilization reduction | **Not established**; requires a defined baseline and host/workload measurement |

## Recommended next technical step

Do not immediately add a 16-entry queue. First ask the project owner to define which concurrency target applies:

1. **Four-way simultaneous fabric transfer:** four source channels can transfer one beat each in a cycle, subject to distinct ready destinations.
2. **Sixteen outstanding transactions:** requests can be accepted and remain incomplete concurrently. This requires explicit outstanding capacity, transaction identity/ordering rules, response association, backpressure, and defined behavior on reset/errors.
3. **Sixteen end-to-end M2M exchanges:** the test must model the selected endpoint/controller paths and define when each exchange starts and completes.

Once the target is approved:

1. Add a directed test that counts accepted requests minus completed responses every cycle and asserts the required peak outstanding count.
2. Use unique transaction tags or another owner-approved association scheme so responses can be checked against requests.
3. Exercise response reordering only if the target contract permits it; otherwise assert ordering.
4. Add stalls, contention, reset with pending transactions and error cases.
5. Run the full ModelSim regression and save the actual logs; update the results document with observed peak outstanding count and the exact tested topology.
6. Only then decide whether queues, IDs, endpoint changes or a wider architecture are needed.

## Suggested acceptance metric

For an agreed in-flight target (K), define:

`outstanding(t) = accepted_requests(t) - completed_responses(t)`

Pass only if:

- `max(outstanding(t)) >= K` during the directed test;
- every accepted request receives exactly one matching response;
- no response is duplicated, lost or misassociated;
- the agreed ordering, backpressure, reset and error rules hold.

The definition of acceptance and completion must be aligned to the selected protocol. A request handshake may mean acceptance into the fabric, not acceptance by the final endpoint; report these counts separately if both are important.

## Scope and limitations

This is a static review of the named RTL and testbench files. No RTL was modified, no simulator was run for this audit, and no hardware or synthesis claim is made. The reported 12-test local regression remains the baseline until a new run provides fresh evidence.
