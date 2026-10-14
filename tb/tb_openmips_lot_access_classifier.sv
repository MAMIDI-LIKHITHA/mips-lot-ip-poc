`timescale 1ns/1ps
module tb_openmips_lot_access_classifier;
    logic paddr_valid;
    logic [31:0] byte_addr;
    logic [2:0] cache_attr;
    logic read_word;
    logic [3:0] write_word_be;
    logic read_line, write_line;
    logic route_lot, route_ram, reject_access, is_lot_window;

    openmips_lot_access_classifier dut (.*);

    task automatic check(
        input logic exp_lot,
        input logic exp_ram,
        input logic exp_reject,
        input string label_i
    );
        #1;
        if (route_lot !== exp_lot ||
            route_ram !== exp_ram ||
            reject_access !== exp_reject) begin
            $error("%s: got lot=%b ram=%b reject=%b",
                   label_i, route_lot, route_ram, reject_access);
            $fatal(1, "classification mismatch");
        end
        $display("PASS: %s", label_i);
    endtask

    initial begin
        paddr_valid = 1;
        byte_addr = 32'h1F00_0000;
        cache_attr = 3'b010;
        read_word = 1;
        write_word_be = 0;
        read_line = 0;
        write_line = 0;
        check(1, 0, 0, "qualified uncacheable LOT word read");

        read_word = 0;
        write_word_be = 4'b1111;
        check(1, 0, 0, "qualified full-word LOT write");

        write_word_be = 4'b0011;
        check(0, 0, 1, "partial LOT write rejected");

        write_word_be = 0;
        read_word = 1;
        byte_addr = 32'h1F00_0002;
        check(0, 0, 1, "misaligned LOT word rejected");

        byte_addr = 32'h1F00_0000;
        cache_attr = 3'b011;
        check(0, 0, 1, "cacheable access to LOT window rejected");

        cache_attr = 3'b010;
        paddr_valid = 0;
        check(0, 0, 1, "invalid physical address rejected");

        paddr_valid = 1;
        byte_addr = 32'h0000_1000;
        check(0, 1, 0, "ordinary uncacheable word routes to RAM");

        read_word = 0;
        write_word_be = 0;
        read_line = 1;
        byte_addr = 32'h1F00_0000;
        check(0, 1, 0, "cache-line read always routes to RAM");

        read_line = 0;
        write_line = 1;
        check(0, 1, 0, "cache-line write always routes to RAM");

        write_line = 0;
        read_line = 0;
        read_word = 1;
        write_word_be = 4'b1111;
        check(0, 0, 1, "conflicting word and line commands rejected");

        $display("TB RESULT: PASS - OpenMIPS LOT access classification");
        $finish;
    end
endmodule
