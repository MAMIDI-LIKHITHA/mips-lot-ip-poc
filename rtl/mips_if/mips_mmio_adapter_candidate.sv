// Candidate MIPS-side MMIO adapter.
// NOT the final MIPS bus adapter: the actual MIPS bus protocol is unconfirmed.
// This module provides a single-outstanding-request bridge from a simple
// memory-mapped CPU handshake into the protocol-neutral LOT interfaces.

module mips_mmio_adapter_candidate #(
    parameter int ADDR_W = 32,
    parameter int DATA_W = 64,
    parameter int DST_W  = 2,
    parameter int LOT_W  = ADDR_W + (DATA_W/2) + 1,
    parameter logic [ADDR_W-1:0] DEST0_BASE = '0,
    parameter logic [ADDR_W-1:0] DEST1_BASE = 32'h0001_0000,
    parameter logic [ADDR_W-1:0] DEST2_BASE = 32'h0002_0000,
    parameter logic [ADDR_W-1:0] DEST3_BASE = 32'h0003_0000,
    parameter logic [ADDR_W-1:0] DEST_MASK  = 32'hFFFF_0000
) (
    input  logic clk,
    input  logic rst_n,

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
    output logic [LOT_W-1:0] lot_payload,

    input  logic lot_rsp_valid,
    output logic lot_rsp_ready,
    input  logic [DATA_W/2-1:0] lot_rsp_rdata,
    input  logic lot_rsp_error
);

    logic busy;
    logic response_valid;
    logic [DATA_W/2-1:0] response_data;
    logic response_error;
    logic addr_valid;

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
                decode_dst = '0;
        end
    endfunction

    always_comb begin
        addr_valid =
            ((req_addr & DEST_MASK) == (DEST0_BASE & DEST_MASK)) ||
            ((req_addr & DEST_MASK) == (DEST1_BASE & DEST_MASK)) ||
            ((req_addr & DEST_MASK) == (DEST2_BASE & DEST_MASK)) ||
            ((req_addr & DEST_MASK) == (DEST3_BASE & DEST_MASK));
    end

    // One outstanding request at a time.
    assign req_ready = !busy && lot_ready && addr_valid && rst_n;
    assign lot_valid = req_valid && req_ready;
    assign lot_dst = decode_dst(req_addr);

    // Payload = {write, address, write_data}.
    // LOT_W is sized explicitly so the write bit cannot overlap the address.
    always_comb begin
        lot_payload = '0;
        lot_payload[LOT_W-1] = req_write;
        lot_payload[LOT_W-2 -: ADDR_W] = req_addr;
        lot_payload[(DATA_W/2)-1:0] = req_wdata;
    end

    assign lot_rsp_ready = busy && !response_valid;

    assign rsp_valid = response_valid;
    assign rsp_rdata = response_data;
    assign rsp_error = response_error;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            response_valid <= 1'b0;
            response_data <= '0;
            response_error <= 1'b0;
        end else begin
            if (lot_valid && lot_ready) begin
                busy <= 1'b1;
                response_valid <= 1'b0;
                response_data <= '0;
                response_error <= 1'b0;
            end

            if (lot_rsp_valid && lot_rsp_ready) begin
                response_valid <= 1'b1;
                response_data <= lot_rsp_rdata;
                response_error <= lot_rsp_error;
            end

            if (rsp_valid && rsp_ready) begin
                busy <= 1'b0;
                response_valid <= 1'b0;
            end
        end
    end

endmodule
