// Lightweight functional coverage for the ready-aware crossbar.
// Intended for simulation-side coverage collection in the verification environment.

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

    // Route coverage: every legal source -> destination pair.
    covergroup cg_routes @(posedge clk);
        cp_route: coverpoint {
            in_valid[0] && in_ready[0] && (in_dst[0] < N)
        } {
            bins active = {1'b1};
        }
    endgroup

    // Backpressure coverage: at least one output is stalled while valid traffic exists.
    covergroup cg_backpressure @(posedge clk);
        cp_stall: coverpoint (|in_valid && (out_ready != {N{1'b1}})) {
            bins no_stall = {1'b0};
            bins stalled  = {1'b1};
        }
    endgroup

    // Multi-output coverage: number of active outputs.
    covergroup cg_multi_output @(posedge clk);
        cp_active_outputs: coverpoint $countones(out_valid) {
            bins none = {0};
            bins one  = {1};
            bins two  = {2};
            bins three = {3};
            bins four = {4};
        }
    endgroup

    // Contention coverage: multiple inputs request traffic simultaneously.
    covergroup cg_contention @(posedge clk);
        cp_active_inputs: coverpoint $countones(in_valid) {
            bins one = {1};
            bins two = {2};
            bins three = {3};
            bins four = {4};
        }
    endgroup

    // Reset coverage.
    covergroup cg_reset @(posedge clk);
        cp_reset: coverpoint rst_n {
            bins reset_asserted = {1'b0};
            bins reset_released = {1'b1};
        }
    endgroup

    cg_routes       routes_cov = new();
    cg_backpressure bp_cov     = new();
    cg_multi_output multi_cov  = new();
    cg_contention   cont_cov   = new();
    cg_reset        reset_cov  = new();

    final begin
        $display("XBAR COVERAGE: routes=%0.2f%% backpressure=%0.2f%% multi_output=%0.2f%% contention=%0.2f%% reset=%0.2f%%",
                 routes_cov.get_inst_coverage(),
                 bp_cov.get_inst_coverage(),
                 multi_cov.get_inst_coverage(),
                 cont_cov.get_inst_coverage(),
                 reset_cov.get_inst_coverage());
    end

endmodule
