`timescale 1ns/1ps
module xbar_invalid_dst_case #(
    parameter int N = 3,
    parameter int DATA_W = 32,
    parameter int DST_W = (N <= 1) ? 1 : $clog2(N)
) (
    input logic clk,
    output logic done
);
    logic rst_n;
    logic [N-1:0] in_valid, in_ready, out_valid, out_ready;
    logic [N-1:0][DST_W-1:0] in_dst;
    logic [N-1:0][DATA_W-1:0] in_data, out_data;
    logic [N-1:0][N-1:0] grant;
    logic [DST_W-1:0] invalid_dst;

    xbar_4x4 #(.N(N), .DATA_W(DATA_W), .DST_W(DST_W)) dut (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_ready(in_ready),
        .in_dst(in_dst), .in_data(in_data),
        .out_valid(out_valid), .out_ready(out_ready),
        .out_data(out_data), .grant(grant)
    );

    initial begin
        done = 1'b0;
        rst_n = 1'b0;
        in_valid = '0;
        in_dst = '0;
        in_data = '0;
        out_ready = '1;
        invalid_dst = DST_W'(N);
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        in_valid[0] = 1'b1;
        in_dst[0] = invalid_dst;
        in_data[0] = DATA_W'('hDEAD);
        #1;
        if (in_ready[0] !== 1'b0 || out_valid !== '0 || grant !== '0)
            $fatal(1, "N=%0d: invalid destination was not suppressed", N);

        @(posedge clk);
        #1;
        if (in_ready[0] !== 1'b0 || out_valid !== '0 || grant !== '0)
            $fatal(1, "N=%0d: invalid destination transferred", N);

        in_dst[0] = DST_W'(N-1);
        in_data[0] = DATA_W'('hBEEF);
        #1;
        if (in_ready[0] !== 1'b1 || !out_valid[N-1] ||
            out_data[N-1] !== DATA_W'('hBEEF) || !grant[0][N-1])
            $fatal(1, "N=%0d: valid routing did not recover after invalid destination", N);

        done = 1'b1;
    end
endmodule

module tb_xbar_invalid_dst;
    logic clk = 1'b0;
    logic done_n1, done_n3, done_n5;
    always #5 clk = ~clk;

    xbar_invalid_dst_case #(.N(1), .DATA_W(8), .DST_W(1)) case_n1
        (.clk(clk), .done(done_n1));
    xbar_invalid_dst_case #(.N(3), .DATA_W(32), .DST_W(2)) case_n3
        (.clk(clk), .done(done_n3));
    xbar_invalid_dst_case #(.N(5), .DATA_W(64), .DST_W(3)) case_n5
        (.clk(clk), .done(done_n5));

    initial begin
        wait (done_n1 && done_n3 && done_n5);
        $display("TB RESULT: PASS - invalid destination suppression/recovery for N=1/3/5");
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "invalid destination parameter test timed out");
    end
endmodule
