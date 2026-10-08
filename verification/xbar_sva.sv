// Lightweight SystemVerilog assertions for the ready-aware 4x4 crossbar.
// These properties are intended to run alongside directed testbenches.

module xbar_sva #(
    parameter int N = 4,
    parameter int DATA_W = 32
) (
    input logic clk,
    input logic rst_n,
    input logic [N-1:0] in_valid,
    input logic [N-1:0] in_ready,
    input logic [N-1:0][N-1:0] grant,
    input logic [N-1:0] out_valid,
    input logic [N-1:0] out_ready
);

    // An input can be granted to at most one output.
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : g_input_onehot
            assert_input_onehot: assert property (
                @(posedge clk) disable iff (!rst_n)
                $onehot0(grant[i])
            ) else $error("XBAR SVA: input %0d has multiple grants", i);
        end
    endgenerate

    // An output can have at most one granted input.
    genvar j;
    generate
        for (j = 0; j < N; j = j + 1) begin : g_output_onehot
            assert_output_onehot: assert property (
                @(posedge clk) disable iff (!rst_n)
                $onehot0(grant[:,j])
            ) else $error("XBAR SVA: output %0d has multiple grants", j);
        end
    endgenerate

    // A visible transfer requires both VALID and READY.
    generate
        for (j = 0; j < N; j = j + 1) begin : g_transfer_handshake
            assert_valid_ready: assert property (
                @(posedge clk) disable iff (!rst_n)
                out_valid[j] |-> out_ready[j]
            ) else $error("XBAR SVA: output %0d VALID asserted while not READY", j);
        end
    endgenerate

endmodule
