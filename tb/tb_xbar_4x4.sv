module tb_xbar_4x4;

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

    xbar_4x4 #(.N(N), .DATA_W(DATA_W), .DST_W(DST_W)) dut (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_ready(in_ready),
        .in_dst(in_dst), .in_data(in_data),
        .out_valid(out_valid), .out_ready(out_ready),
        .out_data(out_data), .grant(grant)
    );

    always #5 clk = ~clk;

    task automatic clear_inputs;
        integer t;
        begin
            for (t = 0; t < N; t = t + 1) begin
                in_valid[t] = 1'b0;
                in_dst[t] = '0;
                in_data[t] = '0;
            end
        end
    endtask

    task automatic check_output(input int output_id, input logic [DATA_W-1:0] expected);
        begin
            if (!out_valid[output_id]) begin
                $error("Output %0d expected valid", output_id);
                $fatal;
            end
            if (out_data[output_id] !== expected) begin
                $error("Output %0d data mismatch: got %h expected %h",
                       output_id, out_data[output_id], expected);
                $fatal;
            end
        end
    endtask

    integer i;
    integer j;
    integer grant_count;

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        out_ready = '1;
        clear_inputs();

        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        // Test 1: one-to-one connectivity.
        for (i = 0; i < N; i = i + 1) begin
            clear_inputs();
            in_valid[i] = 1'b1;
            in_dst[i] = i[DST_W-1:0];
            in_data[i] = 32'h1000 + i;
            #1;
            check_output(i, 32'h1000 + i);
        end

        // Test 2: all inputs target output 0.
        clear_inputs();
        for (i = 0; i < N; i = i + 1) begin
            in_valid[i] = 1'b1;
            in_dst[i] = 2'd0;
            in_data[i] = 32'h2000 + i;
        end
        #1;
        grant_count = 0;
        for (i = 0; i < N; i = i + 1)
            grant_count = grant_count + grant[i][0];

        if (grant_count != 1) begin
            $error("Contention test expected exactly one grant, got %0d", grant_count);
            $fatal;
        end

        if (out_data[0] < 32'h2000 || out_data[0] > 32'h2003) begin
            $error("Contention winner data is outside the four valid contenders");
            $fatal;
        end
        check_output(0, out_data[0]);

        // Test 3: one input cannot be granted to multiple outputs.
        clear_inputs();
        in_valid[0] = 1'b1;
        in_dst[0] = 2'd2;
        in_data[0] = 32'h3000;
        #1;
        grant_count = 0;
        for (j = 0; j < N; j = j + 1)
            grant_count = grant_count + grant[0][j];

        if (grant_count != 1) begin
            $error("Input exclusivity test failed: input 0 has %0d grants", grant_count);
            $fatal;
        end
        check_output(2, 32'h3000);

        // Test 4: output backpressure.
        clear_inputs();
        out_ready[1] = 1'b0;
        in_valid[2] = 1'b1;
        in_dst[2] = 2'd1;
        in_data[2] = 32'h4000;
        #1;
        if (out_valid[1] !== 1'b0 || in_ready[2] !== 1'b0) begin
            $error("Backpressure test failed");
            $fatal;
        end
        out_ready[1] = 1'b1;

        // Reset before the fairness measurement so the expected starting
        // pointer is deterministic and independent of previous tests.
        clear_inputs();
        rst_n = 1'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        // Test 5: round-robin fairness under persistent contention.
        clear_inputs();
        for (i = 0; i < N; i = i + 1) begin
            in_valid[i] = 1'b1;
            in_dst[i] = 2'd0;
            in_data[i] = 32'h5000 + i;
        end

        // The reset pointer starts at input 0. After each clocked grant,
        // the next arbitration starts at the following input.
        for (i = 0; i < N; i = i + 1) begin
            #1;
            if (!grant[i][0]) begin
                $error("Round-robin fairness failed: expected input %0d to win", i);
                $fatal;
            end
            if (out_data[0] !== (32'h5000 + i)) begin
                $error("Round-robin data mismatch: got %h expected %h",
                       out_data[0], 32'h5000 + i);
                $fatal;
            end
            @(posedge clk);
        end

        clear_inputs();
        @(posedge clk);
        $display("TB RESULT: PASS — connectivity, contention, input exclusivity, backpressure and round-robin fairness checks passed.");
        $finish;
    end

endmodule
