// Wrapper joining the pinned OpenMIPS native cache port, the source-specific
// address/qualification adapter, and the candidate LOT memory bridge.
module openmips_native_cache_lot_wrapper #(
    parameter logic [31:0] LOT_BASE = 32'h1F00_0000,
    parameter logic [31:0] LOT_MASK = 32'hFFFF_F000,
    parameter logic [2:0] UNCACHEABLE_ATTR = 3'b010
) (
    input logic clk,
    input logic reset_n,

    input logic [33:0] native_addr,
    input logic native_read_line,
    input logic native_read_word,
    input logic native_line_write_ready,
    input logic native_word_write_ready,
    input logic [3:0] native_word_write_be,
    input logic [127:0] native_data_out,
    input logic native_read_word_paddr_valid,
    input logic native_word_write_paddr_valid,
    output logic [31:0] native_data_in,
    output logic [1:0] native_data_offset,
    output logic native_ready,

    output logic [29:0] ram_addr,
    output logic ram_read_line,
    output logic ram_read_word,
    output logic ram_write_line_ready,
    output logic ram_write_word_ready,
    output logic [3:0] ram_write_word_be,
    output logic [127:0] ram_data_out,
    input logic [31:0] ram_data_in,
    input logic [1:0] ram_data_offset,
    input logic ram_ready,

    output logic lot_valid,
    input logic lot_ready,
    output logic [1:0] lot_dst,
    output logic [64:0] lot_payload,
    input logic lot_rsp_valid,
    output logic lot_rsp_ready,
    input logic [31:0] lot_rsp_rdata,
    input logic lot_rsp_error,

    output logic native_address_rejected,
    output logic protocol_fault
);
    logic [29:0] bridge_word_addr;
    logic bridge_read_line, bridge_read_word;
    logic bridge_line_write_ready, bridge_word_write_ready;
    logic [3:0] bridge_word_write_be;
    logic [127:0] bridge_data_out;
    logic bridge_paddr_valid;
    logic [2:0] bridge_cache_attr;
    logic bridge_fault;

    openmips_native_cache_adapter #(
        .UNCACHEABLE_ATTR(UNCACHEABLE_ATTR)
    ) u_adapter (
        .native_addr(native_addr),
        .native_read_line(native_read_line),
        .native_read_word(native_read_word),
        .native_line_write_ready(native_line_write_ready),
        .native_word_write_ready(native_word_write_ready),
        .native_word_write_be(native_word_write_be),
        .native_data_out(native_data_out),
        .native_read_word_paddr_valid(native_read_word_paddr_valid),
        .native_word_write_paddr_valid(native_word_write_paddr_valid),
        .bridge_word_addr(bridge_word_addr),
        .bridge_read_line(bridge_read_line),
        .bridge_read_word(bridge_read_word),
        .bridge_line_write_ready(bridge_line_write_ready),
        .bridge_word_write_ready(bridge_word_write_ready),
        .bridge_word_write_be(bridge_word_write_be),
        .bridge_data_out(bridge_data_out),
        .bridge_paddr_valid(bridge_paddr_valid),
        .bridge_cache_attr(bridge_cache_attr),
        .address_rejected(native_address_rejected)
    );

    openmips_lot_memory_bridge #(
        .PABITS(32),
        .LOT_BASE(LOT_BASE),
        .LOT_MASK(LOT_MASK),
        .UNCACHEABLE_ATTR(UNCACHEABLE_ATTR)
    ) u_bridge (
        .clk(clk),
        .reset_n(reset_n),
        .data_addr(bridge_word_addr),
        .data_read_line(bridge_read_line),
        .data_read_word(bridge_read_word),
        .data_write_line_ready(bridge_line_write_ready),
        .data_write_word_ready(bridge_word_write_ready),
        .data_write_word_be(bridge_word_write_be),
        .data_out(bridge_data_out),
        .data_paddr_valid(bridge_paddr_valid),
        .data_cache_attr(bridge_cache_attr),
        .data_in(native_data_in),
        .data_offset(native_data_offset),
        .data_ready(native_ready),
        .ram_addr(ram_addr),
        .ram_read_line(ram_read_line),
        .ram_read_word(ram_read_word),
        .ram_write_line_ready(ram_write_line_ready),
        .ram_write_word_ready(ram_write_word_ready),
        .ram_write_word_be(ram_write_word_be),
        .ram_data_out(ram_data_out),
        .ram_data_in(ram_data_in),
        .ram_data_offset(ram_data_offset),
        .ram_ready(ram_ready),
        .lot_valid(lot_valid),
        .lot_ready(lot_ready),
        .lot_dst(lot_dst),
        .lot_payload(lot_payload),
        .lot_rsp_valid(lot_rsp_valid),
        .lot_rsp_ready(lot_rsp_ready),
        .lot_rsp_rdata(lot_rsp_rdata),
        .lot_rsp_error(lot_rsp_error),
        .protocol_fault(bridge_fault)
    );

    assign protocol_fault = bridge_fault | native_address_rejected;
endmodule
