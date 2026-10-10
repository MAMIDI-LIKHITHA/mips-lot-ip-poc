`timescale 1ns/1ps
module tb_xbar_backpressure_stability;

    localparam int N = 4;
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

    logic [DATA_W-1:0] held_data;
    logic held_valid;

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        in_valid = '0;
        in_dst = '0;
        in_data = '0;
        out_ready = '0;
        held_data = '0;
        held_valid = 1'b0;

        #2;
        rst_n = 1'b1;

        // Drive one request toward destination 2 while the destination is stalled.
        in_valid[0] = 1'b1;
        in_dst[0] = 2'd2;
        in_data[0] = 32'hCAFE_1234;
        out_ready[2] = 1'b0;

        #1;
        if (out_valid[2] !== 1'b1)
            $fatal(1, "FAIL: out_valid must remain asserted during backpressure");
        if (out_data[2] !== 32'hCAFE_1234)
            $fatal(1, "FAIL: stalled output data mismatch");

        if (in_ready[0] !== 1'b0)
            $fatal(1, "FAIL: source reported ready while destination was stalled");

        // Hold the request and destination stall for several cycles.
        repeat (3) begin
            @(posedge clk);
            #1;
            if (out_valid[2] !== 1'b1 || out_data[2] !== 32'hCAFE_1234)
                $fatal(1, "FAIL: VALID/data did not remain stable during sustained backpressure");

            if (in_ready[0] !== 1'b0)
                $fatal(1, "FAIL: in_ready asserted during sustained backpressure");
        end

        // Release the destination. The request should now become transferable.
        out_ready[2] = 1'b1;
        #1;

        if (out_valid[2] !== 1'b1)
            $fatal(1, "FAIL: out_valid did not assert after backpressure release");

        if (out_data[2] !== 32'hCAFE_1234)
            $fatal(1, "FAIL: output data changed while request was held");

        if (in_ready[0] !== 1'b1)
            $fatal(1, "FAIL: source did not become ready after backpressure release");

        // Capture the visible transfer and verify it remains stable through the
        // transfer edge while VALID and READY are both asserted.
        held_data = out_data[2];
        held_valid = out_valid[2];

        @(posedge clk);
        #1;

        if (held_valid !== 1'b1 || held_data !== 32'hCAFE_1234)
            $fatal(1, "FAIL: transfer observation was not stable");

        // Stop the source and confirm the output returns to idle.
        in_valid[0] = 1'b0;
        #1;

        if (out_valid !== '0)
            $fatal(1, "FAIL: output valid did not clear after source deassertion");

        if (in_ready !== '0)
            $fatal(1, "FAIL: input ready did not clear after source deassertion");

        $display("TB RESULT: PASS - sustained backpressure, persistent VALID, stable data and recovery checks passed.");
        $finish;
    end

endmodule
