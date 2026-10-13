`timescale 1ns/1ps
module tb_lot_rsp_router;

    localparam int N = 4;
    localparam int DATA_W = 32;
    localparam int SRC_W = 3;

    logic clk, rst_n;
    logic [N-1:0] src_valid, src_ready;
    logic [N-1:0][SRC_W-1:0] src_id;
    logic [N-1:0][DATA_W-1:0] src_data;
    logic [N-1:0] src_error;
    logic [N-1:0] dst_valid, dst_ready, dst_error;
    logic [N-1:0][DATA_W-1:0] dst_data;
    logic [N-1:0][N-1:0] grant;

    lot_rsp_router #(.N(N), .DATA_W(DATA_W), .SRC_W(SRC_W)) dut (
        .clk(clk), .rst_n(rst_n),
        .src_valid(src_valid), .src_ready(src_ready),
        .src_id(src_id), .src_data(src_data), .src_error(src_error),
        .dst_valid(dst_valid), .dst_ready(dst_ready),
        .dst_data(dst_data), .dst_error(dst_error), .grant(grant)
    );

    always #5 clk = ~clk;

    task automatic clear_inputs;
        integer i;
        begin
            for (i = 0; i < N; i = i + 1) begin
                src_valid[i] = 1'b0; src_id[i] = '0;
                src_data[i] = '0; src_error[i] = 1'b0;
            end
        end
    endtask

    task automatic check_output(
        input int output_id,
        input logic [DATA_W-1:0] expected_data,
        input logic expected_error
    );
        begin
            if (!dst_valid[output_id]) begin $error("Expected response valid at output %0d; dst_valid=%b src_valid=%b src_id=%b src_ready=%b grant=%b", output_id, dst_valid, src_valid, src_id, src_ready, grant); $fatal; end
            if (dst_data[output_id] !== expected_data) begin
                $error("Data mismatch at output %0d: got %h expected %h", output_id, dst_data[output_id], expected_data);
                $fatal;
            end
            if (dst_error[output_id] !== expected_error) begin $error("Error bit mismatch"); $fatal; end
        end
    endtask

    integer i;
    integer grant_count;

    initial begin
        clk = 1'b0; rst_n = 1'b0; dst_ready = '1; clear_inputs();
        repeat (2) @(posedge clk);
        // Deassert reset away from the active clock edge to avoid testbench/DUT races.
        @(negedge clk);
        rst_n = 1'b1;

        // Direct response routing.
        clear_inputs();
        src_valid[2] = 1'b1; src_id[2] = 2'd1;
        src_data[2] = 32'hA001; src_error[2] = 1'b0;
        #1; check_output(1, 32'hA001, 1'b0);

        // Error propagation.
        clear_inputs();
        src_valid[0] = 1'b1; src_id[0] = 2'd3;
        src_data[0] = 32'hE003; src_error[0] = 1'b1;
        #1; check_output(3, 32'hE003, 1'b1);

        // Multiple responses can route to distinct sources in the same cycle.
        clear_inputs();
        src_valid[0] = 1'b1; src_id[0] = 2'd0;
        src_data[0] = 32'hD000; src_error[0] = 1'b0;
        src_valid[2] = 1'b1; src_id[2] = 2'd2;
        src_data[2] = 32'hD002; src_error[2] = 1'b1;
        #1;
        check_output(0, 32'hD000, 1'b0);
        check_output(2, 32'hD002, 1'b1);
        if (src_ready[0] !== 1'b1 || src_ready[2] !== 1'b1)
            $fatal(1, "Distinct-destination responses should both be accepted concurrently");

        // Two responses cannot target the same source simultaneously.
        clear_inputs();
        src_valid[0] = 1'b1; src_id[0] = 2'd0; src_data[0] = 32'hB000;
        src_valid[3] = 1'b1; src_id[3] = 2'd0; src_data[3] = 32'hB003;
        #1;
        grant_count = 0;
        for (i = 0; i < N; i = i + 1) grant_count = grant_count + grant[i][0];
        if (grant_count != 1) begin $error("Expected one response grant, got %0d", grant_count); $fatal; end
        // The candidate currently uses fixed lowest-index source priority.
        if (grant[0][0] !== 1'b1 || grant[3][0] !== 1'b0 ||
            dst_valid[0] !== 1'b1 || dst_data[0] !== 32'hB000 ||
            src_ready[0] !== 1'b1 || src_ready[3] !== 1'b0) begin
            $error("Same-destination contention did not honor documented fixed source-index priority");
            $fatal;
        end

        // Out-of-range source IDs must not be routed or acknowledged.
        clear_inputs();
        src_valid[1] = 1'b1; src_id[1] = 3'd7;
        src_data[1] = 32'hBAD7; src_error[1] = 1'b1;
        #1;
        if (dst_valid !== '0 || src_ready !== '0 || grant !== '0) begin
            $error("Out-of-range source ID must not assert destination VALID, source READY, or a grant");
            $fatal;
        end

        // Backpressure.
        clear_inputs();
        dst_ready[2] = 1'b0;
        src_valid[1] = 1'b1; src_id[1] = 2'd2; src_data[1] = 32'hC002;
        // Keep the source response stable while the destination applies
        // backpressure for several clock cycles.
        repeat (3) begin
            @(posedge clk);
            #1;
            if (dst_valid[2] !== 1'b1 ||
                dst_data[2] !== 32'hC002 ||
                dst_error[2] !== 1'b0 ||
                src_ready[1] !== 1'b0) begin
                $error("Response changed or was acknowledged during sustained backpressure");
                $fatal;
            end
        end

        // Once READY returns, the held response must be accepted.
        @(negedge clk);
        dst_ready[2] = 1'b1;
        #1;
        if (dst_valid[2] !== 1'b1 ||
            dst_data[2] !== 32'hC002 ||
            dst_error[2] !== 1'b0 ||
            src_ready[1] !== 1'b1) begin
            $error("Held response was not accepted when READY returned");
            $fatal;
        end

        $display("TB RESULT: PASS - response routing, simultaneous distinct-destination responses, error propagation, contention and backpressure checks passed.");
        $finish;
    end
endmodule
