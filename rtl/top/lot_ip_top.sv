// Top-level POC shell.
// The MIPS-facing and final endpoint interfaces remain unimplemented until
// those project requirements are confirmed.
//
// The generic internal transaction boundary is now explicit:
// top -> LOT transaction router -> 4x4 XBAR.

module lot_ip_top #(
    parameter int N = 4,
    parameter int DATA_W = 32,
    parameter int DST_W = (N <= 1) ? 1 : $clog2(N)
) (
    input logic clk,
    input logic rst_n,

    input logic [N-1:0] src_valid,
    output logic [N-1:0] src_ready,
    input logic [N-1:0][DST_W-1:0] src_dst,
    input logic [N-1:0][DATA_W-1:0] src_data,

    output logic [N-1:0] dst_valid,
    input logic [N-1:0] dst_ready,
    output logic [N-1:0][DATA_W-1:0] dst_data
);

    logic [N-1:0][N-1:0] grant_unused;

    lot_txn_router #(
        .N(N),
        .DATA_W(DATA_W),
        .DST_W(DST_W)
    ) u_router (
        .clk(clk),
        .rst_n(rst_n),
        .src_valid(src_valid),
        .src_ready(src_ready),
        .src_dst(src_dst),
        .src_data(src_data),
        .dst_valid(dst_valid),
        .dst_ready(dst_ready),
        .dst_data(dst_data),
        .grant(grant_unused)
    );

endmodule
