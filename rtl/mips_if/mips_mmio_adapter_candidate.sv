// Candidate MIPS-side MMIO adapter.
// NOT the final MIPS bus adapter: the actual MIPS bus protocol is unconfirmed.
// This module provides a single-outstanding-request bridge from a simple
// memory-mapped CPU handshake into the protocol-neutral LOT request interface.

module mips_mmio_adapter_candidate #(
    parameter int ADDR_W = 32,
    parameter int DATA_W = 64,
    parameter int DST_W  = 2,
    parameter logic [ADDR_W-1:0] DEST0_BASE = '0,
    parameter logic [ADDR_W-1:0] DEST1_BASE = 32'h0001_0000,
    parameter logic [ADDR_W-1:0] DEST2_BASE = 32'h0002_0000,
    parameter logic [ADDR_W-1:0] DEST3_BASE = 32'h0003_0000,
    parameter logic [ADDR_W-1:0] DEST_MASK  = 32'hFFFF_0000
) (
    input  logic req_valid,
    output logic req_ready,
    input  logic req_write,
    input  logic [ADDR_W-1:0] req_addr,
    input  logic [DATA_W/2-1:0] req_wdata,

    output logic rsp_valid,
    input  logic rsp_ready,
    output logic [DATA_W/2-1:0] rsp_rdata,
    output logic rsp_error,

    output logic lot_valid,
    input  logic lot_ready,
    output logic [DST_W-1:0] lot_dst,
    output logic [DATA_W-1:0] lot_payload
);

    logic busy;
    logic [DATA_W/2-1:0] response_data;
    logic response_error;

    function automatic logic [DST_W-1:0] decode_dst(input logic [ADDR_W-1:0] addr);
        begin
            if ((addr & DEST_MASK) == (DEST0_BASE & DEST_MASK))
                decode_dst = 'd0;
            else if ((addr & DEST_MASK) == (DEST1_BASE & DEST_MASK))
                decode_dst = 'd1;
            else if ((addr & DEST_MASK) == (DEST2_BASE & DEST_MASK))
                decode_dst = 'd2;
            else if ((addr & DEST_MASK) == (DEST3_BASE & DEST_MASK))
                decode_dst = 'd3;
            else
                decode_dst = 'd3;
        end
    endfunction

    assign req_ready = !busy && lot_ready;
    assign lot_valid = req_valid && req_ready;
    assign lot_dst = decode_dst(req_addr);

    always_comb begin
        lot_payload = '0;
        lot_payload[DATA_W-1] = req_write;
        lot_payload[DATA_W/2-1:0] = req_wdata;
        lot_payload[DATA_W/2 + ADDR_W - 1:DATA_W/2] = req_addr;
    end

    assign rsp_valid = busy;
    assign rsp_rdata = response_data;
    assign rsp_error = response_error;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            response_data <= '0;
            response_error <= 1'b0;
        end else begin
            if (lot_valid && lot_ready) begin
                busy <= 1'b1;
                response_data <= '0;
                response_error <= 1'b0;
            end
            if (rsp_valid && rsp_ready)
                busy <= 1'b0;
        end
    end

endmodule
