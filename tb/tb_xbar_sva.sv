`timescale 1ns/1ps
module tb_xbar_sva;

    localparam int N = 4;
    localparam int DATA_W = 32;
    localparam int DST_W = 2;

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

    xbar_sva #(
        .N(N),
        .DATA_W(DATA_W)
    ) sva (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .grant(grant),
        .out_valid(out_valid),
        .out_ready(out_ready)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        in_valid = '0;
        in_dst = '0;
        in_data = '0;
        out_ready = '0;

        #2;
        if (in_ready !== '0 || out_valid !== '0 || out_data !== '0) begin
            $error("TB: reset did not quiesce crossbar");
            $finish;
        end

        #8;
        rst_n = 1'b1;
        out_ready[2] = 1'b1;
        in_valid[0] = 1'b1;
        in_dst[0] = 2'd2;
        in_data[0] = 32'hCAFE_0001;

        #10;
        if (out_valid[2] !== 1'b1 ||
            out_data[2] !== 32'hCAFE_0001 ||
            in_ready[0] !== 1'b1) begin
            $error("TB: normal SVA integration transfer failed");
            $finish;
        end

        in_valid = '0;
        in_dst[0] = 2'd3;
        in_dst[1] = 2'd3;
        in_data[0] = 32'h1111_0000;
        in_data[1] = 32'h2222_0000;
        in_valid[0] = 1'b1;
        in_valid[1] = 1'b1;
        out_ready = '0;
        out_ready[3] = 1'b1;

        #10;
        if (out_valid[3] !== 1'b1 ||
            (in_ready[0] + in_ready[1]) !== 1) begin
            $error("TB: contention arbitration/SVA integration failed");
            $finish;
        end

        in_valid = '0;
        out_ready = '0;
        in_valid[2] = 1'b1;
        in_dst[2] = 2'd1;
        in_data[2] = 32'hBEEF_0002;

        #10;
        if (out_valid[1] !== 1'b0 || in_ready[2] !== 1'b0) begin
            $error("TB: backpressure behavior failed");
            $finish;
        end

        out_ready[1] = 1'b1;
        #10;
        if (out_valid[1] !== 1'b1 ||
            out_data[1] !== 32'hBEEF_0002 ||
            in_ready[2] !== 1'b1) begin
            $error("TB: backpressure recovery failed");
            $finish;
        end

        rst_n = 1'b0;
        #2;
        if (in_ready !== '0 || out_valid !== '0 || out_data !== '0) begin
            $error("TB: reset-time traffic was not suppressed");
            $finish;
        end

        $display("TB RESULT: PASS - SVA integration exercised reset, routing, contention and backpressure with no assertion failures.");
        $finish;
    end

endmodule
