# LOT Endpoint Adapter Verification

**PASS**

A reusable protocol-neutral LOT endpoint register adapter was added and verified with directed ready/valid transactions in ModelSim Intel FPGA Edition.

### Verified
- CONTROL register write/readback at 0x0000
- DATA register write/readback at 0x0004
- STATUS read at 0x0008
- Endpoint ID read at 0x000C
- Invalid local address error at 0x0010
- One outstanding response
- Request and response ready/valid handshakes

### Register map

| Offset | Register | Access |
|---|---|---|
| 0x0000 | CONTROL | RW |
| 0x0004 | DATA | RW |
| 0x0008 | STATUS | RO |
| 0x000C | ID | RO |

### Reproduction

    vlog -sv rtl/endpoints/lot_endpoint_adapter.sv tb/tb_lot_endpoint_adapter.sv
    vsim work.tb_lot_endpoint_adapter
    run -all

This remains a protocol-neutral behavioral POC and does not claim to implement a final Matter, Thread, Wi-Fi, BLE, Ethernet, or confirmed MIPS peripheral protocol.
