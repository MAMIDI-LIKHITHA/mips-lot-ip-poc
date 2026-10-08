// Multi-endpoint protocol-neutral verification harness.
//
// Verifies that all four 4x4 request-XBAR destinations can reach an
// independent LOT endpoint adapter instance and return a response through
// the shared response fabric.

module tb_lot_multi_endpoint;

    localparam int N = 4;
    localparam int ADDR_W = 32;
    localparam int CPU_DATA_W = 64;
    localparam int DATA_W = 32;
    localparam int DST_W = 2;
    localparam int LOT_W = ADDR_W + DATA_W + 1;

    logic clk, rst_n;

    logic cpu_req_valid, cpu_req_ready, cpu_req_write;
    logic [ADDR_W-1:0] cpu_req_addr;
    logic [DATA_W-1:0] cpu_req_wdata;
    logic cpu_rsp_valid, cpu_rsp_ready, cpu_rsp_error;
    logic [DATA_W-1:0] cpu_rsp_rdata;

    logic lot_req_valid, lot_req_ready;
    logic [DST_W-1:0] lot_req_dst;
    logic [LOT_W-1:0] lot_req_payload;

    logic lot_rsp_valid, lot_rsp_ready, lot_rsp_error;
    logic [DATA_W-1:0] lot_rsp_rdata;

    logic [N-1:0] req_src_valid, req_src_ready;
    logic [N-1:0][DST_W-1:0] req_src_dst;
    logic [N-1:0][LOT_W-1:0] req_src_data;
    logic [N-1:0] req_dst_valid, req_dst_ready;
    logic [N-1:0] ep_req_ready;
    logic [N-1:0][LOT_W-1:0] req_dst_data;
    logic [N-1:0][N-1:0] req_grant;

    logic [N-1:0] ep_rsp_valid, ep_rsp_ready, ep_rsp_error;
    logic [N-1:0][DATA_W-1:0] ep_rsp_data;

    logic [N-1:0] rsp_src_valid, rsp_src_ready;
    logic [N-1:0][DST_W-1:0] rsp_src_id;
    logic [N-1:0][DATA_W-1:0] rsp_src_data;
    logic [N-1:0] rsp_src_error;
    logic [N-1:0] rsp_dst_valid, rsp_dst_ready;
    logic [N-1:0][DATA_W-1:0] rsp_dst_data;
    logic [N-1:0] rsp_dst_error;
    logic [N-1:0][N-1:0] rsp_grant;

    assign req_src_valid = {3'b000, lot_req_valid};
    assign req_src_dst[0] = lot_req_dst;
    assign req_src_data[0] = lot_req_payload;
    assign lot_req_ready = req_src_ready[0];
    assign req_dst_ready = ep_req_ready;

    assign rsp_src_valid = ep_rsp_valid;
    assign rsp_src_id[0] = 2'd0;
    assign rsp_src_id[1] = 2'd0;
    assign rsp_src_id[2] = 2'd0;
    assign rsp_src_id[3] = 2'd0;
    assign rsp_src_data = ep_rsp_data;
    assign rsp_src_error = ep_rsp_error;
    assign ep_rsp_ready = rsp_src_ready;

    assign rsp_dst_ready = {3'b000, lot_rsp_ready};
    assign lot_rsp_valid = rsp_dst_valid[0];
    assign lot_rsp_rdata = rsp_dst_data[0];
    assign lot_rsp_error = rsp_dst_error[0];

    mips_mmio_adapter_candidate #(
        .ADDR_W(ADDR_W), .DATA_W(CPU_DATA_W), .DST_W(DST_W), .LOT_W(LOT_W)
    ) u_mips_candidate (
        .clk(clk), .rst_n(rst_n),
        .req_valid(cpu_req_valid), .req_ready(cpu_req_ready),
        .req_write(cpu_req_write), .req_addr(cpu_req_addr),
        .req_wdata(cpu_req_wdata),
        .rsp_valid(cpu_rsp_valid), .rsp_ready(cpu_rsp_ready),
        .rsp_rdata(cpu_rsp_rdata), .rsp_error(cpu_rsp_error),
        .lot_valid(lot_req_valid), .lot_ready(lot_req_ready),
        .lot_dst(lot_req_dst), .lot_payload(lot_req_payload),
        .lot_rsp_valid(lot_rsp_valid), .lot_rsp_ready(lot_rsp_ready),
        .lot_rsp_rdata(lot_rsp_rdata), .lot_rsp_error(lot_rsp_error)
    );

    lot_txn_router #(
        .N(N), .DATA_W(LOT_W), .DST_W(DST_W)
    ) u_req_router (
        .clk(clk), .rst_n(rst_n),
        .src_valid(req_src_valid), .src_ready(req_src_ready),
        .src_dst(req_src_dst), .src_data(req_src_data),
        .dst_valid(req_dst_valid), .dst_ready(req_dst_ready),
        .dst_data(req_dst_data), .grant(req_grant)
    );

    lot_rsp_router #(
        .N(N), .DATA_W(DATA_W), .SRC_W(DST_W)
    ) u_rsp_router (
        .clk(clk), .rst_n(rst_n),
        .src_valid(rsp_src_valid), .src_ready(rsp_src_ready),
        .src_id(rsp_src_id), .src_data(rsp_src_data),
        .src_error(rsp_src_error),
        .dst_valid(rsp_dst_valid), .dst_ready(rsp_dst_ready),
        .dst_data(rsp_dst_data), .dst_error(rsp_dst_error),
        .grant(rsp_grant)
    );

    lot_endpoint_adapter #(.ADDR_W(ADDR_W), .DATA_W(DATA_W), .LOT_W(LOT_W))
        u_endpoint0 (.clk(clk), .rst_n(rst_n), .req_valid(req_dst_valid[0]),
        .req_ready(ep_req_ready[0]), .req_payload(req_dst_data[0]),
        .rsp_valid(ep_rsp_valid[0]), .rsp_ready(ep_rsp_ready[0]),
        .rsp_rdata(ep_rsp_data[0]), .rsp_error(ep_rsp_error[0]));

    lot_endpoint_adapter #(.ADDR_W(ADDR_W), .DATA_W(DATA_W), .LOT_W(LOT_W))
        u_endpoint1 (.clk(clk), .rst_n(rst_n), .req_valid(req_dst_valid[1]),
        .req_ready(ep_req_ready[1]), .req_payload(req_dst_data[1]),
        .rsp_valid(ep_rsp_valid[1]), .rsp_ready(ep_rsp_ready[1]),
        .rsp_rdata(ep_rsp_data[1]), .rsp_error(ep_rsp_error[1]));

    lot_endpoint_adapter #(.ADDR_W(ADDR_W), .DATA_W(DATA_W), .LOT_W(LOT_W))
        u_endpoint2 (.clk(clk), .rst_n(rst_n), .req_valid(req_dst_valid[2]),
        .req_ready(ep_req_ready[2]), .req_payload(req_dst_data[2]),
        .rsp_valid(ep_rsp_valid[2]), .rsp_ready(ep_rsp_ready[2]),
        .rsp_rdata(ep_rsp_data[2]), .rsp_error(ep_rsp_error[2]));

    lot_endpoint_adapter #(.ADDR_W(ADDR_W), .DATA_W(DATA_W), .LOT_W(LOT_W))
        u_endpoint3 (.clk(clk), .rst_n(rst_n), .req_valid(req_dst_valid[3]),
        .req_ready(ep_req_ready[3]), .req_payload(req_dst_data[3]),
        .rsp_valid(ep_rsp_valid[3]), .rsp_ready(ep_rsp_ready[3]),
        .rsp_rdata(ep_rsp_data[3]), .rsp_error(ep_rsp_error[3]));

    always #5 clk = ~clk;

    task automatic wait_for_response(input logic [DST_W-1:0] dst);
        integer cycles;
        begin
            cycles = 0;
            while (!cpu_rsp_valid && cycles < 20) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (!cpu_rsp_valid) begin
                $display("TIMEOUT endpoint %0d", dst);
                $display("  cpu_req_valid=%b cpu_req_ready=%b busy_path_rsp_valid=%b", cpu_req_valid, cpu_req_ready, cpu_rsp_valid);
                $display("  req_valid=%b req_ready=%b req_dst_valid=%b req_dst_ready=%b", lot_req_valid, lot_req_ready, req_dst_valid, req_dst_ready);
                $display("  rsp_src_valid=%b rsp_src_ready=%b rsp_dst_valid=%b rsp_dst_ready=%b", rsp_src_valid, rsp_src_ready, rsp_dst_valid, rsp_dst_ready);
                $display("  ep_rsp_valid=%b ep_rsp_ready=%b", ep_rsp_valid, ep_rsp_ready);
                $fatal;
            end
        end
    endtask

    task automatic cpu_read(
        input logic [DST_W-1:0] dst,
        input logic [DATA_W-1:0] expected
    );
        logic [ADDR_W-1:0] addr;
        begin
            addr = {dst, 14'b0, 16'h000C};
            cpu_req_write = 1'b0;
            cpu_req_addr = addr;
            cpu_req_wdata = '0;
            cpu_req_valid = 1'b1;
            begin : request_wait
                integer req_cycles;
                req_cycles = 0;
                while (!cpu_req_ready && req_cycles < 20) begin
                    @(posedge clk);
                    req_cycles = req_cycles + 1;
                end
                if (!cpu_req_ready) begin
                    $display("REQUEST TIMEOUT endpoint %0d", dst);
                    $display("  cpu_req_valid=%b cpu_req_ready=%b", cpu_req_valid, cpu_req_ready);
                    $display("  lot_req_valid=%b lot_req_ready=%b lot_req_dst=%0d", lot_req_valid, lot_req_ready, lot_req_dst);
                    $display("  req_src_valid=%b req_src_ready=%b req_dst_valid=%b req_dst_ready=%b", req_src_valid, req_src_ready, req_dst_valid, req_dst_ready);
                    $display("  req_grant=%b", req_grant);
                    $display("  rsp_src_valid=%b rsp_src_ready=%b rsp_dst_valid=%b rsp_dst_ready=%b", rsp_src_valid, rsp_src_ready, rsp_dst_valid, rsp_dst_ready);
                    $display("  ep_rsp_valid=%b ep_rsp_ready=%b", ep_rsp_valid, ep_rsp_ready);
                    $fatal;
                end
            end
            @(posedge clk);
            cpu_req_valid = 1'b0;

            // Assert response-ready before the sampling edge.  This avoids
            // a testbench race where cpu_rsp_ready is driven after @(posedge clk)
            // and therefore misses the response handshake.
            cpu_rsp_ready = 1'b1;
            wait_for_response(dst);
            if (cpu_rsp_error !== 1'b0 || cpu_rsp_rdata !== expected) begin
                $error("Endpoint %0d response mismatch: got data=%h error=%b expected=%h",
                       dst, cpu_rsp_rdata, cpu_rsp_error, expected);
                $fatal;
            end

            @(posedge clk);
            #1 cpu_rsp_ready = 1'b0;

            // Allow the candidate adapter's registered busy/response state to
            // settle before starting the next independent transaction.
            begin : idle_wait
                integer idle_cycles;
                idle_cycles = 0;
                while (u_mips_candidate.busy && idle_cycles < 5) begin
                    @(posedge clk);
                    idle_cycles = idle_cycles + 1;
                end
                if (u_mips_candidate.busy) begin
                    $display("BUSY CLEAR TIMEOUT endpoint %0d", dst);
                    $display("  busy=%b response_valid=%b rsp_valid=%b rsp_ready=%b",
                             u_mips_candidate.busy, u_mips_candidate.response_valid,
                             cpu_rsp_valid, cpu_rsp_ready);
                    $fatal;
                end
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        cpu_req_valid = 1'b0;
        cpu_req_write = 1'b0;
        cpu_req_addr = '0;
        cpu_req_wdata = '0;
        cpu_rsp_ready = 1'b0;

        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        $display("=== MULTI-ENDPOINT LOT FABRIC VERIFICATION ===");
        $display("[1] Endpoint 0 ID read");
        cpu_read(2'd0, 32'h4C4F_5430);

        $display("[2] Endpoint 1 ID read");
        cpu_read(2'd1, 32'h4C4F_5430);

        $display("[3] Endpoint 2 ID read");
        cpu_read(2'd2, 32'h4C4F_5430);

        $display("[4] Endpoint 3 ID read");
        cpu_read(2'd3, 32'h4C4F_5430);

        $display("[5] Endpoint isolation check");
        if (ep_rsp_valid !== 4'b0000) begin
            $error("Endpoint response remained asserted after completed transactions");
            $fatal;
        end

        $display("TB RESULT: PASS - all four XBAR destinations reached independent LOT endpoint adapters and returned correct register responses through the shared response fabric.");
        $stop;
    end

endmodule
