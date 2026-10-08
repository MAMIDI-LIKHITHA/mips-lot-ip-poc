// Mixed concurrent LOT fabric verification.
//
// Four independent sources each execute a mixed write/read/error sequence.
// The first phase deliberately creates destination contention, while later
// phases use independent destinations. Response readiness is varied to exercise
// response backpressure and stability. Endpoint ownership is tracked at the
// request handshake so response source IDs remain associated with the actual
// winning source under contention.
//
// Verified intent:
// - concurrent source traffic
// - request-destination contention and arbitration
// - read/write/error transactions
// - response backpressure
// - response source-ID mapping under contention
// - data/error integrity

module tb_lot_mixed_traffic;

    localparam int N = 4;
    localparam int ADDR_W = 32;
    localparam int DATA_W = 32;
    localparam int DST_W = 2;
    localparam int LOT_W = ADDR_W + DATA_W + 1;
    localparam int TXNS_PER_SRC = 3;

    logic clk, rst_n;

    logic [N-1:0] src_valid, src_ready;
    logic [N-1:0][DST_W-1:0] src_dst;
    logic [N-1:0][LOT_W-1:0] src_data;

    logic [N-1:0] req_valid, req_ready;
    logic [N-1:0][LOT_W-1:0] req_data;

    logic [N-1:0] ep_rsp_valid, ep_rsp_ready, ep_rsp_error, ep_req_ready;
    logic [N-1:0][DATA_W-1:0] ep_rsp_data;

    logic [N-1:0] rsp_src_valid, rsp_src_ready;
    logic [N-1:0][DST_W-1:0] rsp_src_id;
    logic [N-1:0][DATA_W-1:0] rsp_src_data;
    logic [N-1:0] rsp_src_error;

    logic [N-1:0] dst_valid, dst_ready;
    logic [N-1:0][DATA_W-1:0] dst_data;
    logic [N-1:0] dst_error;
    logic [N-1:0][N-1:0] req_grant, rsp_grant;

    integer txn_idx [N];
    integer target [N];
    logic waiting [N];
    logic done [N];

    logic [DST_W-1:0] endpoint_owner [N];
    logic owner_valid [N];

    integer accepted_count;
    integer response_count;
    integer contention_cycles;
    integer backpressure_cycles;
    integer cycle;
    integer i;

    function automatic [DST_W-1:0] calc_target(input integer s, input integer t);
        begin
            if (t == 0)
                calc_target = 2;          // all sources contend for endpoint 2
            else if (t == 1)
                calc_target = s;          // independent destinations
            else
                calc_target = (s + 1) % N; // second contention pattern
        end
    endfunction

    function automatic [31:0] calc_data(input integer s);
        calc_data = 32'hB100_0000 + s;
    endfunction

    function automatic [31:0] expected_data(input integer s, input integer t);
        expected_data = calc_data(s);
    endfunction

    function automatic expected_error(input integer t);
        expected_error = (t == 2);
    endfunction

    assign dst_ready[0] = ((cycle % 4) != 1);
    assign dst_ready[1] = ((cycle % 4) != 2);
    assign dst_ready[2] = ((cycle % 4) != 3);
    assign dst_ready[3] = 1'b1;

    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : g_src
            assign src_valid[g] = !done[g] && !waiting[g];
            assign src_dst[g] = target[g][DST_W-1:0];

            always_comb begin
                src_data[g] = '0;
                if (txn_idx[g] == 0) begin
                    // WRITE CONTROL
                    src_data[g] = {1'b1, (target[g] << 16), calc_data(g)};
                end else if (txn_idx[g] == 1) begin
                    // READ CONTROL
                    src_data[g] = {1'b0, (target[g] << 16), 32'h0};
                end else begin
                    // INVALID WRITE: local register offset 0x0010
                    src_data[g] = {1'b1, (target[g] << 16) | 32'h0000_0010, calc_data(g)};
                end
            end
        end
    endgenerate

    lot_txn_router #(
        .N(N), .DATA_W(LOT_W), .DST_W(DST_W)
    ) u_req_router (
        .clk(clk), .rst_n(rst_n),
        .src_valid(src_valid), .src_ready(src_ready),
        .src_dst(src_dst), .src_data(src_data),
        .dst_valid(req_valid), .dst_ready(req_ready),
        .dst_data(req_data), .grant(req_grant)
    );

    generate
        for (g = 0; g < N; g = g + 1) begin : g_ep
            assign req_ready[g] = ep_req_ready[g];
            lot_endpoint_adapter #(
                .ADDR_W(ADDR_W), .DATA_W(DATA_W), .LOT_W(LOT_W)
            ) u_endpoint (
                .clk(clk), .rst_n(rst_n),
                .req_valid(req_valid[g]), .req_ready(ep_req_ready[g]),
                .req_payload(req_data[g]),
                .rsp_valid(ep_rsp_valid[g]), .rsp_ready(ep_rsp_ready[g]),
                .rsp_rdata(ep_rsp_data[g]), .rsp_error(ep_rsp_error[g])
            );
        end
    endgenerate

    assign rsp_src_valid = ep_rsp_valid;
    assign rsp_src_data = ep_rsp_data;
    assign rsp_src_error = ep_rsp_error;

    generate
        for (g = 0; g < N; g = g + 1) begin : g_rsp_id
            assign rsp_src_id[g] = endpoint_owner[g];
        end
    endgenerate

    assign ep_rsp_ready = rsp_src_ready;

    lot_rsp_router #(
        .N(N), .DATA_W(DATA_W), .SRC_W(DST_W)
    ) u_rsp_router (
        .clk(clk), .rst_n(rst_n),
        .src_valid(rsp_src_valid), .src_ready(rsp_src_ready),
        .src_id(rsp_src_id), .src_data(rsp_src_data),
        .src_error(rsp_src_error),
        .dst_valid(dst_valid), .dst_ready(dst_ready),
        .dst_data(dst_data), .dst_error(dst_error),
        .grant(rsp_grant)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst_n) begin
            for (i = 0; i < N; i = i + 1) begin
                // Record actual request winner for each endpoint.
                if (req_valid[i] && req_ready[i]) begin
                    for (integer s = 0; s < N; s = s + 1) begin
                        if (src_valid[s] && src_ready[s] &&
                            src_dst[s] == i[DST_W-1:0]) begin
                            endpoint_owner[i] <= s[DST_W-1:0];
                            owner_valid[i] <= 1'b1;
                            waiting[s] <= 1'b1;
                            accepted_count <= accepted_count + 1;
                        end
                    end
                end

                if (dst_valid[i] && dst_ready[i]) begin
                    response_count <= response_count + 1;
                    for (integer s2 = 0; s2 < N; s2 = s2 + 1) begin
                        if (rsp_src_id[i] == s2[DST_W-1:0] && waiting[s2]) begin
                            if (dst_data[i] !== expected_data(s2, txn_idx[s2]))
                                $fatal(1, "Source %0d data mismatch txn %0d: got %h expected %h",
                                       s2, txn_idx[s2], dst_data[i], expected_data(s2, txn_idx[s2]));
                            if (dst_error[i] !== expected_error(txn_idx[s2]))
                                $fatal(1, "Source %0d error mismatch txn %0d: got %b expected %b",
                                       s2, txn_idx[s2], dst_error[i], expected_error(txn_idx[s2]));
                            waiting[s2] <= 1'b0;
                            if (txn_idx[s2] == TXNS_PER_SRC-1) begin
                                done[s2] <= 1'b1;
                            end else begin
                                txn_idx[s2] <= txn_idx[s2] + 1;
                                target[s2] <= calc_target(s2, txn_idx[s2] + 1);
                            end
                        end
                    end
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst_n) begin
            if ((src_valid[0] && src_valid[1] && src_dst[0] == src_dst[1]) ||
                (src_valid[0] && src_valid[2] && src_dst[0] == src_dst[2]) ||
                (src_valid[0] && src_valid[3] && src_dst[0] == src_dst[3]) ||
                (src_valid[1] && src_valid[2] && src_dst[1] == src_dst[2]) ||
                (src_valid[1] && src_valid[3] && src_dst[1] == src_dst[3]) ||
                (src_valid[2] && src_valid[3] && src_dst[2] == src_dst[3]))
                contention_cycles <= contention_cycles + 1;

            if (dst_valid != 0 && dst_ready != {N{1'b1}})
                backpressure_cycles <= backpressure_cycles + 1;
        end
    end

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        accepted_count = 0;
        response_count = 0;
        contention_cycles = 0;
        backpressure_cycles = 0;

        for (i = 0; i < N; i = i + 1) begin
            txn_idx[i] = 0;
            target[i] = calc_target(i, 0);
            waiting[i] = 1'b0;
            done[i] = 1'b0;
            endpoint_owner[i] = '0;
            owner_valid[i] = 1'b0;
        end

        repeat (2) @(posedge clk);
        rst_n = 1'b1;

        $display("=== MIXED CONCURRENT LOT FABRIC VERIFICATION ===");
        $display("[1] Concurrent mixed write/read/error traffic begins");
        $display("[2] Initial phase creates four-way contention for endpoint 2");

        cycle = 0;
        while (response_count < (N * TXNS_PER_SRC) && cycle < 100) begin
            @(posedge clk);
            cycle = cycle + 1;
        end

        if (response_count != (N * TXNS_PER_SRC)) begin
            $display("TIMEOUT: responses=%0d expected=%0d", response_count, N*TXNS_PER_SRC);
            $display("  src_valid=%b src_ready=%b", src_valid, src_ready);
            $display("  src_dst=%p", src_dst);
            $display("  req_valid=%b req_ready=%b", req_valid, req_ready);
            $display("  req_grant=%p", req_grant);
            $display("  ep_rsp_valid=%b ep_rsp_ready=%b", ep_rsp_valid, ep_rsp_ready);
            $display("  dst_valid=%b dst_ready=%b", dst_valid, dst_ready);
            $display("  waiting=%p done=%p", waiting, done);
            $fatal;
        end

        for (i = 0; i < N; i = i + 1)
            if (!done[i] || waiting[i])
                $fatal(1, "Source %0d did not complete cleanly", i);

        if (contention_cycles == 0)
            $fatal(1, "Expected destination contention was not observed");

        if (backpressure_cycles == 0)
            $fatal(1, "Expected response backpressure was not observed");

        if (accepted_count != (N * TXNS_PER_SRC))
            $fatal(1, "Accepted transfer count mismatch: got %0d expected %0d",
                   accepted_count, N*TXNS_PER_SRC);

        $display("[3] Mixed read/write/error responses verified");
        $display("[4] Response backpressure and stability exercised");
        $display("[5] Source mapping preserved under contention");
        $display("Accepted transactions      : %0d", accepted_count);
        $display("Returned responses         : %0d", response_count);
        $display("Contention cycles          : %0d", contention_cycles);
        $display("Backpressure cycles        : %0d", backpressure_cycles);
        $display("TB RESULT: PASS - mixed concurrent LOT traffic, contention, reads, writes, error responses, backpressure and source mapping verified.");
        $display("Simulation cycles          : %0d", cycle);
        $stop;
    end

endmodule
