`timescale 1ns/1ps
module tb_xbar_reset;

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

    always #5 clk = ~clk;

    task automatic clear_inputs;
        begin
            in_valid = '0;
            in_dst   = '0;
            in_data  = '0;
            out_ready = '0;
        end
    endtask

    initial begin
        clk = 1'b0;
        clear_inputs();
        rst_n = 1'b0;

        // Reset must suppress all externally visible transfers.
        #2;
        if (in_ready !== '0 || out_valid !== '0 || out_data !== '0) begin
            $display("FAIL: outputs were not quiescent while reset was asserted");
            $finish;
        end

        // Assert reset across a clock edge while presenting traffic.
        in_valid[0] = 1'b1;
        in_dst[0]   = 2'd2;
        in_data[0]  = 32'hCAFE_0001;
        out_ready[2] = 1'b1;

        @(posedge clk);
        #1;
        if (in_ready !== '0 || out_valid !== '0) begin
            $display("FAIL: traffic transferred while reset was asserted");
            $finish;
        end

        // Release reset and verify normal traffic resumes.
        rst_n = 1'b1;
        @(posedge clk);
        #1;

        if (out_valid[2] !== 1'b1 ||
            in_ready[0] !== 1'b1 ||
            out_data[2] !== 32'hCAFE_0001) begin
            $display("FAIL: traffic did not resume correctly after reset");
            $finish;
        end

        // Remove traffic and reassert reset; outputs must return to quiescent.
        clear_inputs();
        rst_n = 1'b0;
        #2;

        if (in_ready !== '0 || out_valid !== '0 || out_data !== '0) begin
            $display("FAIL: outputs were not cleared after reset reassertion");
            $finish;
        end

        // Release reset again and verify the crossbar can operate normally.
        rst_n = 1'b1;
        in_valid[3] = 1'b1;
        in_dst[3]   = 2'd1;
        in_data[3]  = 32'hBEEF_0002;
        out_ready[1] = 1'b1;

        @(posedge clk);
        #1;

        if (out_valid[1] !== 1'b1 ||
            in_ready[3] !== 1'b1 ||
            out_data[1] !== 32'hBEEF_0002) begin
            $display("FAIL: traffic did not recover after second reset");
            $finish;
        end

        $display("TB RESULT: PASS - reset quiescence, reset-time traffic suppression, post-reset recovery and repeated reset behavior checks passed.");
        $finish;
    end

endmodule
