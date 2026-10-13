module xbar_scheduler #(
    parameter int N = 4
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic [N*N-1:0]        req,
    input  logic [N-1:0]          out_ready,
    output logic [N-1:0][N-1:0]   grant
);

    localparam int PTR_W = (N <= 1) ? 1 : $clog2(N);

    logic [PTR_W-1:0] rr_ptr [N];
    logic [N-1:0]     used_input;
    logic [PTR_W-1:0] next_rr [N];

    integer o;
    integer k;
    integer idx;
    logic found;

    // Arbitration is independent of downstream READY. This allows VALID
    // and payload to remain asserted while a selected output is stalled.
    always_comb begin
        grant      = '0;
        used_input = '0;
        next_rr    = rr_ptr;

        for (o = 0; o < N; o = o + 1) begin
            found = 1'b0;
            for (k = 0; k < N; k = k + 1) begin
                idx = rr_ptr[o] + k;
                if (idx >= N)
                    idx = idx - N;

                if (!found && !used_input[idx] && req[idx*N + o]) begin
                    grant[idx][o] = 1'b1;
                    used_input[idx] = 1'b1;
                    found = 1'b1;

                    // Advance fairness state only when this output
                    // completes a valid/ready handshake.
                    if (out_ready[o])
                        next_rr[o] = (idx == N-1) ? '0 : idx + 1'b1;
                end
            end
        end
    end

    integer p;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (p = 0; p < N; p = p + 1)
                rr_ptr[p] <= '0;
        end else begin
            for (p = 0; p < N; p = p + 1)
                rr_ptr[p] <= next_rr[p];
        end
    end

endmodule
