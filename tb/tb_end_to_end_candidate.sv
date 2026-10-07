// End-to-end protocol-neutral candidate transaction harness.
//
// Flow under test:
// candidate CPU request -> request XBAR -> behavioral endpoint -> response XBAR
// -> candidate CPU response.
//
// This does not represent the final MIPS bus or any final network protocol.

module tb_end_to_end_candidate;

    localparam int N = 4;
    localparam int ADDR_W = 32;
    localparam int CPU_DATA_W = 64;
    localparam int DATA_W = 32;
    localparam int DST_W = 2;
    localparam int LOT_W = ADDR_W + DATA_W + 1;

    logic clk;
    logic rst_n;

    // Candidate CPU side.
    logic cpu_req_valid;
    logic cpu_req_ready;
    logic cpu_req_write;
    logic [ADDR_W-1:0] cpu_req_addr;
    logic [DATA_W-1:0] cpu_req_wdata;

    logic cpu_rsp_valid;
    logic cpu_rsp_ready;
    logic [DATA_W-1:0] cpu_rsp_rdata;
    logic cpu_rsp_error;

    // Candidate adapter request-side LOT interface.
    logic lot_req_valid;
    logic lot_req_ready;
    logic [DST_W-1:0] lot_req_dst;
    logic [LOT_W-1:0] lot_req_payload;

    // Candidate adapter response-side LOT interface.
    logic lot_rsp_valid;
    logic lot_rsp_ready;
    logic [DATA_W-1:0] lot_rsp_rdata;
    logic lot_rsp_error;

    // Request XBAR.
    logic [N-1:0] req_src_valid;
    logic [N-1:0] req_src_ready;
    logic [N-1:0][DST_W-1:0] req_src_dst;
    logic [N-1:0][LOT_W-1:0] req_src_data;
    logic [N-1:0] req_dst_valid;
    logic [N-1:0] req_dst_ready;
    logic [N-1:0][LOT_W-1:0] req_dst_data;
    logic [N-1:0][N-1:0] req_grant;

    // Response XBAR.
    logic [N-1:0] rsp_src_valid;
    logic [N-1:0] rsp_src_ready;
    logic [N-1:0][DST_W-1:0] rsp_src_id;
    logic [N-1:0][DATA_W-1:0] rsp_src_data;
    logic [N-1:0] rsp_src_error;
    logic [N-1:0] rsp_dst_valid;
    logic [N-1:0] rsp_dst_ready;
    logic [N-1:0][DATA_W-1:0] rsp_dst_data;
    logic [N-1:0] rsp_dst_error;
    logic [N-1:0][N-1:0] rsp_grant;

    // Behavioral endpoint response state.
    logic endpoint_rsp_pending;
    logic [DATA_W-1:0] endpoint_rsp_data;
    logic endpoint_rsp_error;

    assign req_src_valid = {3'b000, lot_req_valid};
    assign req_src_dst[0] = lot_req_dst;
    assign req_src_data[0] = lot_req_payload;

    assign lot_req_ready = req_src_ready[0];

    assign req_dst_ready = '1;

    assign rsp_src_valid = {3'b000, endpoint_rsp_pending};
    assign rsp_src_id[0] = 2'd0; // Return to the candidate adapter (source 0).
    assign rsp_src_data[0] = endpoint_rsp_data;
    assign rsp_src_error[0] = endpoint_rsp_error;

    assign rsp_dst_ready = {3'b000, lot_rsp_ready};
    assign lot_rsp_valid = rsp_dst_valid[0];
    assign lot_rsp_rdata = rsp_dst_data[0];
    assign lot_rsp_error = rsp_dst_error[0];

    mips_mmio_adapter_candidate #(
        .ADDR_W(ADDR_W),
        .DATA_W(CPU_DATA_W),
        .DST_W(DST_W),
        .LOT_W(LOT_W)
    ) u_mips_candidate (
        .clk(clk),
        .rst_n(rst_n),
        .req_valid(cpu_req_valid),
        .req_ready(cpu_req_ready),
        .req_write(cpu_req_write),
        .req_addr(cpu_req_addr),
        .req_wdata(cpu_req_wdata),
        .rsp_valid(cpu_rsp_valid),
        .rsp_ready(cpu_rsp_ready),
        .rsp_rdata(cpu_rsp_rdata),
        .rsp_error(cpu_rsp_error),
        .lot_valid(lot_req_valid),
        .lot_ready(lot_req_ready),
        .lot_dst(lot_req_dst),
        .lot_payload(lot_req_payload),
        .lot_rsp_valid(lot_rsp_valid),
        .lot_rsp_ready(lot_rsp_ready),
        .lot_rsp_rdata(lot_rsp_rdata),
        .lot_rsp_error(lot_rsp_error)
    );

    lot_txn_router #(
        .N(N),
        .DATA_W(LOT_W),
        .DST_W(DST_W)
    ) u_req_router (
        .clk(clk),
        .rst_n(rst_n),
        .src_valid(req_src_valid),
        .src_ready(req_src_ready),
        .src_dst(req_src_dst),
        .src_data(req_src_data),
        .dst_valid(req_dst_valid),
        .dst_ready(req_dst_ready),
        .dst_data(req_dst_data),
        .grant(req_grant)
    );

    lot_rsp_router #(
        .N(N),
        .DATA_W(DATA_W),
        .SRC_W(DST_W)
    ) u_rsp_router (
        .clk(clk),
        .rst_n(rst_n),
        .src_valid(rsp_src_valid),
        .src_ready(rsp_src_ready),
        .src_id(rsp_src_id),
        .src_data(rsp_src_data),
        .src_error(rsp_src_error),
        .dst_valid(rsp_dst_valid),
        .dst_ready(rsp_dst_ready),
        .dst_data(rsp_dst_data),
        .dst_error(rsp_dst_error),
        .grant(rsp_grant)
    );

    always #5 clk = ~clk;

    // Simple endpoint model:
    // endpoint 2 accepts the request, waits one cycle, then returns
    // {address[15:0], write_data[15:0]} as a deterministic response.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            endpoint_rsp_pending <= 1'b0;
            endpoint_rsp_data <= '0;
            endpoint_rsp_error <= 1'b0;
        end else begin
            if (endpoint_rsp_pending && rsp_src_ready[0])
                endpoint_rsp_pending <= 1'b0;

            if (req_dst_valid[2] && req_dst_ready[2]) begin
                endpoint_rsp_pending <= 1'b1;
                endpoint_rsp_data <= {
                    req_dst_data[2][31:16],
                    req_dst_data[2][15:0]
                };
                endpoint_rsp_error <= 1'b0;
            end
        end
    end

    task automatic reset_dut;
        begin
            rst_n = 1'b0;
            cpu_req_valid = 1'b0;
            cpu_req_write = 1'b0;
            cpu_req_addr = '0;
            cpu_req_wdata = '0;
            cpu_rsp_ready = 1'b0;
            repeat (2) @(posedge clk);
            rst_n = 1'b1;
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

        // Request destination 2 using the candidate address map.
        cpu_req_write = 1'b1;
        cpu_req_addr = 32'h0002_0040;
        cpu_req_wdata = 32'h1234_ABCD;
        cpu_req_valid = 1'b1;

        wait (cpu_req_ready);
        @(posedge clk);
        cpu_req_valid = 1'b0;

        // The endpoint response must return through the response XBAR.
        wait (cpu_rsp_valid);

        if (cpu_rsp_rdata !== 32'h0040_ABCD) begin
            $error("End-to-end response mismatch: got %h expected 0040ABCD",
                   cpu_rsp_rdata);
            $fatal;
        end

        if (cpu_rsp_error !== 1'b0) begin
            $error("Unexpected endpoint error");
            $fatal;
        end

        cpu_rsp_ready = 1'b1;
        @(posedge clk);
        #1;
        cpu_rsp_ready = 1'b0;

        if (cpu_rsp_valid !== 1'b0) begin
            $error("CPU response did not complete");
            $fatal;
        end

        $display("TB RESULT: PASS - CPU request reached endpoint 2 and response returned through response XBAR.");
        $finish;
    end

endmodule
