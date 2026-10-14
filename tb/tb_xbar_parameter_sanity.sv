`timescale 1ns/1ps
module xbar_parameter_case #(
    parameter int N = 2,
    parameter int DATA_W = 8,
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
    logic [DATA_W-1:0] expected_data;

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
        expected_data = DATA_W'('h5A);
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        in_dst[0] = DST_W'(N-1);
        in_data[0] = expected_data;
        in_valid = {{(N-1){1'b0}}, 1'b1};
        #1;
        if (!out_valid[N-1])
            $fatal(1, "N=%0d DATA_W=%0d: selected output not valid", N, DATA_W);
        if (out_data[N-1] !== expected_data)
            $fatal(1, "N=%0d DATA_W=%0d: payload mismatch", N, DATA_W);
        if (!in_ready[0] || !grant[0][N-1])
            $fatal(1, "N=%0d DATA_W=%0d: handshake/grant missing", N, DATA_W);
        in_valid = '0;
        #1;
        done = 1'b1;
    end
endmodule

module tb_xbar_parameter_sanity;
    logic clk = 1'b0;
    logic done_n1_w8, done_n2_w8, done_n2_w64, done_n3_w16;
    logic done_n3_w32, done_n4_w32, done_n5_w32, done_n5_w64;
    always #5 clk = ~clk;

    xbar_parameter_case #(.N(1), .DATA_W(8), .DST_W(1)) case_n1_w8
        (.clk(clk), .done(done_n1_w8));
    xbar_parameter_case #(.N(2), .DATA_W(8), .DST_W(1)) case_n2_w8
        (.clk(clk), .done(done_n2_w8));
    xbar_parameter_case #(.N(2), .DATA_W(64), .DST_W(1)) case_n2_w64
        (.clk(clk), .done(done_n2_w64));
    xbar_parameter_case #(.N(3), .DATA_W(16), .DST_W(2)) case_n3_w16
        (.clk(clk), .done(done_n3_w16));
    xbar_parameter_case #(.N(3), .DATA_W(32), .DST_W(2)) case_n3_w32
        (.clk(clk), .done(done_n3_w32));
    xbar_parameter_case #(.N(4), .DATA_W(32), .DST_W(2)) case_n4_w32
        (.clk(clk), .done(done_n4_w32));
    xbar_parameter_case #(.N(5), .DATA_W(32), .DST_W(3)) case_n5_w32
        (.clk(clk), .done(done_n5_w32));
    xbar_parameter_case #(.N(5), .DATA_W(64), .DST_W(3)) case_n5_w64
        (.clk(clk), .done(done_n5_w64));

    initial begin
        wait (done_n1_w8 && done_n2_w8 && done_n2_w64 && done_n3_w16 &&
              done_n3_w32 && done_n4_w32 && done_n5_w32 && done_n5_w64);
        $display("TB RESULT: PASS — 8 parameter combinations across N=1/2/3/4/5 and DATA_W=8/16/32/64");
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "parameter sanity test timed out");
    end
endmodule
