// OpenMIPS LOT access classifier candidate.
// This is a boundary/classification block, NOT a complete native OpenMIPS
// memory-port bridge. Cycle-level Ready_M/Ready_C behavior must be validated
// against the selected core before this is connected to a processor.
module openmips_lot_access_classifier #(
    parameter logic [31:0] LOT_BASE = 32'h1F00_0000,
    parameter logic [31:0] LOT_MASK = 32'hFFFF_F000,
    parameter logic [2:0]  UNCACHEABLE_ATTR = 3'b010
) (
    input  logic        paddr_valid,
    input  logic [31:0] byte_addr,
    input  logic [2:0]  cache_attr,

    input  logic        read_word,
    input  logic        write_word,
    input  logic [3:0]  write_word_be,
    input  logic        read_line,
    input  logic        write_line,

    output logic        route_lot,
    output logic        route_ram,
    output logic        reject_access,
    output logic        is_lot_window
);
    logic any_word;
    logic any_line;
    logic in_window;

    always_comb begin
        any_word = read_word || write_word || (|write_word_be);
        any_line = read_line || write_line;
        in_window = ((byte_addr & LOT_MASK) == (LOT_BASE & LOT_MASK));

        is_lot_window = in_window;
        route_lot = 1'b0;
        route_ram = 1'b0;
        reject_access = 1'b0;

        // Line transfers are always RAM traffic. They are never converted to
        // a single LOT word, even if their address overlaps the test window.
        if (any_line) begin
            // Simultaneous line and word commands are an invalid combination;
            // do not route either side effect when the command bundle is bad.
            if (any_word) begin
                reject_access = 1'b1;
            end else begin
                route_ram = 1'b1;
            end
        end else if (read_word && write_word) begin
            reject_access = 1'b1;
        end else if (any_word) begin
            if (!paddr_valid) begin
                reject_access = 1'b1;
            end else if (in_window) begin
                // An address hit alone is insufficient: the translation/cache
                // path must mark the transaction uncacheable.
                if (cache_attr != UNCACHEABLE_ATTR) begin
                    reject_access = 1'b1;
                end else if (byte_addr[1:0] != 2'b00) begin
                    reject_access = 1'b1;
                end else if (write_word && (write_word_be != 4'b1111)) begin
                    // LOT contract has no byte enables; never silently drop
                    // partial-write information.
                    reject_access = 1'b1;
                end else begin
                    route_lot = 1'b1;
                end
            end else begin
                route_ram = 1'b1;
            end
        end
    end
endmodule
