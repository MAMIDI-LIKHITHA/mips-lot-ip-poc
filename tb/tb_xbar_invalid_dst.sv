`timescale 1ns/1ps
module tb_xbar_invalid_dst;

    localparam int N = 3;
    localparam int DATA_W = 32;
    localparam int DST_W = (N <= 1) ? 1 : $clog2(N);

    logic clk;
    logic rst_n;

    logic [N-1:0] in_valid;
    logic [N-1:0] in_ready;
    logic [N-1:0][DST_W-1:0] in_dst;
    logic [N-1:0][DATA_W-1:0] in_data;

    logic [N-1:0] out_valid;
    logic [N-1:0] out_ready;
    logic [N-1:0][DATA_W-1:0] out_data;
    logic [N-1:0][N-1:0] grant;

    xbar_4x4 #(
        .N(N),
        .DATA_W(DATA_W),
        .DST_W(DST_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .in_dst(in_dst),
        .in_data(in_data),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .out_data(out_data),
        .grant(grant)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        in_valid = '0;
        in_dst = '0;
        in_data = '0;
        out_ready = '1;

        #2;
        if (in_ready !== '0 || out_valid !== '0 || out_data !== '0)
            $fatal(1, "FAIL: outputs not quiescent during reset");

        rst_n = 1'b1;

        // N=3 gives DST_W=2, so value 3 is an explicitly invalid destination.
        in_valid[0] = 1'b1;
        in_dst[0] = 2'd3;
        in_data[0] = 32'hDEAD_0001;

        #1;
        if (in_ready[0] !== 1'b0)
            $fatal(1, "FAIL: invalid destination incorrectly reported ready");
        if (out_valid !== '0)
            $fatal(1, "FAIL: invalid destination generated output valid");
        if (grant !== '0)
            $fatal(1, "FAIL: invalid destination generated a grant");

        @(posedge clk);
        #1;
        if (in_ready[0] !== 1'b0 || out_valid !== '0)
            $fatal(1, "FAIL: invalid destination was transferred");

        // Replace invalid destination with a valid destination and confirm recovery.
        in_dst[0] = 2'd1;
        in_data[0] = 32'hBEEF_0002;

        #1;
        if (in_ready[0] !== 1'b1)
            $fatal(1, "FAIL: valid destination did not become ready");
        if (out_valid[1] !== 1'b1)
            $fatal(1, "FAIL: valid destination did not assert output valid");
        if (out_data[1] !== 32'hBEEF_0002)
            $fatal(1, "FAIL: valid destination data mismatch");

        @(posedge clk);
        #1;
        if (in_ready[0] !== 1'b1 || out_valid[1] !== 1'b1)
            $fatal(1, "FAIL: valid transfer did not remain available");

        $display("TB RESULT: PASS - invalid destination suppression and recovery to valid routing checks passed.");
        $finish;
    end

endmodule
