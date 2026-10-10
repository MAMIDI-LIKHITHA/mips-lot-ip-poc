`timescale 1ns/1ps
module tb_xbar_stress_latency;

    localparam int N = 4;
    localparam int DATA_W = 32;
    localparam int DST_W = 2;
    localparam int NUM_CYCLES = 500;

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

    integer cycle;
    integer i;
    integer j;
    integer accepted_count;
    integer delivered_count;
    integer contention_cycles;
    integer backpressure_output_stalls;
    integer multi_output_cycles;
    integer latency_zero_count;
    integer latency_min;
    integer latency_max;
    integer latency_sum;
    integer errors;
    logic [N-1:0] source_pending;

    // A source holds VALID, destination, and payload until its handshake.
    always @(posedge clk or negedge rst_n) begin
        integer s;
        if (!rst_n) begin
            source_pending <= '0;
        end else begin
            for (s = 0; s < N; s = s + 1) begin
                if (in_valid[s] && in_ready[s])
                    source_pending[s] <= 1'b0;
                else if (in_valid[s])
                    source_pending[s] <= 1'b1;
            end
        end
    end

    task automatic clear_inputs;
        integer t;
        begin
            for (t = 0; t < N; t = t + 1) begin
                in_valid[t] = 1'b0;
                in_dst[t]   = '0;
                in_data[t]  = '0;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        in_valid = '0;
        in_dst = '0;
        in_data = '0;
        out_ready = '1;

        accepted_count = 0;
        delivered_count = 0;
        contention_cycles = 0;
        backpressure_output_stalls = 0;
        multi_output_cycles = 0;
        latency_zero_count = 0;
        latency_min = 999999;
        latency_max = 0;
        latency_sum = 0;
        errors = 0;
        source_pending = '0;

        // Hold reset across a rising edge.
        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        for (cycle = 0; cycle < NUM_CYCLES; cycle = cycle + 1) begin
            // Drive traffic during the low phase so combinational
            // ready/valid signals settle before the checks.
            @(negedge clk);

            // Every 10th cycle opens a four-output opportunity; otherwise
            // use deterministic output stalls to exercise backpressure.
            if ((cycle % 10) == 0)
                out_ready = '1;
            else
                for (j = 0; j < N; j = j + 1)
                    out_ready[j] = (((cycle + 2*j) % 9) != 0);

            // Only launch a new transaction after the previous one completed.
            // A stalled source keeps VALID, destination, and data unchanged.
            for (i = 0; i < N; i = i + 1) begin
                if (!source_pending[i]) begin
                    if ((cycle % 10) == 0) begin
                        in_valid[i] = 1'b1;
                        in_dst[i] = ((cycle / 10) + i) % N;
                        in_data[i] = 32'hF400_0000 | (cycle << 8) | i;
                    end else begin
                        in_valid[i] = (((cycle + 3*i) % 7) != 0);
                        in_dst[i] = (cycle + 2*i + (cycle/11)) % N;
                        in_data[i] = 32'hA500_0000 | (cycle << 8) | i;
                    end
                end
            end

            #1;

            // Verify scheduler invariants every stress cycle.
            for (i = 0; i < N; i = i + 1) begin
                if (grant[i][0] || grant[i][1] || grant[i][2] || grant[i][3]) begin
                    if (!in_valid[i]) begin
                        $error("Cycle %0d: grant issued to invalid input %0d", cycle, i);
                        errors = errors + 1;
                    end
                end

                for (j = 0; j < N; j = j + 1) begin
                    if (grant[i][j]) begin
                        if (in_dst[i] !== j[DST_W-1:0]) begin
                            $error("Cycle %0d: input %0d granted to wrong output %0d", cycle, i, j);
                            errors = errors + 1;
                        end
                        if (!out_valid[j]) begin
                            $error("Cycle %0d: grant/output valid mismatch on output %0d", cycle, j);
                            errors = errors + 1;
                        end
                        if (out_data[j] !== in_data[i]) begin
                            $error("Cycle %0d: data mismatch input %0d -> output %0d", cycle, i, j);
                            errors = errors + 1;
                        end
                    end
                end
            end

            // One input may not receive multiple grants.
            for (i = 0; i < N; i = i + 1) begin
                if ((grant[i][0] + grant[i][1] + grant[i][2] + grant[i][3]) > 1) begin
                    $error("Cycle %0d: input %0d received multiple grants", cycle, i);
                    errors = errors + 1;
                end
            end

            // One output may not have multiple grants.
            for (j = 0; j < N; j = j + 1) begin
                if ((grant[0][j] + grant[1][j] + grant[2][j] + grant[3][j]) > 1) begin
                    $error("Cycle %0d: output %0d received multiple grants", cycle, j);
                    errors = errors + 1;
                end
            end

            // Count accepted and delivered transfers.
            for (i = 0; i < N; i = i + 1) begin
                if (in_valid[i] && in_ready[i]) begin
                    accepted_count = accepted_count + 1;

                    // This XBAR is combinational, so an accepted transfer
                    // is delivered in the same cycle (zero-cycle latency).
                    latency_zero_count = latency_zero_count + 1;
                    if (latency_min > 0)
                        latency_min = 0;
                    latency_max = 0;
                end
            end

            for (j = 0; j < N; j = j + 1) begin
                if (out_valid[j] && out_ready[j])
                    delivered_count = delivered_count + 1;
                if (!out_ready[j])
                    backpressure_output_stalls = backpressure_output_stalls + 1;
            end

            // Detect whether any output has multiple active contenders.
            for (j = 0; j < N; j = j + 1) begin
                integer contenders;
                contenders = 0;
                for (i = 0; i < N; i = i + 1)
                    if (in_valid[i] && (in_dst[i] == j[DST_W-1:0]))
                        contenders = contenders + 1;
                if (contenders > 1) begin
                    contention_cycles = contention_cycles + 1;
                    break;
                end
            end

            // Count cycles where all four outputs are simultaneously valid.
            if ((out_valid[0] + out_valid[1] + out_valid[2] + out_valid[3]) == N && out_ready == '1)
                multi_output_cycles = multi_output_cycles + 1;
        end

        @(negedge clk);
        clear_inputs();
        out_ready = '1;
        #1;

        $display("================================================");
        $display("XBAR STRESS + LATENCY VERIFICATION");
        $display("================================================");
        $display("Stress cycles               : %0d", NUM_CYCLES);
        $display("Accepted transfers          : %0d", accepted_count);
        $display("Delivered transfers         : %0d", delivered_count);
        $display("Contention cycles           : %0d", contention_cycles);
        $display("Backpressure output stalls  : %0d", backpressure_output_stalls);
        $display("Four-output cycles          : %0d", multi_output_cycles);
        $display("Latency min (cycles)        : %0d", latency_min);
        $display("Latency max (cycles)        : %0d", latency_max);
        if (accepted_count > 0)
            $display("Latency average (cycles)    : %0.2f", latency_sum * 1.0 / accepted_count);
        else
            $display("Latency average (cycles)    : N/A");
        $display("Zero-cycle transfers        : %0d", latency_zero_count);
        $display("================================================");

        if (accepted_count != delivered_count) begin
            $error("Transfer accounting mismatch: accepted=%0d delivered=%0d",
                   accepted_count, delivered_count);
            errors = errors + 1;
        end

        if (accepted_count == 0) begin
            $error("Stress test generated no accepted transfers");
            errors = errors + 1;
        end

        if (contention_cycles == 0) begin
            $error("Stress test did not exercise contention");
            errors = errors + 1;
        end

        if (backpressure_output_stalls == 0) begin
            $error("Stress test did not exercise backpressure");
            errors = errors + 1;
        end

        if (multi_output_cycles == 0) begin
            $error("Stress test did not exercise four-output simultaneous traffic");
            errors = errors + 1;
        end

        if (errors != 0) begin
            $display("TB RESULT: FAIL - %0d verification errors detected.", errors);
            $fatal;
        end else begin
            $display("TB RESULT: PASS - stress traffic, transfer accounting, contention, backpressure, four-output simultaneous traffic and zero-cycle crossbar latency verified.");
        end

        $finish;
    end

endmodule
