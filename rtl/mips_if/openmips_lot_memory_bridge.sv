// Candidate bridge between the OpenMIPS DataCache memory port and LOT.
// First integration scope: PABITS=32, aligned full-word accesses to four
// 32-bit endpoint registers at LOT_BASE + {0,4,8,C}. Cache-line traffic stays
// on the RAM port. This module does NOT modify or instantiate the OpenMIPS core.
//
// IMPORTANT: data_paddr_valid and data_cache_attr are internal-core sidebands.
// The stock MIPS32 top-level does not export them; an integration top must expose
// the matching DCache/Processor signals before this bridge can be safely wired.
module openmips_lot_memory_bridge #(
    parameter int PABITS = 32,
    parameter logic [31:0] LOT_BASE = 32'h1F00_0000,
    parameter logic [31:0] LOT_MASK = 32'hFFFF_F000,
    parameter logic [2:0] UNCACHEABLE_ATTR = 3'b010
) (
    input  logic clk,
    input  logic reset_n,

    // OpenMIPS DataCache memory-side request signals.
    input  logic [PABITS-3:0] data_addr, // word-address units; append 2'b00
    input  logic data_read_line,
    input  logic data_read_word,
    input  logic data_write_line_ready,
    input  logic data_write_word_ready,
    input  logic [3:0] data_write_word_be,
    input  logic [127:0] data_out,
    input  logic data_paddr_valid,
    input  logic [2:0] data_cache_attr,

    // OpenMIPS DataCache memory-side return signals.
    output logic [31:0] data_in,
    output logic [1:0] data_offset,
    output logic data_ready,

    // Existing RAM/controller port. Line commands and non-LOT words pass here.
    output logic [PABITS-3:0] ram_addr,
    output logic ram_read_line,
    output logic ram_read_word,
    output logic ram_write_line_ready,
    output logic ram_write_word_ready,
    output logic [3:0] ram_write_word_be,
    output logic [127:0] ram_data_out,
    input  logic [31:0] ram_data_in,
    input  logic [1:0] ram_data_offset,
    input  logic ram_ready,

    // Existing LOT ready/valid request and response contract.
    output logic lot_valid,
    input  logic lot_ready,
    output logic [1:0] lot_dst,
    output logic [64:0] lot_payload,
    input  logic lot_rsp_valid,
    output logic lot_rsp_ready,
    input  logic [31:0] lot_rsp_rdata,
    input  logic lot_rsp_error,

    // Sticky fail-stop indicator. The native cache port has no error response.
    output logic protocol_fault
);
    logic class_route_lot;
    logic class_route_ram;
    logic class_reject;
    logic class_window;
    logic route_lot;
    logic route_ram;
    logic reject_access;
    logic [31:0] byte_addr;
    logic pending;
    logic ram_pending;
    logic ram_line_pending;
    logic [1:0] ram_line_beat_count;
    logic ram_command;
    logic [1:0] endpoint_dst;
    logic endpoint_offset_supported;
    logic lot_response_fire;

    // The OpenMIPS top-level memory address is a word address, not byte address.
    // This first implementation deliberately supports PABITS=32 only.
    assign byte_addr = {data_addr, 2'b00};
    assign endpoint_offset_supported = (byte_addr[11:0] <= 12'h00C);

    openmips_lot_access_classifier #(
        .LOT_BASE(LOT_BASE),
        .LOT_MASK(LOT_MASK),
        .UNCACHEABLE_ATTR(UNCACHEABLE_ATTR)
    ) u_classifier (
        .paddr_valid(data_paddr_valid),
        .byte_addr(byte_addr),
        .cache_attr(data_cache_attr),
        .read_word(data_read_word),
        .write_word(data_write_word_ready),
        .write_word_be(data_write_word_ready ? data_write_word_be : 4'b0000),
        .read_line(data_read_line),
        .write_line(data_write_line_ready),
        .route_lot(class_route_lot),
        .route_ram(class_route_ram),
        .reject_access(class_reject),
        .is_lot_window(class_window)
    );

    // The current POC has four endpoint destinations: CONTROL, DATA, STATUS,
    // ID. A hit elsewhere in the 4 KiB classifier window is not a valid endpoint.
    assign endpoint_dst = byte_addr[3:2];
    // Once a LOT request is accepted, keep ownership on the LOT path until its
    // response is consumed, even if upstream sideband/address signals move.
    assign ram_command = data_read_line || data_read_word ||
                         data_write_line_ready || data_write_word_ready;
    assign route_lot = pending || (!ram_pending && class_route_lot && endpoint_offset_supported);
    assign reject_access = !pending && !ram_pending && (class_reject ||
                           (class_route_lot && !endpoint_offset_supported));
    // Hold RAM ownership after the command disappears. A line read has four
    // response beats; word reads and write-buffer acknowledgements have one.
    assign route_ram = ram_pending || (!pending && class_route_ram && !reject_access);

    // RAM path is preserved for cache-line fills/writebacks and ordinary words.
    assign ram_addr = data_addr;
    assign ram_read_line = data_read_line && route_ram;
    assign ram_read_word = data_read_word && route_ram;
    assign ram_write_line_ready = data_write_line_ready && route_ram;
    assign ram_write_word_ready = data_write_word_ready && route_ram;
    assign ram_write_word_be = route_ram ? data_write_word_be : 4'b0000;
    assign ram_data_out = data_out;

    // LOT payload follows the existing 65-bit {write, byte_address, write_data}
    // contract. Reads put zero in the write-data field.
    assign lot_dst = endpoint_dst;
    always_comb begin
        lot_payload = '0;
        lot_payload[64] = data_write_word_ready;
        lot_payload[63:32] = byte_addr;
        lot_payload[31:0] = data_write_word_ready ? data_out[31:0] : 32'b0;
    end

    // Send a request exactly once, then wait for its response. The cache holds
    // the source command stable because DataMem_Ready is withheld until completion.
    assign lot_valid = reset_n && !protocol_fault && route_lot && !pending;
    assign lot_rsp_ready = reset_n && pending;
    assign lot_response_fire = lot_rsp_valid && lot_rsp_ready;

    // OpenMIPS expects a one-cycle completion pulse, not a held ready/valid level.
    always_comb begin
        data_ready = 1'b0;
        data_in = ram_data_in;
        data_offset = ram_data_offset;

        if (route_lot && pending && lot_rsp_valid) begin
            data_ready = 1'b1;
            data_in = lot_rsp_rdata;
            data_offset = 2'b00;
        end else if (route_ram) begin
            data_ready = ram_ready;
        end
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            pending <= 1'b0;
            ram_pending <= 1'b0;
            ram_line_pending <= 1'b0;
            ram_line_beat_count <= 2'd0;
            protocol_fault <= 1'b0;
        end else begin
            if (reject_access)
                protocol_fault <= 1'b1;

            if (lot_valid && lot_ready)
                pending <= 1'b1;

            if (!ram_pending && !pending && class_route_ram && ram_command && !ram_ready) begin
                ram_pending <= 1'b1;
                ram_line_pending <= data_read_line;
                ram_line_beat_count <= 2'd0;
            end
            if (ram_pending && ram_ready) begin
                if (ram_line_pending && ram_line_beat_count != 2'd3) begin
                    ram_line_beat_count <= ram_line_beat_count + 2'd1;
                end else begin
                    ram_pending <= 1'b0;
                    ram_line_pending <= 1'b0;
                    ram_line_beat_count <= 2'd0;
                end
            end

            if (lot_response_fire) begin
                pending <= 1'b0;
                if (lot_rsp_error)
                    protocol_fault <= 1'b1;
            end
        end
    end

    // Guard against accidental use with wider physical address configurations.
    initial begin
        if (PABITS != 32)
            $error("openmips_lot_memory_bridge currently supports PABITS=32 only");
    end
endmodule
