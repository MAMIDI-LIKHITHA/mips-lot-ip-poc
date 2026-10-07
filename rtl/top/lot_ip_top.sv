// Top-level POC shell.
// The MIPS-facing interface and final endpoint interfaces are intentionally
// left unimplemented until the project requirements are confirmed.
//
// Current milestone: expose the generic 4x4 interconnect as a standalone
// engineering block.

module lot_ip_top #(
    parameter int N = 4,
    parameter int DATA_W = 32,
    parameter int DST_W  = (N <= 1) ? 1 : $clog2(N)
) (
    input  logic                     clk,
    input  logic                     rst_n,

    input  logic [N-1:0]             in_valid,
    output logic [N-1:0]             in_ready,
    input  logic [N-1:0][DST_W-1:0]  in_dst,
    input  logic [N-1:0][DATA_W-1:0] in_data,

    output logic [N-1:0]             out_valid,
    input  logic [N-1:0]             out_ready,
    output logic [N-1:0][DATA_W-1:0] out_data
);

    logic [N-1:0][N-1:0] grant_unused;

    xbar_4x4 #(
        .N     (N),
        .DATA_W(DATA_W),
        .DST_W (DST_W)
    ) u_xbar (
        .clk      (clk),
        .rst_n    (rst_n),
        .in_valid (in_valid),
        .in_ready  (in_ready),
        .in_dst    (in_dst),
        .in_data  (in_data),
        .out_valid(out_valid),
        .out_ready (out_ready),
        .out_data  (out_data),
        .grant      (grant_unused)
    );

endmodule
