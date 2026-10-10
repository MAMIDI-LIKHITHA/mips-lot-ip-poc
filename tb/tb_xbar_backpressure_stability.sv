`timescale 1ns/1ps
module tb_xbar_backpressure_stability;

    localparam int N = 4;
    localparam int DATA_W = 32;
    localparam int DST_W = 2;

    logic clk, rst_n;
    logic [N-1:0] in_valid, in_ready;
    logic [N-1:0][DST_W-1:0] in_dst;
    logic [N-1:0][DATA_W-1:0] in_data;
    logic [N-1:0] out_valid, out_ready;
    logic [N-1:0][DATA_W-1:0] out_data;
    logic [N-1:0][N-1:0] grant;

    xbar_4x4 #(.N(N), .DATA_W(DATA_W), .DST_W(DST_W)) dut (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_ready(in_ready),
        .in_dst(in_dst), .in_data(in_data),
        .out_valid(out_valid), .out_ready(out_ready),
        .out_data(out_data), .grant(grant)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        in_valid = '0;
        in_dst = '0;
        in_data = '0;
        out_ready = '0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        // Two contenders target output 2. Keep the output stalled and ensure
        // the first winner and its payload remain visible without pointer advance.
        in_valid[0] = 1'b1;
        in_valid[1] = 1'b1;
        in_dst[0] = 2'd2;
        in_dst[1] = 2'd2;
        in_data[0] = 32'hCAFE_1234;
        in_data[1] = 32'hBEEF_5678;
        out_ready[2] = 1'b0;

        #1;
        if (out_valid[2] !== 1'b1 || out_data[2] !== 32'hCAFE_1234)
            $fatal(1, "FAIL: selected VALID/data not presented during backpressure");
        if (in_ready[0] !== 1'b0 || in_ready[1] !== 1'b0)
            $fatal(1, "FAIL: source READY asserted while output stalled");

        repeat (3) begin
            @(posedge clk);
            #1;
            if (out_valid[2] !== 1'b1 || out_data[2] !== 32'hCAFE_1234)
                $fatal(1, "FAIL: selected VALID/data changed during sustained backpressure");
            if (in_ready[0] !== 1'b0 || in_ready[1] !== 1'b0)
                $fatal(1, "FAIL: source READY asserted during sustained backpressure");
        end

        // Release READY: input 0 completes a transfer at the next active edge.
        @(negedge clk);
        out_ready[2] = 1'b1;
        #1;
        if (out_valid[2] !== 1'b1 || in_ready[0] !== 1'b1 ||
            out_data[2] !== 32'hCAFE_1234)
            $fatal(1, "FAIL: first transfer did not recover correctly");

        @(posedge clk);
        #1;
        in_valid[0] = 1'b0;

        // Pointer must advance after the successful handshake; input 1 wins next.
        #1;
        if (out_valid[2] !== 1'b1 || in_ready[1] !== 1'b1 ||
            out_data[2] !== 32'hBEEF_5678)
            $fatal(1, "FAIL: round-robin pointer did not advance after completed handshake");

        @(posedge clk);
        #1;
        in_valid[1] = 1'b0;
        #1;
        if (out_valid !== '0 || in_ready !== '0)
            $fatal(1, "FAIL: output did not return to idle after both transfers");

        $display("TB RESULT: PASS - VALID/data stability during backpressure, pointer hold while stalled, handshake recovery and round-robin advance verified.");
        $finish;
    end

endmodule
