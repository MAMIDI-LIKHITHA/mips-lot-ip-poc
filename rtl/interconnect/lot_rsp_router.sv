// Protocol-neutral LOT response router.
// Routes a completed response to the source identified by src_id.
// One response is one beat. VALID/data/error remain asserted during backpressure.
module lot_rsp_router #(
    parameter int N = 4,
    parameter int DATA_W = 32,
    parameter int SRC_W = (N <= 1) ? 1 : $clog2(N)
) (
    input  logic                      clk,
    input  logic                      rst_n,
    input  logic [N-1:0]              src_valid,
    output logic [N-1:0]              src_ready,
    input  logic [N-1:0][SRC_W-1:0]   src_id,
    input  logic [N-1:0][DATA_W-1:0]  src_data,
    input  logic [N-1:0]              src_error,
    output logic [N-1:0]              dst_valid,
    input  logic [N-1:0]              dst_ready,
    output logic [N-1:0][DATA_W-1:0]  dst_data,
    output logic [N-1:0]              dst_error,
    output logic [N-1:0][N-1:0]       grant
);

    // Each response names exactly one destination. Arbitrate independently
    // per destination so responses to distinct destinations can proceed in
    // parallel, while same-destination contention grants only one source.
    // Fixed source-index priority is intentional for this simulation candidate.
    always_comb begin : route_responses
        integer src;
        integer dst;
        logic selected;

        src_ready = '0;
        dst_valid = '0;
        dst_data  = '0;
        dst_error = '0;
        grant     = '0;

        for (dst = 0; dst < N; dst = dst + 1) begin
            selected = 1'b0;
            for (src = 0; src < N; src = src + 1) begin
                // The loop only visits legal destinations [0, N-1], so an
                // equality match already rejects every out-of-range src_id.
                // Cast dst to SRC_W to keep the comparison width explicit.
                if (!selected && src_valid[src] &&
                    (src_id[src] == SRC_W'(dst)) && rst_n) begin
                    selected = 1'b1;
                    grant[src][dst] = 1'b1;
                    dst_valid[dst] = 1'b1;
                    dst_data[dst] = src_data[src];
                    dst_error[dst] = src_error[src];
                    src_ready[src] = dst_ready[dst];
                end
            end
        end
    end

endmodule
