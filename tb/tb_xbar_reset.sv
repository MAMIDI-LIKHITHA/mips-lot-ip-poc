`timescale 1ns/1ps
module xbar_reset_case #(
    parameter int N = 4,
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

    xbar_4x4 #(.N(N), .DATA_W(DATA_W), .DST_W(DST_W)) dut (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_ready(in_ready),
        .in_dst(in_dst), .in_data(in_data),
        .out_valid(out_valid), .out_ready(out_ready),
        .out_data(out_data), .grant(grant)
    );

    task automatic clear_inputs;
        begin
            in_valid = '0;
            in_dst = '0;
            in_data = '0;
            out_ready = '0;
        end
    endtask

    initial begin
        done = 1'b0;
        clear_inputs();
        rst_n = 1'b0;
        #2;
        if (in_ready !== '0 || out_valid !== '0 || out_data !== '0)
            $fatal(1, "N=%0d: outputs not quiescent during reset", N);

        // Present traffic while reset remains asserted.
        in_valid[0] = 1'b1;
        in_dst[0] = DST_W'(N-1);
        in_data[0] = DATA_W'('hCAFE);
        out_ready[N-1] = 1'b1;
        @(posedge clk);
        #1;
        if (in_ready !== '0 || out_valid !== '0)
            $fatal(1, "N=%0d: traffic transferred during reset", N);

        // Release reset and verify the same request can route.
        rst_n = 1'b1;
        #1;
        if (!out_valid[N-1] || !in_ready[0] ||
            out_data[N-1] !== DATA_W'('hCAFE))
            $fatal(1, "N=%0d: traffic failed to resume after reset", N);

        clear_inputs();
        rst_n = 1'b0;
        #2;
        if (in_ready !== '0 || out_valid !== '0 || out_data !== '0)
            $fatal(1, "N=%0d: outputs not quiescent after reset reassertion", N);

        rst_n = 1'b1;
        in_valid[N-1] = 1'b1;
        in_dst[N-1] = '0;
        in_data[N-1] = DATA_W'('hBEEF);
        out_ready[0] = 1'b1;
        #1;
        if (!out_valid[0] || !in_ready[N-1] ||
            out_data[0] !== DATA_W'('hBEEF))
            $fatal(1, "N=%0d: traffic failed after repeated reset", N);

        done = 1'b1;
    end
endmodule

module tb_xbar_reset;
    logic clk = 1'b0;
    logic done_n1, done_n3, done_n5;
    always #5 clk = ~clk;

    xbar_reset_case #(.N(1), .DATA_W(8), .DST_W(1)) case_n1
        (.clk(clk), .done(done_n1));
    xbar_reset_case #(.N(3), .DATA_W(32), .DST_W(2)) case_n3
        (.clk(clk), .done(done_n3));
    xbar_reset_case #(.N(5), .DATA_W(64), .DST_W(3)) case_n5
        (.clk(clk), .done(done_n5));

    initial begin
        wait (done_n1 && done_n3 && done_n5);
        $display("TB RESULT: PASS - reset suppression/recovery for N=1/3/5");
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "crossbar reset parameter test timed out");
    end
endmodule
