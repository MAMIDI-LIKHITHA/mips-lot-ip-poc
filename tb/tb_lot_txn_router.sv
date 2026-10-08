`timescale 1ns/1ps
module tb_lot_txn_router;

    localparam int N = 4;
    localparam int DATA_W = 32;
    localparam int DST_W = 2;

    logic clk;
    logic rst_n;

    logic [N-1:0] src_valid;
    logic [N-1:0] src_ready;
    logic [N-1:0][DST_W-1:0] src_dst;
    logic [N-1:0][DATA_W-1:0] src_data;

    logic [N-1:0] dst_valid;
    logic [N-1:0] dst_ready;
    logic [N-1:0][DATA_W-1:0] dst_data;
    logic [N-1:0][N-1:0] grant;

    lot_txn_router #(
        .N(N),
        .DATA_W(DATA_W),
        .DST_W(DST_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .src_valid(src_valid),
        .src_ready(src_ready),
        .src_dst(src_dst),
        .src_data(src_data),
        .dst_valid(dst_valid),
        .dst_ready(dst_ready),
        .dst_data(dst_data),
        .grant(grant)
    );

    always #5 clk = ~clk;

    task automatic clear_inputs;
        begin
            src_valid = '0;
            src_dst = '0;
            src_data = '0;
        end
    endtask

    task automatic check_route(
        input int source,
        input int destination,
        input logic [DATA_W-1:0] data
    );
        begin
            clear_inputs();
            dst_ready = '1;

            src_valid[source] = 1'b1;
            src_dst[source] = destination[DST_W-1:0];
            src_data[source] = data;

            #1;

            if (!src_ready[source]) begin
                $error("Route check failed: source %0d was not ready for destination %0d",
                       source, destination);
                $fatal;
            end

            if (!dst_valid[destination]) begin
                $error("Route check failed: destination %0d did not assert valid",
                       destination);
                $fatal;
            end

            if (dst_data[destination] !== data) begin
                $error("Route data mismatch: destination %0d got %h expected %h",
                       destination, dst_data[destination], data);
                $fatal;
            end

            if (grant[source][destination] !== 1'b1) begin
                $error("Grant mismatch: expected grant[%0d][%0d]",
                       source, destination);
                $fatal;
            end

            @(posedge clk);
            #1;
            clear_inputs();
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        clear_inputs();
        dst_ready = '1;

        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        #1;

        // 1. Basic destination routing and payload integrity.
        check_route(0, 0, 32'hA000_0001);
        check_route(1, 1, 32'hB111_1112);
        check_route(2, 2, 32'hC222_2223);
        check_route(3, 3, 32'hD333_3334);

        // 2. Backpressure: destination 2 is stalled.
        clear_inputs();
        dst_ready = '1;
        dst_ready[2] = 1'b0;
        src_valid[1] = 1'b1;
        src_dst[1] = 2'd2;
        src_data[1] = 32'hBEEF_0002;
        #1;

        if (src_ready[1] !== 1'b0 || dst_valid[2] !== 1'b0) begin
            $error("Backpressure check failed: blocked destination accepted a request");
            $fatal;
        end

        // Release destination 2; request must become transferable without changing data.
        dst_ready[2] = 1'b1;
        #1;

        if (src_ready[1] !== 1'b1 || dst_valid[2] !== 1'b1 ||
            dst_data[2] !== 32'hBEEF_0002) begin
            $error("Backpressure release check failed");
            $fatal;
        end

        @(posedge clk);
        #1;
        clear_inputs();

        // 3. Contention: two sources target the same output.
        dst_ready = '1;
        src_valid[0] = 1'b1;
        src_valid[1] = 1'b1;
        src_dst[0] = 2'd3;
        src_dst[1] = 2'd3;
        src_data[0] = 32'h1111_0000;
        src_data[1] = 32'h2222_0000;
        #1;

        if ((dst_valid[3] !== 1'b1) ||
            (grant[0][3] + grant[1][3]) !== 1) begin
            $error("Contention check failed: expected exactly one winner for destination 3");
            $fatal;
        end

        if (!((src_ready[0] === 1'b1) ^ (src_ready[1] === 1'b1))) begin
            $error("Contention check failed: expected exactly one source ready");
            $fatal;
        end

        if (src_ready[0] && dst_data[3] !== 32'h1111_0000) begin
            $error("Contention winner data mismatch for source 0");
            $fatal;
        end

        if (src_ready[1] && dst_data[3] !== 32'h2222_0000) begin
            $error("Contention winner data mismatch for source 1");
            $fatal;
        end

        @(posedge clk);
        #1;

        // 4. After one contender is served, round-robin pointer should favor the other.
        if (!src_ready[1] || dst_data[3] !== 32'h2222_0000) begin
            $error("Round-robin progression check failed: source 1 was not favored");
            $fatal;
        end

        clear_inputs();
        dst_ready = '1;

        $display("TB RESULT: PASS - LOT transaction routing, payload integrity, backpressure, contention and round-robin progression checks passed.");
        $finish;
    end

endmodule
