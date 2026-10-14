// Integrated functional RTL top: pinned OpenMIPS MIPS32 core + data-cache
// qualification adapter + LOT/RAM memory bridge. Instruction memory and the
// RAM/LOT targets remain external system interfaces.
module openmips_mips32_lot_system #(
    parameter integer PABITS = 36,
    parameter logic [31:0] LOT_BASE = 32'h1F00_0000,
    parameter logic [31:0] LOT_MASK = 32'hFFFF_F000
) (
    input  logic clk,
    input  logic reset,
    input  logic [4:0] interrupts,
    input  logic nmi,

    output logic [33:0] inst_addr,
    output logic inst_read_line,
    output logic inst_read_word,
    input  logic inst_ready,
    input  logic [31:0] inst_data,
    input  logic [1:0] inst_offset,

    output logic [29:0] ram_addr,
    output logic ram_read_line,
    output logic ram_read_word,
    output logic ram_write_line_ready,
    output logic ram_write_word_ready,
    output logic [3:0] ram_write_word_be,
    output logic [127:0] ram_data_out,
    input  logic [31:0] ram_data_in,
    input  logic [1:0] ram_data_offset,
    input  logic ram_ready,

    output logic lot_valid,
    input  logic lot_ready,
    output logic [1:0] lot_dst,
    output logic [64:0] lot_payload,
    input  logic lot_rsp_valid,
    output logic lot_rsp_ready,
    input  logic [31:0] lot_rsp_rdata,
    input  logic lot_rsp_error,

    output logic native_address_rejected,
    output logic protocol_fault
);
    logic [33:0] data_addr;
    logic data_read_line, data_read_word, data_write_line, data_write_word;
    logic [3:0] data_write_be;
    logic [127:0] data_out;
    logic data_read_word_paddr_valid, data_write_word_paddr_valid;
    logic [31:0] data_in;
    logic [1:0] data_offset;
    logic data_ready;

    MIPS32 #(.PABITS(PABITS)) cpu (
        .clock(clk),
        .reset(reset),
        .Core_Reset(reset),
        .InstMem_Address(inst_addr),
        .InstMem_ReadLine(inst_read_line),
        .InstMem_ReadWord(inst_read_word),
        .InstMem_Ready(inst_ready),
        .InstMem_In(inst_data),
        .InstMem_Offset(inst_offset),
        .DataMem_Address(data_addr),
        .DataMem_ReadLine(data_read_line),
        .DataMem_ReadWord(data_read_word),
        .DataMem_In(data_in),
        .DataMem_Ready(data_ready),
        .DataMem_Offset(data_offset),
        .DataMem_WriteLineReady(data_write_line),
        .DataMem_WriteWordReady(data_write_word),
        .DataMem_WriteWordBE(data_write_be),
        .DataMem_Out(data_out),
        .DataMem_ReadWordPAddressValid(data_read_word_paddr_valid),
        .DataMem_WriteWordPAddressValid(data_write_word_paddr_valid),
        .Interrupts(interrupts),
        .NMI(nmi)
    );

    openmips_native_cache_lot_wrapper #(
        .LOT_BASE(LOT_BASE),
        .LOT_MASK(LOT_MASK)
    ) memory_wrapper (
        .clk(clk),
        .reset_n(~reset),
        .native_addr(data_addr),
        .native_read_line(data_read_line),
        .native_read_word(data_read_word),
        .native_line_write_ready(data_write_line),
        .native_word_write_ready(data_write_word),
        .native_word_write_be(data_write_be),
        .native_data_out(data_out),
        .native_read_word_paddr_valid(data_read_word_paddr_valid),
        .native_word_write_paddr_valid(data_write_word_paddr_valid),
        .native_data_in(data_in),
        .native_data_offset(data_offset),
        .native_ready(data_ready),
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
        .native_address_rejected(native_address_rejected),
        .protocol_fault(protocol_fault)
    );
endmodule
