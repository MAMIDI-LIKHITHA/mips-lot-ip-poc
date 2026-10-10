// Lightweight SystemVerilog assertions for the ready/valid 4x4 crossbar.
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
    input logic [N-1:0] out_ready,
    input logic [N-1:0][DATA_W-1:0] out_data
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
    genvar o;
    genvar a;
    genvar b;
    generate
        for (o = 0; o < N; o = o + 1) begin : g_output_unique
            for (a = 0; a < N; a = a + 1) begin : g_output_pair_a
                for (b = a + 1; b < N; b = b + 1) begin : g_output_pair_b
                    assert_output_unique: assert property (
                        @(posedge clk) disable iff (!rst_n)
                        !(grant[a][o] && grant[b][o])
                    ) else $error("XBAR SVA: output %0d has multiple grants", o);
                end
            end
        end
    endgenerate

    // VALID may remain asserted while READY is low; the payload must hold.
    genvar j;
    generate
        for (j = 0; j < N; j = j + 1) begin : g_transfer_handshake
            assert_stable_when_stalled: assert property (
                @(posedge clk) disable iff (!rst_n)
                (out_valid[j] && !out_ready[j]) |=> (out_valid[j] && $stable(out_data[j]))
            ) else $error("XBAR SVA: output %0d VALID/data changed while stalled", j);
        end
    endgenerate

endmodule
