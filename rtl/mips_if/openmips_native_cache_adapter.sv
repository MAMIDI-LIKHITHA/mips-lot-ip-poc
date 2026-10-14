// Source-specific adapter for the pinned OpenMIPS DataCache_2KB PABITS=36 port.
// Requires the qualification sidebands added by scripts/apply-openmips-cache-qualification.py.
module openmips_native_cache_adapter #(
    parameter logic [2:0] UNCACHEABLE_ATTR = 3'b010
) (
    input  logic [33:0] native_addr,
    input  logic        native_read_line,
    input  logic        native_read_word,
    input  logic        native_line_write_ready,
    input  logic        native_word_write_ready,
    input  logic [3:0]  native_word_write_be,
    input  logic [127:0] native_data_out,
    input  logic        native_read_word_paddr_valid,
    input  logic        native_word_write_paddr_valid,

    output logic [29:0] bridge_word_addr,
    output logic        bridge_read_line,
    output logic        bridge_read_word,
    output logic        bridge_line_write_ready,
    output logic        bridge_word_write_ready,
    output logic [3:0]  bridge_word_write_be,
    output logic [127:0] bridge_data_out,
    output logic        bridge_paddr_valid,
    output logic [2:0]  bridge_cache_attr,
    output logic        address_rejected
);
    logic command_valid;
    logic bridge_command_valid;
    logic word_command;
    logic word_paddr_valid;

    assign command_valid = native_read_line | native_read_word |
                           native_line_write_ready | native_word_write_ready;
    assign word_command = native_read_word | native_word_write_ready;
    assign word_paddr_valid = native_read_word ? native_read_word_paddr_valid :
                              native_word_write_ready ? native_word_write_paddr_valid : 1'b0;

    openmips_native_addr_guard u_addr_guard (
        .native_word_addr(native_addr),
        .command_valid(command_valid),
        .bridge_word_addr(bridge_word_addr),
        .bridge_command_valid(bridge_command_valid),
        .address_rejected(address_rejected)
    );

    // Only ReadWord_M and WordOutReady_M are single-word uncacheable commands
    // on this native cache port. Line fills/writebacks stay on the RAM path.
    always_comb begin
        bridge_read_line = native_read_line && bridge_command_valid;
        bridge_read_word = native_read_word && bridge_command_valid;
        bridge_line_write_ready = native_line_write_ready && bridge_command_valid;
        bridge_word_write_ready = native_word_write_ready && bridge_command_valid;
        bridge_word_write_be = bridge_word_write_ready ? native_word_write_be : 4'b0000;
        bridge_data_out = native_data_out;
        bridge_paddr_valid = word_command ? word_paddr_valid : 1'b1;
        bridge_cache_attr = (word_command && word_paddr_valid) ? UNCACHEABLE_ATTR : 3'b000;
    end
endmodule
