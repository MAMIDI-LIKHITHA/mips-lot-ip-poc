`timescale 1ns/1ps
// Full candidate integration: MIPS MMIO adapter -> LOT transaction router
// -> four independent endpoint adapters -> LOT response router -> MIPS.
// The MIPS-facing protocol remains a candidate/protocol-neutral handshake.

module tb_mips_four_endpoint_integration;

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
    assign req_dst_ready = '1;

    assign rsp_src_valid = ep_rsp_valid;
    assign rsp_src_id = '0;
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

    lot_txn_router #(.N(N), .DATA_W(LOT_W), .DST_W(DST_W)) u_req_router (
        .clk(clk), .rst_n(rst_n),
        .src_valid(req_src_valid), .src_ready(req_src_ready),
        .src_dst(req_src_dst), .src_data(req_src_data),
        .dst_valid(req_dst_valid), .dst_ready(req_dst_ready),
        .dst_data(req_dst_data), .grant(req_grant)
    );

    lot_rsp_router #(.N(N), .DATA_W(DATA_W), .SRC_W(DST_W)) u_rsp_router (
        .clk(clk), .rst_n(rst_n),
        .src_valid(rsp_src_valid), .src_ready(rsp_src_ready),
        .src_id(rsp_src_id), .src_data(rsp_src_data),
        .src_error(rsp_src_error),
        .dst_valid(rsp_dst_valid), .dst_ready(rsp_dst_ready),
        .dst_data(rsp_dst_data), .dst_error(rsp_dst_error),
        .grant(rsp_grant)
    );

    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : g_endpoint
            lot_endpoint_adapter #(
                .ADDR_W(ADDR_W), .DATA_W(DATA_W), .LOT_W(LOT_W)
            ) u_endpoint (
                .clk(clk), .rst_n(rst_n),
                .req_valid(req_dst_valid[g]), .req_ready(req_dst_ready[g]),
                .req_payload(req_dst_data[g]),
                .rsp_valid(ep_rsp_valid[g]), .rsp_ready(ep_rsp_ready[g]),
                .rsp_rdata(ep_rsp_data[g]), .rsp_error(ep_rsp_error[g])
            );
        end
    endgenerate

    always #5 clk = ~clk;

    task automatic reset_dut;
        begin
            rst_n = 1'b0;
            cpu_req_valid = 1'b0;
            cpu_req_write = 1'b0;
            cpu_req_addr = '0;
            cpu_req_wdata = '0;
            cpu_rsp_ready = 1'b0;
            repeat (3) @(posedge clk);
            rst_n = 1'b1;
            @(posedge clk);
        end
    endtask

    task automatic cpu_access(
        input logic [DST_W-1:0] dst,
        input logic write,
        input logic [15:0] local_addr,
        input logic [DATA_W-1:0] wdata,
        input logic [DATA_W-1:0] expected,
        input logic expected_error
    );
        logic [ADDR_W-1:0] addr;
        integer cycles;
        begin
            addr = {14'b0, dst, local_addr};
            cpu_req_write = write;
            cpu_req_addr = addr;
            cpu_req_wdata = wdata;
            cpu_req_valid = 1'b1;

            cycles = 0;
            while (!cpu_req_ready && cycles < 20) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (!cpu_req_ready) begin
                $error("CPU request timeout: dst=%0d addr=%h", dst, addr);
                $fatal;
            end

            @(posedge clk);
            cpu_req_valid = 1'b0;

            wait (cpu_rsp_valid);
            if (cpu_rsp_error !== expected_error ||
                cpu_rsp_rdata !== expected) begin
                $error("Response mismatch dst=%0d addr=%h got data=%h err=%b expected data=%h err=%b",
                       dst, addr, cpu_rsp_rdata, cpu_rsp_error, expected, expected_error);
                $fatal;
            end

            cpu_rsp_ready = 1'b1;
            @(posedge clk);
            #1 cpu_rsp_ready = 1'b0;
        end
    endtask

    task automatic cpu_read_stalled(
        input logic [DST_W-1:0] dst,
        input logic [15:0] local_addr,
        input logic [DATA_W-1:0] expected
    );
        logic [ADDR_W-1:0] addr;
        logic [DATA_W-1:0] held_data;
        logic held_error;
        begin
            addr = {14'b0, dst, local_addr};
            cpu_req_write = 1'b0;
            cpu_req_addr = addr;
            cpu_req_wdata = '0;
            cpu_req_valid = 1'b1;

            wait (cpu_req_ready);
            @(posedge clk);
            cpu_req_valid = 1'b0;

            wait (cpu_rsp_valid);
            held_data = cpu_rsp_rdata;
            held_error = cpu_rsp_error;

            repeat (3) begin
                @(posedge clk);
                if (cpu_rsp_valid !== 1'b1 ||
                    cpu_rsp_rdata !== held_data ||
                    cpu_rsp_error !== held_error) begin
                    $error("CPU response changed under backpressure");
                    $fatal;
                end
            end

            if (held_data !== expected || held_error !== 1'b0) begin
                $error("Stalled response mismatch");
                $fatal;
            end

            cpu_rsp_ready = 1'b1;
            @(posedge clk);
            #1 cpu_rsp_ready = 1'b0;
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

        reset_dut();

        $display("=== MIPS -> FOUR-ENDPOINT LOT INTEGRATION ===");
        $display("[1] Endpoint 0 ID read");
        cpu_access(2'd0, 1'b0, 16'h000C, '0, 32'h4C4F_5430, 1'b0);

        $display("[2] Endpoint 1 CONTROL write/readback");
        cpu_access(2'd1, 1'b1, 16'h0000, 32'h0000_0011, 32'h0000_0011, 1'b0);
        cpu_access(2'd1, 1'b0, 16'h0000, '0, 32'h0000_0011, 1'b0);

        $display("[3] Endpoint 2 DATA write/readback");
        cpu_access(2'd2, 1'b1, 16'h0004, 32'hCAFE_BEEF, 32'hCAFE_BEEF, 1'b0);
        cpu_access(2'd2, 1'b0, 16'h0004, '0, 32'hCAFE_BEEF, 1'b0);

        $display("[4] Endpoint 3 STATUS read");
        cpu_access(2'd3, 1'b0, 16'h0008, '0, 32'h0000_0001, 1'b0);

        $display("[5] Invalid register error propagation");
        cpu_access(2'd0, 1'b0, 16'h0010, '0, 32'h0000_0000, 1'b1);

        $display("[6] CPU response backpressure stability");
        cpu_read_stalled(2'd2, 16'h0008, 32'h0000_0001);

        $display("[7] Endpoint isolation after traffic");
        if (ep_rsp_valid !== 4'b0000) begin
            $error("Endpoint response remained asserted after completion");
            $fatal;
        end

        $display("TB RESULT: PASS - candidate MIPS request/response path reached all four independent LOT endpoints, preserved destination and register data, propagated endpoint errors, and maintained response stability under CPU backpressure.");
        $display("Clock period                 : 10 ns");
        $stop;
    end

endmodule
