module tb_mips_mmio_adapter_candidate;

    localparam int ADDR_W = 32;
    localparam int CPU_DATA_W = 64;
    localparam int DATA_W = 32;
    localparam int DST_W = 2;
    localparam int LOT_W = ADDR_W + DATA_W + 1;

    logic clk, rst_n;
    logic req_valid, req_ready, req_write;
    logic [ADDR_W-1:0] req_addr;
    logic [DATA_W-1:0] req_wdata;
    logic rsp_valid, rsp_ready;
    logic [DATA_W-1:0] rsp_rdata;
    logic rsp_error;
    logic lot_valid, lot_ready;
    logic [DST_W-1:0] lot_dst;
    logic [LOT_W-1:0] lot_payload;
    logic lot_rsp_valid, lot_rsp_ready;
    logic [DATA_W-1:0] lot_rsp_rdata;
    logic lot_rsp_error;

    mips_mmio_adapter_candidate #(
        .ADDR_W(ADDR_W), .DATA_W(CPU_DATA_W),
        .DST_W(DST_W), .LOT_W(LOT_W)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .req_valid(req_valid), .req_ready(req_ready),
        .req_write(req_write), .req_addr(req_addr), .req_wdata(req_wdata),
        .rsp_valid(rsp_valid), .rsp_ready(rsp_ready),
        .rsp_rdata(rsp_rdata), .rsp_error(rsp_error),
        .lot_valid(lot_valid), .lot_ready(lot_ready),
        .lot_dst(lot_dst), .lot_payload(lot_payload),
        .lot_rsp_valid(lot_rsp_valid), .lot_rsp_ready(lot_rsp_ready),
        .lot_rsp_rdata(lot_rsp_rdata), .lot_rsp_error(lot_rsp_error)
    );

    always #5 clk = ~clk;

    task automatic reset_dut;
        begin
            rst_n = 1'b0;
            req_valid = 1'b0;
            req_write = 1'b0;
            req_addr = '0;
            req_wdata = '0;
            rsp_ready = 1'b0;
            lot_ready = 1'b1;
            lot_rsp_valid = 1'b0;
            lot_rsp_rdata = '0;
            lot_rsp_error = 1'b0;
            repeat (2) @(posedge clk);
            #1;
            if (req_ready || lot_valid || rsp_valid || lot_rsp_ready)
                $fatal(1, "Adapter not quiescent during reset");
            rst_n = 1'b1;
            @(posedge clk);
            #1;
        end
    endtask

    task automatic issue_request(
        input logic write_i,
        input logic [ADDR_W-1:0] addr_i,
        input logic [DATA_W-1:0] data_i,
        input logic [DST_W-1:0] expected_dst
    );
        logic [LOT_W-1:0] expected_payload;
        begin
            expected_payload = {write_i, addr_i, data_i};
            req_write = write_i;
            req_addr = addr_i;
            req_wdata = data_i;
            req_valid = 1'b1;
            wait (req_ready);
            #1;
            if (!lot_valid || lot_dst !== expected_dst ||
                lot_payload !== expected_payload)
                $fatal(1, "Request decode/payload mismatch");
            @(posedge clk);
            #1;
            req_valid = 1'b0;
        end
    endtask

    task automatic return_response(
        input logic [DATA_W-1:0] data_i,
        input logic error_i
    );
        begin
            wait (lot_rsp_ready);
            lot_rsp_rdata = data_i;
            lot_rsp_error = error_i;
            lot_rsp_valid = 1'b1;
            @(posedge clk);
            #1;
            lot_rsp_valid = 1'b0;
            wait (rsp_valid);
            if (rsp_rdata !== data_i || rsp_error !== error_i)
                $fatal(1, "Response mismatch");
            rsp_ready = 1'b1;
            @(posedge clk);
            #1;
            rsp_ready = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        reset_dut();

        $display("=== MIPS MMIO CANDIDATE ADAPTER VERIFICATION ===");

        $display("[1] Four destination decodes + payload encoding");
        issue_request(1'b1, 32'h0000_0010, 32'h1111_0000, 2'd0);
        return_response(32'h1111_0000, 1'b0);

        issue_request(1'b0, 32'h0001_0020, 32'h0000_0000, 2'd1);
        return_response(32'h2222_0001, 1'b0);

        issue_request(1'b1, 32'h0002_0030, 32'h3333_0002, 2'd2);
        return_response(32'h3333_0002, 1'b0);

        issue_request(1'b0, 32'h0003_0040, 32'h0000_0000, 2'd3);
        return_response(32'h4444_0003, 1'b0);

        $display("[2] LOT-side request backpressure and stability");
        lot_ready = 1'b0;
        req_write = 1'b1;
        req_addr = 32'h0002_0050;
        req_wdata = 32'hAAAA_5555;
        req_valid = 1'b1;
        #1;
        if (req_ready || !lot_valid)
            $fatal(1, "Unexpected request handshake while LOT side stalled");
        repeat (2) begin
            @(posedge clk);
            #1;
            if (!lot_valid || lot_dst !== 2'd2 ||
                lot_payload !== {1'b1,32'h0002_0050,32'hAAAA_5555})
                $fatal(1, "LOT request changed while stalled");
        end
        lot_ready = 1'b1;
        wait (req_ready);
        @(posedge clk);
        #1;
        req_valid = 1'b0;
        return_response(32'hAAAA_5555, 1'b0);

        $display("[3] Single-outstanding-request enforcement");
        req_write = 1'b1;
        req_addr = 32'h0001_0060;
        req_wdata = 32'h1234_5678;
        req_valid = 1'b1;
        wait (req_ready);
        @(posedge clk);
        #1;
        if (req_ready)
            $fatal(1, "Second CPU request accepted while response outstanding");
        req_valid = 1'b0;
        return_response(32'h1234_5678, 1'b0);

        $display("[4] CPU response backpressure + error stability");
        req_write = 1'b0;
        req_addr = 32'h0002_0070;
        req_wdata = '0;
        req_valid = 1'b1;
        wait (req_ready);
        @(posedge clk);
        #1;
        req_valid = 1'b0;
        wait (lot_rsp_ready);
        lot_rsp_rdata = 32'hDEAD_BEEF;
        lot_rsp_error = 1'b1;
        lot_rsp_valid = 1'b1;
        @(posedge clk);
        #1;
        lot_rsp_valid = 1'b0;
        wait (rsp_valid);
        repeat (3) begin
            #1;
            if (!rsp_valid || rsp_rdata !== 32'hDEAD_BEEF || !rsp_error)
                $fatal(1, "CPU response changed while stalled");
            @(posedge clk);
        end
        rsp_ready = 1'b1;
        @(posedge clk);
        #1;
        rsp_ready = 1'b0;
        if (rsp_valid)
            $fatal(1, "CPU response did not complete");

        $display("[5] Invalid-address suppression");
        req_addr = 32'h8000_0000;
        req_write = 1'b0;
        req_wdata = '0;
        req_valid = 1'b1;
        #1;
        if (req_ready || lot_valid)
            $fatal(1, "Invalid address was not suppressed");
        repeat (2) @(posedge clk);
        req_valid = 1'b0;

        $display("[6] Reset quiescence + recovery");
        rst_n = 1'b0;
        #1;
        if (req_ready || lot_valid || rsp_valid)
            $fatal(1, "Adapter not quiescent during reset");
        rst_n = 1'b1;
        @(posedge clk);
        #1;
        issue_request(1'b1, 32'h0003_0080, 32'hFACE_CAFE, 2'd3);
        return_response(32'hFACE_CAFE, 1'b0);

        $display("TB RESULT: PASS - candidate MIPS MMIO adapter destination decode, payload encoding, request/response backpressure, single-outstanding behavior, error propagation, invalid-address suppression and reset recovery verified.");
        $stop;
    end

endmodule
