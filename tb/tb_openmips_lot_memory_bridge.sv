`timescale 1ns/1ps
module tb_openmips_lot_memory_bridge;
    logic clk, reset_n;
    logic [29:0] data_addr;
    logic data_read_line, data_read_word;
    logic data_write_line_ready, data_write_word_ready;
    logic [3:0] data_write_word_be;
    logic [127:0] data_out;
    logic data_paddr_valid;
    logic [2:0] data_cache_attr;
    logic [31:0] data_in;
    logic [1:0] data_offset;
    logic data_ready;
    logic [29:0] ram_addr;
    logic ram_read_line, ram_read_word;
    logic ram_write_line_ready, ram_write_word_ready;
    logic [3:0] ram_write_word_be;
    logic [127:0] ram_data_out;
    logic [31:0] ram_data_in;
    logic [1:0] ram_data_offset;
    logic ram_ready;
    logic lot_valid, lot_ready;
    logic [1:0] lot_dst;
    logic [64:0] lot_payload;
    logic lot_rsp_valid, lot_rsp_ready;
    logic [31:0] lot_rsp_rdata;
    logic lot_rsp_error;
    logic protocol_fault;

    openmips_lot_memory_bridge dut (.*);
    always #5 clk = ~clk;

    task automatic clear_commands;
        begin
            data_read_line = 0;
            data_read_word = 0;
            data_write_line_ready = 0;
            data_write_word_ready = 0;
            data_write_word_be = 0;
            data_out = 0;
            data_addr = 0;
            data_paddr_valid = 1;
            data_cache_attr = 3'b010;
            ram_data_in = 32'hCAFE_BABE;
            ram_data_offset = 2'd2;
            ram_ready = 0;
            lot_ready = 0;
            lot_rsp_valid = 0;
            lot_rsp_rdata = 0;
            lot_rsp_error = 0;
        end
    endtask

    task automatic check_expectation(input logic condition_i, input string message_i);
        if (!condition_i) $fatal(1, "%s", message_i);
        $display("PASS: %s", message_i);
    endtask

    initial begin
        clk = 0;
        reset_n = 0;
        clear_commands();
        repeat (2) @(posedge clk);
        #1 reset_n = 1;
        @(negedge clk);

        // 1: Qualified LOT read, endpoint CONTROL.
        data_addr = 30'h1F00_0000 >> 2;
        data_read_word = 1;
        #1;
        check_expectation(lot_valid && lot_dst == 0 && !ram_read_word,
               "qualified LOT read issues one request and suppresses RAM");
        check_expectation(lot_payload == {1'b0,32'h1F00_0000,32'b0},
               "LOT read payload uses byte address and zero write data");
        lot_ready = 1;
        @(posedge clk); #1;
        lot_ready = 0;
        check_expectation(!lot_valid && lot_rsp_ready,
               "accepted LOT request waits for response without reissuing");
        // Mutate upstream request inputs while the bridge owns the outstanding
        // LOT transaction; the response must not accidentally switch to RAM.
        data_addr = 30'h0000_3000 >> 2;
        data_read_word = 0;
        ram_ready = 1;
        #1;
        check_expectation(!ram_read_word && !data_ready,
               "outstanding LOT transaction retains path ownership");
        lot_rsp_rdata = 32'h1234_5678;
        lot_rsp_valid = 1;
        #1;
        check_expectation(data_ready && data_in == 32'h1234_5678 && lot_rsp_ready,
               "LOT read response produces cache completion pulse and data");
        @(posedge clk); #1;
        lot_rsp_valid = 0;
        data_read_word = 0;
        check_expectation(!data_ready && !lot_rsp_ready,
               "LOT read completion is a pulse and clears outstanding state");

        // 2: Qualified full-word write to DATA endpoint.
        @(negedge clk);
        data_addr = 30'h1F00_0004 >> 2;
        data_write_word_ready = 1;
        data_write_word_be = 4'b1111;
        data_out[31:0] = 32'hA55A_1234;
        #1;
        check_expectation(lot_valid && lot_dst == 1 && lot_payload[64] &&
               lot_payload[31:0] == 32'hA55A_1234 && !ram_write_word_ready,
               "full-word LOT write is routed to DATA endpoint");
        lot_ready = 1;
        @(posedge clk); #1;
        lot_ready = 0;
        lot_rsp_rdata = 0;
        lot_rsp_error = 0;
        lot_rsp_valid = 1;
        #1;
        check_expectation(data_ready && lot_rsp_ready,
               "LOT write dequeues write-buffer entry only on response");
        @(posedge clk); #1;
        lot_rsp_valid = 0;
        data_write_word_ready = 0;
        data_write_word_be = 0;

        // 3: Cache-line read is never sent to LOT.
        @(negedge clk);
        data_addr = 30'h0000_1000 >> 2;
        data_read_line = 1;
        ram_ready = 1;
        #1;
        check_expectation(ram_read_line && !lot_valid && data_ready &&
               data_in == 32'hCAFE_BABE && data_offset == 2,
               "cache-line read command and response stay on RAM path");
        data_read_line = 0;
        ram_ready = 0;

        // 4: Cache-line write stays on RAM path, with full payload intact.
        @(negedge clk);
        data_addr = 30'h0000_2000 >> 2;
        data_write_line_ready = 1;
        data_out = 128'h0123_4567_89AB_CDEF_FEDC_BA98_7654_3210;
        ram_ready = 1;
        #1;
        check_expectation(ram_write_line_ready && !lot_valid &&
               ram_data_out == data_out && data_ready,
               "cache-line write and 128-bit payload stay on RAM path");
        data_write_line_ready = 0;
        ram_ready = 0;

        // 5: Ordinary word read remains RAM.
        @(negedge clk);
        data_addr = 30'h0000_3000 >> 2;
        data_read_word = 1;
        ram_ready = 1;
        #1;
        check_expectation(ram_read_word && !lot_valid && data_ready,
               "ordinary word read remains on RAM path");
        data_read_word = 0;
        ram_ready = 0;

        // 6: The aperture does not alias unimplemented register offsets.
        @(negedge clk);
        data_addr = 30'h1F00_0010 >> 2;
        data_read_word = 1;
        data_cache_attr = 3'b010;
        #1;
        check_expectation(!lot_valid && !ram_read_word && !data_ready,
               "unmapped offset inside LOT aperture is rejected");
        @(posedge clk); #1;
        check_expectation(protocol_fault, "unmapped LOT offset sets sticky fault");
        data_read_word = 0;

        // Reset clears the diagnostic fault before the next independent case.
        @(negedge clk);
        reset_n = 0;
        @(posedge clk); #1;
        check_expectation(!protocol_fault, "reset clears sticky protocol fault");
        @(negedge clk);
        reset_n = 1;

        // 7: Qualification mismatch is fail-stop and reported.
        @(negedge clk);
        data_addr = 30'h1F00_0000 >> 2;
        data_read_word = 1;
        data_cache_attr = 3'b011;
        #1;
        check_expectation(!lot_valid && !ram_read_word && !data_ready,
               "cacheable access to LOT window is blocked, not misrouted");
        @(posedge clk); #1;
        check_expectation(protocol_fault, "invalid LOT qualification sets sticky fault");
        data_read_word = 0;

        $display("TB RESULT: PASS - OpenMIPS LOT memory bridge");
        $finish;
    end
endmodule
