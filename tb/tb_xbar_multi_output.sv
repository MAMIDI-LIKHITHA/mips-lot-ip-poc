`timescale 1ns/1ps

module xbar_multi_output_case #(
    parameter int N = 4,
    parameter int DATA_W = 32,
    parameter int DST_W = (N <= 1) ? 1 : $clog2(N)
) (
    input logic clk,
    output logic done
);
    logic rst_n;
    logic [N-1:0] in_valid, in_ready;
    logic [N-1:0][DST_W-1:0] in_dst;
    logic [N-1:0][DATA_W-1:0] in_data;
    logic [N-1:0] out_valid, out_ready;
    logic [N-1:0][DATA_W-1:0] out_data;
    logic [N-1:0][N-1:0] grant;
    logic [N-1:0][DST_W-1:0] expected_dst;
    logic [N-1:0][DATA_W-1:0] expected_payload;

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
        expected_dst = '0;
        expected_payload = '0;

        for (int i = 0; i < N; i++) begin
            expected_dst[i] = DST_W'(i);
            expected_payload[i] = DATA_W'(32'hA500_0000 ^ (i * 32'h0101_0101));
        end

        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);
        in_dst = expected_dst;
        in_data = expected_payload;
        in_valid = '1;
        #1;

        if (out_valid !== {N{1'b1}})
            $fatal(1, "N=%0d: not all distinct outputs became valid", N);
        if (in_ready !== {N{1'b1}})
            $fatal(1, "N=%0d: not all inputs became ready", N);

        for (int i = 0; i < N; i++) begin
            int row_grants;
            int col_grants;
            row_grants = 0;
            col_grants = 0;
            if (out_data[i] !== expected_payload[i])
                $fatal(1, "N=%0d output %0d payload mismatch", N, i);
            for (int j = 0; j < N; j++) begin
                row_grants += grant[i][j];
                col_grants += grant[j][i];
            end
            if (row_grants != 1)
                $fatal(1, "N=%0d input %0d has %0d grants", N, i, row_grants);
            if (col_grants != 1)
                $fatal(1, "N=%0d output %0d has %0d grants", N, i, col_grants);
        end

        // Stall the highest-numbered output; other outputs must remain independent.
        out_ready[N-1] = 1'b0;
        #1;
        if (out_valid !== {N{1'b1}})
            $fatal(1, "N=%0d: VALID changed under partial backpressure", N);
        if (out_data[N-1] !== expected_payload[N-1])
            $fatal(1, "N=%0d: stalled payload changed", N);
        for (int i = 0; i < N; i++) begin
            if (in_ready[i] !== (i != N-1))
                $fatal(1, "N=%0d input %0d READY incorrect during stall", N, i);
            if (out_data[i] !== expected_payload[i])
                $fatal(1, "N=%0d output %0d changed during partial stall", N, i);
        end

        out_ready[N-1] = 1'b1;
        #1;
        if (out_valid !== {N{1'b1}} || in_ready !== {N{1'b1}})
            $fatal(1, "N=%0d: outputs did not recover after stall release", N);

        @(posedge clk);
        in_valid = '0;
        @(negedge clk);
        done = 1'b1;
    end
endmodule

module tb_xbar_multi_output;
    logic clk = 1'b0;
    logic done_n1, done_n3, done_n4, done_n5;
    always #5 clk = ~clk;

    xbar_multi_output_case #(.N(1), .DATA_W(8), .DST_W(1)) case_n1
        (.clk(clk), .done(done_n1));
    xbar_multi_output_case #(.N(3), .DATA_W(32), .DST_W(2)) case_n3
        (.clk(clk), .done(done_n3));
    xbar_multi_output_case #(.N(4), .DATA_W(32), .DST_W(2)) case_n4
        (.clk(clk), .done(done_n4));
    xbar_multi_output_case #(.N(5), .DATA_W(64), .DST_W(3)) case_n5
        (.clk(clk), .done(done_n5));

    initial begin
        wait (done_n1 && done_n3 && done_n4 && done_n5);
        $display("TB RESULT: PASS — multi-output routing/backpressure for N=1/3/4/5 and DATA_W=8/32/64");
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "multi-output parameter test timed out");
    end
endmodule
