# 20 — Response Path Architecture

## Purpose

The request-side XBAR routes a transaction from an initiator to a selected LOT destination. A complete request/response transaction also needs a return path.

This adds a protocol-neutral response fabric without assuming the final MIPS bus protocol.

## Architecture

Request path:

MIPS/Initiator -> request adapter -> LOT transaction router -> 4x4 XBAR -> endpoint

Response path:

endpoint -> response source ID + data/error -> response router -> MIPS/Initiator

The response router uses the response source ID as its routing destination.

## Response interface

Each response source provides:

- src_valid
- src_ready
- src_id
- src_data
- src_error

Each response destination provides:

- dst_valid
- dst_ready
- dst_data
- dst_error

The response source ID identifies the destination that must receive the response. For the current 4-source/4-destination POC, it is 2 bits.

## Why a separate response fabric

Request routing uses the destination selected by the initiator. Response routing uses the source/initiator ID associated with the completed transaction.

Keeping the directions separate makes the protocol-neutral layer explicit and avoids assuming a specific MIPS bus response mechanism.

## Current limitation

The actual MIPS bus protocol, endpoint completion protocol, transaction ID requirements, and multiple-outstanding behavior are still unconfirmed.

Therefore this response router is an architectural POC component, not evidence of final MIPS integration.

## Verification

tb_lot_rsp_router.sv checks direct routing, error propagation, response contention, and backpressure.

A PASS statement is valid only after running the testbench in a compatible simulator.
