// Portable functional coverage tracker for ModelSim Intel FPGA Edition.
// Uses ordinary simulation constructs instead of covergroups/Questa-only features.

module xbar_coverage #(
    parameter int N = 4,
    parameter int DATA_W = 32,
    parameter int DST_W = (N <= 1) ? 1 : $clog2(N)
) (
    input logic clk,
    input logic rst_n,
    input logic [N-1:0] in_valid,
    input logic [N-1:0] in_ready,
    input logic [N-1:0][DST_W-1:0] in_dst,
    input logic [N-1:0] out_valid,
    input logic [N-1:0] out_ready,
    input logic [N-1:0][N-1:0] grant
);

    localparam int ROUTE_COUNT = N * N;

    logic [ROUTE_COUNT-1:0] route_seen;
    logic contention_seen;
    logic multi_output_seen;
    logic backpressure_seen;
    logic reset_seen;
    integer route_hits;
    integer cycle_count;

    function automatic integer route_index(input integer src, input integer dst);
        route_index = (src * N) + dst;
    endfunction

    always @(posedge clk) begin
        integer s;
        integer d;

        cycle_count = cycle_count + 1;

        if (!rst_n) begin
            reset_seen = 1'b1;
        end
        else begin
            for (s = 0; s < N; s = s + 1) begin
                if (in_valid[s] && in_ready[s] && (in_dst[s] < N)) begin
                    d = in_dst[s];
                    if (!route_seen[route_index(s, d)]) begin
                        // Blocking update is intentional: coverage state is a
                        // simulation-side scoreboard sampled on clock edges.
                        route_seen[route_index(s, d)] = 1'b1;
                        route_hits = route_hits + 1;
                    end
                end
            end

            if ($countones(in_valid) >= 2)
                contention_seen = 1'b1;

            if ($countones(out_valid) >= 2)
                multi_output_seen = 1'b1;

            if ((|in_valid) && (out_ready != {N{1'b1}}))
                backpressure_seen = 1'b1;
        end
    end

    initial begin
        route_seen = '0;
        contention_seen = 1'b0;
        multi_output_seen = 1'b0;
        backpressure_seen = 1'b0;
        reset_seen = 1'b0;
        route_hits = 0;
        cycle_count = 0;
    end

    task report;
        real route_pct;
        begin
            route_pct = (100.0 * route_hits) / ROUTE_COUNT;
            $display("==============================================");
            $display("XBAR FUNCTIONAL COVERAGE");
            $display("Route coverage       : %0d/%0d = %0.2f%%",
                     route_hits, ROUTE_COUNT, route_pct);
            $display("Contention           : %s", contention_seen ? "PASS" : "MISS");
            $display("Multi-output         : %s", multi_output_seen ? "PASS" : "MISS");
            $display("Backpressure         : %s", backpressure_seen ? "PASS" : "MISS");
            $display("Reset                : %s", reset_seen ? "PASS" : "MISS");
            $display("==============================================");
        end
    endtask

endmodule
