// Protocol-neutral internal LOT transaction router.
// This is the boundary a future confirmed MIPS/bus adapter will drive.
// One transaction is one beat.

module lot_txn_router #(
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
    output logic [N-1:0][DATA_W-1:0] dst_data,
    output logic [N-1:0][N-1:0] grant
);

    xbar_4x4 #(
        .N(N),
        .DATA_W(DATA_W),
        .DST_W(DST_W)
    ) u_xbar (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(src_valid),
        .in_ready(src_ready),
        .in_dst(src_dst),
        .in_data(src_data),
        .out_valid(dst_valid),
        .out_ready(dst_ready),
        .out_data(dst_data),
        .grant(grant)
    );

endmodule
