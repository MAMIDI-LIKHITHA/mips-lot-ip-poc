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

    integer i;
    integer j;

    always_comb begin
        valid_dst = '0;
        req       = '0;

        for (i = 0; i < N; i = i + 1) begin
            valid_dst[i] = (in_dst[i] < N);
            if (in_valid[i] && valid_dst[i] && out_ready[in_dst[i]])
                req[i][in_dst[i]] = 1'b1;
        end
    end

    xbar_scheduler #(.N(N)) u_scheduler (
        .clk   (clk),
        .rst_n (rst_n),
        .req   (req),
        .grant (grant)
    );

    always_comb begin
        in_ready  = '0;
        out_valid = '0;
        out_data  = '0;

        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                if (grant[i][j]) begin
                    in_ready[i]  = 1'b1;
                    out_valid[j] = 1'b1;
                    out_data[j]  = in_data[i];
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
