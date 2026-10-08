`timescale 1ns/1ps
module tb_xbar_multi_output;

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

    task automatic clear_inputs;
        integer k;
        begin
            for (k = 0; k < N; k = k + 1) begin
                in_valid[k] = 1'b0;
                in_dst[k] = '0;
                in_data[k] = '0;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        out_ready = '1;
        clear_inputs();

        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        // Four simultaneous requests target four different outputs.
        in_valid[0] = 1'b1;
        in_dst[0] = 2'd0;
        in_data[0] = 32'hA000_0000;

        in_valid[1] = 1'b1;
        in_dst[1] = 2'd1;
        in_data[1] = 32'hA111_1111;

        in_valid[2] = 1'b1;
        in_dst[2] = 2'd2;
        in_data[2] = 32'hA222_2222;

        in_valid[3] = 1'b1;
        in_dst[3] = 2'd3;
        in_data[3] = 32'hA333_3333;

        #1;

        if (out_valid !== 4'b1111)
            $fatal(1, "FAIL: expected all four outputs valid");

        if (in_ready !== 4'b1111)
            $fatal(1, "FAIL: expected all four inputs ready");

        if (out_data[0] !== 32'hA000_0000 ||
            out_data[1] !== 32'hA111_1111 ||
            out_data[2] !== 32'hA222_2222 ||
            out_data[3] !== 32'hA333_3333)
            $fatal(1, "FAIL: simultaneous multi-output data mismatch");

        // Exactly one grant per active input and exactly one winner per output.
        for (int i = 0; i < N; i = i + 1) begin
            int row_grants;
            int col_grants;
            row_grants = 0;
            col_grants = 0;

            for (int j = 0; j < N; j = j + 1) begin
                row_grants += grant[i][j];
                col_grants += grant[j][i];
            end

            if (row_grants != 1)
                $fatal(1, "FAIL: input %0d has %0d grants", i, row_grants);

            if (col_grants != 1)
                $fatal(1, "FAIL: output %0d has %0d grants", i, col_grants);
        end

        // Stall output 2 while the other three remain ready.
        out_ready[2] = 1'b0;
        #1;

        if (out_valid[0] !== 1'b1 ||
            out_valid[1] !== 1'b1 ||
            out_valid[2] !== 1'b0 ||
            out_valid[3] !== 1'b1)
            $fatal(1, "FAIL: independent outputs were not preserved under partial backpressure");

        if (in_ready[0] !== 1'b1 ||
            in_ready[1] !== 1'b1 ||
            in_ready[2] !== 1'b0 ||
            in_ready[3] !== 1'b1)
            $fatal(1, "FAIL: ready signals incorrect under partial backpressure");

        if (out_data[0] !== 32'hA000_0000 ||
            out_data[1] !== 32'hA111_1111 ||
            out_data[3] !== 32'hA333_3333)
            $fatal(1, "FAIL: independent output data changed under partial backpressure");

        // Release output 2 and verify all four transfers recover.
        out_ready[2] = 1'b1;
        #1;

        if (out_valid !== 4'b1111 || in_ready !== 4'b1111)
            $fatal(1, "FAIL: all outputs did not recover after backpressure release");

        if (out_data[2] !== 32'hA222_2222)
            $fatal(1, "FAIL: output 2 data mismatch after recovery");

        @(posedge clk);
        clear_inputs();
        @(posedge clk);

        $display("TB RESULT: PASS - simultaneous multi-output routing, one-to-one grants, partial backpressure and recovery checks passed.");
        $finish;
    end

endmodule
