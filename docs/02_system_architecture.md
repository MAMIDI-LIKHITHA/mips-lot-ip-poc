# 02 — System Architecture

## Intended layering

```
+----------------------+
|      MIPS Core       |
+----------+-----------+
           |
+----------v-----------+
|   MIPS / Bus Adapter  |
+----------+-----------+
           |
+----------v-----------+
| Interconnect / Txn    |
|       Layer           |
+----------+-----------+
           |
+----------v-----------+
|       4×4 XBAR        |
|  routing + arbitration|
+----+------+------+----+
     |      |      |
     |      |      +------ Endpoint Adapter
     |      +------------- Endpoint Adapter
     +-------------------- Endpoint Adapter
                    ...
```

The exact adapter signals and endpoint mapping remain open.

## Design principle

Keep protocol-specific logic outside the generic switching fabric where practical. This allows the crossbar to be verified independently and avoids coupling the first POC to an unconfirmed MIPS or radio interface.

## Transaction path

For the current POC:

1. Input transaction arrives.
2. Destination is decoded.
3. Input requests the selected output.
4. Scheduler arbitrates output contention while enforcing one grant per input per cycle.
5. Granted transaction is routed.
6. Response/ready behavior is handled by the selected transaction abstraction.
