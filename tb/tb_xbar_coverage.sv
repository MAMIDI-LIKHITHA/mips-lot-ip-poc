`timescale 1ns/1ps
module tb_xbar_coverage;

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

    xbar_coverage #(
        .N(N),
        .DATA_W(DATA_W),
        .DST_W(DST_W)
    ) cov (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .in_dst(in_dst),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .grant(grant)
    );

    always #5 clk = ~clk;

    task automatic check_route(
        input integer src,
        input integer dst,
        input logic [DATA_W-1:0] data
    );
        begin
            in_valid = '0;
            out_ready = '0;
            in_valid[src] = 1'b1;
            in_dst[src] = dst[DST_W-1:0];
            in_data[src] = data;
            out_ready[dst] = 1'b1;
            #10;
            if (out_valid[dst] !== 1'b1 ||
                out_data[dst] !== data ||
                in_ready[src] !== 1'b1) begin
                $error("TB: route failed src=%0d dst=%0d", src, dst);
                $finish;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        in_valid = '0;
        in_dst = '0;
        in_data = '0;
        out_ready = '0;

        // Hold reset through at least one rising clock edge so the
        // coverage tracker can record the reset-asserted bin.
        #7;
        if (in_ready !== '0 || out_valid !== '0 || out_data !== '0) begin
            $error("TB: reset did not quiesce crossbar");
            $finish;
        end

        rst_n = 1'b1;

        // All 16 legal source -> destination routes.
        check_route(0, 0, 32'hA000_0000);
        check_route(0, 1, 32'hA000_0001);
        check_route(0, 2, 32'hA000_0002);
        check_route(0, 3, 32'hA000_0003);
        check_route(1, 0, 32'hA111_0000);
        check_route(1, 1, 32'hA111_0001);
        check_route(1, 2, 32'hA111_0002);
        check_route(1, 3, 32'hA111_0003);
        check_route(2, 0, 32'hA222_0000);
        check_route(2, 1, 32'hA222_0001);
        check_route(2, 2, 32'hA222_0002);
        check_route(2, 3, 32'hA222_0003);
        check_route(3, 0, 32'hA333_0000);
        check_route(3, 1, 32'hA333_0001);
        check_route(3, 2, 32'hA333_0002);
        check_route(3, 3, 32'hA333_0003);

        // Two-input contention.
        in_valid = '0;
        out_ready = '0;
        in_valid[0] = 1'b1;
        in_valid[1] = 1'b1;
        in_dst[0] = 2'd3;
        in_dst[1] = 2'd3;
        in_data[0] = 32'h1111_0000;
        in_data[1] = 32'h2222_0000;
        out_ready[3] = 1'b1;
        #10;
        if (out_valid[3] !== 1'b1 ||
            (in_ready[0] + in_ready[1]) !== 1) begin
            $error("TB: contention scenario failed");
            $finish;
        end

        // Four-way simultaneous traffic.
        in_valid = 4'b1111;
        in_dst[0] = 2'd0;
        in_dst[1] = 2'd1;
        in_dst[2] = 2'd2;
        in_dst[3] = 2'd3;
        in_data[0] = 32'hB000_0000;
        in_data[1] = 32'hB111_1111;
        in_data[2] = 32'hB222_2222;
        in_data[3] = 32'hB333_3333;
        out_ready = 4'b1111;
        #10;
        if (out_valid !== 4'b1111) begin
            $error("TB: multi-output scenario failed");
            $finish;
        end

        // Partial backpressure.
        out_ready = 4'b1011;
        #10;
        if (out_valid[2] !== 1'b1 || in_ready[2] !== 1'b0) begin
            $error("TB: partial backpressure scenario failed: VALID should stay high while READY is low");
            $finish;
        end

        // Return to idle and cover reset again.
        in_valid = '0;
        out_ready = '0;
        rst_n = 1'b0;
        #7;
        if (in_ready !== '0 || out_valid !== '0 || out_data !== '0) begin
            $error("TB: reset recovery check failed");
            $finish;
        end

        cov.report();
        $display("TB RESULT: PASS - functional coverage scenarios exercised all 16 routes, contention, four-way multi-output traffic, partial backpressure and reset.");
        $finish;
    end

endmodule
