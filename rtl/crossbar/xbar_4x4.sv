module xbar_4x4 #(
    parameter int N = 4,
    parameter int DATA_W = 32,
    parameter int DST_W  = (N <= 1) ? 1 : $clog2(N)
) (
    input  logic                    clk,
    input  logic                    rst_n,

    input  logic [N-1:0]            in_valid,
    output logic [N-1:0]            in_ready,
    input  logic [N-1:0][DST_W-1:0] in_dst,
    input  logic [N-1:0][DATA_W-1:0] in_data,

    output logic [N-1:0]            out_valid,
    input  logic [N-1:0]            out_ready,
    output logic [N-1:0][DATA_W-1:0] out_data,

    output logic [N-1:0][N-1:0]     grant
);

    logic [N-1:0][N-1:0] req;
    logic [N-1:0]        valid_dst;

    // Requests describe source intent and destination only. READY must not
    // gate request generation or the downstream VALID signal.
    always_comb begin : build_requests
        integer i;

        valid_dst = '0;
        req       = '0;

        for (i = 0; i < N; i = i + 1) begin
            valid_dst[i] = (in_dst[i] < N);
            if (in_valid[i] && valid_dst[i])
                req[i][in_dst[i]] = 1'b1;
        end
    end

    xbar_scheduler #(.N(N)) u_scheduler (
        .clk       (clk),
        .rst_n     (rst_n),
        .req       (req),
        .out_ready (out_ready),
        .grant     (grant)
    );

    // A selected request asserts output VALID regardless of output READY.
    // The input sees READY only when its selected output can accept it.
    always_comb begin : route_outputs
        integer i;
        integer j;

        in_ready  = '0;
        out_valid = '0;
        out_data  = '0;

        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                if (grant[i][j]) begin
                    out_valid[j] = 1'b1;
                    out_data[j]  = in_data[i];
                    in_ready[i]  = out_ready[j];
                end
            end
        end

        if (!rst_n) begin
            in_ready  = '0;
            out_valid = '0;
            out_data  = '0;
        end
    end

endmodule
