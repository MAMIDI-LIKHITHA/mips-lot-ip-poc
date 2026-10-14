`timescale 1ns/1ps

module xbar_stress_case #(
    parameter int N = 4,
    parameter int DATA_W = 32,
    parameter int DST_W = (N <= 1) ? 1 : $clog2(N),
    parameter int NUM_CYCLES = 500
) (
    input logic clk,
    output logic done
);
    logic rst_n;
    logic [N-1:0] in_valid, in_ready, out_valid, out_ready;
    logic [N-1:0][DST_W-1:0] in_dst;
    logic [N-1:0][DATA_W-1:0] in_data, out_data;
    logic [N-1:0][N-1:0] grant;
    logic [N-1:0] source_pending;

    integer accepted_count, delivered_count, contention_cycles;
    integer backpressure_stalls, multi_output_cycles, errors;

    xbar_4x4 #(.N(N), .DATA_W(DATA_W), .DST_W(DST_W)) dut (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_ready(in_ready),
        .in_dst(in_dst), .in_data(in_data),
        .out_valid(out_valid), .out_ready(out_ready),
        .out_data(out_data), .grant(grant)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            source_pending <= '0;
        end else begin
            for (int s = 0; s < N; s++) begin
                if (in_valid[s] && in_ready[s])
                    source_pending[s] <= 1'b0;
                else if (in_valid[s])
                    source_pending[s] <= 1'b1;
            end
        end
    end

    initial begin
        done = 1'b0;
        rst_n = 1'b0;
        in_valid = '0;
        in_dst = '0;
        in_data = '0;
        out_ready = '1;
        source_pending = '0;
        accepted_count = 0;
        delivered_count = 0;
        contention_cycles = 0;
        backpressure_stalls = 0;
        multi_output_cycles = 0;
        errors = 0;

        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        for (int cycle = 0; cycle < NUM_CYCLES; cycle++) begin
            @(negedge clk);

            if ((cycle % 10) == 0)
                out_ready = '1;
            else begin
                for (int o = 0; o < N; o++)
                    out_ready[o] = (((cycle + 2*o) % 9) != 0);
            end

            for (int s = 0; s < N; s++) begin
                if (!source_pending[s]) begin
                    in_valid[s] = ((cycle % 10) == 0) ? 1'b1 : (((cycle + 3*s) % 7) != 0);
                    if ((cycle % 10) == 0)
                        in_dst[s] = DST_W'(s);
                    else
                        in_dst[s] = DST_W'((cycle + (s/2) + (cycle/11)) % N);
                    in_data[s] = DATA_W'(32'hA500_0000 | (cycle << 8) | s);
                end
            end

            #1;

            for (int s = 0; s < N; s++) begin
                int row_grants;
                row_grants = 0;
                for (int o = 0; o < N; o++) begin
                    row_grants += grant[s][o];
                    if (grant[s][o]) begin
                        if (!in_valid[s] || in_dst[s] !== DST_W'(o)) begin
                            $error("N=%0d cycle=%0d invalid/wrong-destination grant s=%0d o=%0d", N, cycle, s, o);
                            errors++;
                        end
                        if (!out_valid[o] || out_data[o] !== in_data[s]) begin
                            $error("N=%0d cycle=%0d output payload/VALID mismatch o=%0d", N, cycle, o);
                            errors++;
                        end
                    end
                end
                if (row_grants > 1) begin
                    $error("N=%0d cycle=%0d source %0d has multiple grants", N, cycle, s);
                    errors++;
                end
                if (in_valid[s] && in_ready[s])
                    accepted_count++;
            end

            for (int o = 0; o < N; o++) begin
                int col_grants;
                int contenders;
                col_grants = 0;
                contenders = 0;
                for (int s = 0; s < N; s++) begin
                    col_grants += grant[s][o];
                    if (in_valid[s] && in_dst[s] == DST_W'(o))
                        contenders++;
                end
                if (col_grants > 1) begin
                    $error("N=%0d cycle=%0d output %0d has multiple grants", N, cycle, o);
                    errors++;
                end
                if (out_valid[o] && out_ready[o])
                    delivered_count++;
                if (!out_ready[o])
                    backpressure_stalls++;
                if (contenders > 1 && col_grants <= 1)
                    contention_cycles++;
            end

            if (out_valid === {N{1'b1}} && out_ready === {N{1'b1}})
                multi_output_cycles++;
        end

        @(negedge clk);
        in_valid = '0;
        out_ready = '1;
        #1;

        if (accepted_count != delivered_count) begin
            $error("N=%0d transfer accounting mismatch: accepted=%0d delivered=%0d",
                   N, accepted_count, delivered_count);
            errors++;
        end
        if (accepted_count == 0 || contention_cycles == 0 ||
            backpressure_stalls == 0 || multi_output_cycles == 0) begin
            $error("N=%0d did not exercise all required stress scenarios", N);
            errors++;
        end

        if (errors != 0)
            $fatal(1, "N=%0d stress regression failed with %0d errors", N, errors);

        $display("STRESS PASS N=%0d DATA_W=%0d cycles=%0d accepted=%0d delivered=%0d contention=%0d stalls=%0d multi_output=%0d",
                 N, DATA_W, NUM_CYCLES, accepted_count, delivered_count,
                 contention_cycles, backpressure_stalls, multi_output_cycles);
        done = 1'b1;
    end
endmodule

module tb_xbar_stress_latency;
    logic clk = 1'b0;
    logic done_n2, done_n3, done_n4, done_n5;
    always #5 clk = ~clk;

    xbar_stress_case #(.N(2), .DATA_W(8), .DST_W(1)) case_n2
        (.clk(clk), .done(done_n2));
    xbar_stress_case #(.N(3), .DATA_W(32), .DST_W(2)) case_n3
        (.clk(clk), .done(done_n3));
    xbar_stress_case #(.N(4), .DATA_W(32), .DST_W(2)) case_n4
        (.clk(clk), .done(done_n4));
    xbar_stress_case #(.N(5), .DATA_W(64), .DST_W(3)) case_n5
        (.clk(clk), .done(done_n5));

    initial begin
        wait (done_n2 && done_n3 && done_n4 && done_n5);
        $display("TB RESULT: PASS — parameterized 500-cycle stress across N=2/3/4/5");
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "parameterized stress test timed out");
    end
endmodule
