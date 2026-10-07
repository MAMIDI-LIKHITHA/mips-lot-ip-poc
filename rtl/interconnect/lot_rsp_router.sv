// Protocol-neutral LOT response router.
// Routes a completed response back to the originating source.
// The response source ID is treated as the routing destination.
// One response is one beat.

module lot_rsp_router #(
    parameter int N = 4,
    parameter int DATA_W = 32,
    parameter int SRC_W = (N <= 1) ? 1 : $clog2(N)
) (
    input logic clk,
    input logic rst_n,
    input logic [N-1:0] src_valid,
    output logic [N-1:0] src_ready,
    input logic [N-1:0][SRC_W-1:0] src_id,
    input logic [N-1:0][DATA_W-1:0] src_data,
    input logic [N-1:0] src_error,
    output logic [N-1:0] dst_valid,
    input logic [N-1:0] dst_ready,
    output logic [N-1:0][DATA_W-1:0] dst_data,
    output logic [N-1:0] dst_error,
    output logic [N-1:0][N-1:0] grant
);

    localparam int ROUTER_W = DATA_W + 1;
    logic [N-1:0][ROUTER_W-1:0] packed_data;
    logic [N-1:0][ROUTER_W-1:0] routed_data;

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : g_pack
            always_comb begin
                packed_data[i] = '0;
                packed_data[i][DATA_W-1:0] = src_data[i];
                packed_data[i][DATA_W] = src_error[i];
                dst_data[i] = routed_data[i][DATA_W-1:0];
                dst_error[i] = routed_data[i][DATA_W];
            end
        end
    endgenerate

    xbar_4x4 #(
        .N(N),
        .DATA_W(ROUTER_W),
        .DST_W(SRC_W)
    ) u_rsp_xbar (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(src_valid),
        .in_ready(src_ready),
        .in_dst(src_id),
        .in_data(packed_data),
        .out_valid(dst_valid),
        .out_ready(dst_ready),
        .out_data(routed_data),
        .grant(grant)
    );

endmodule
