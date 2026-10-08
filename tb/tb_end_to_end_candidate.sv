// End-to-end protocol-neutral candidate transaction harness.
//
// Flow under test:
// candidate CPU request -> request XBAR -> LOT endpoint adapter
// -> response XBAR -> candidate CPU response.
//
// This does not represent the final MIPS bus or any final network protocol.
// Endpoint 2 is exercised using its local register map.

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

    assign req_src_valid = {3'b000, lot_req_valid};
    assign req_src_dst[0] = lot_req_dst;
    assign req_src_data[0] = lot_req_payload;

    assign lot_req_ready = req_src_ready[0];

    // All request destinations are available. Endpoint 2 is the active one.
    assign req_dst_ready = '1;

    // Endpoint 2 response returns to source 0, the candidate adapter.
    logic endpoint_rsp_valid;
    logic endpoint_rsp_ready;
    logic [DATA_W-1:0] endpoint_rsp_data;
    logic endpoint_rsp_error;

    assign rsp_src_valid = {3'b000, endpoint_rsp_valid};
    assign rsp_src_id[0] = 2'd0;
    assign rsp_src_data[0] = endpoint_rsp_data;
    assign rsp_src_error[0] = endpoint_rsp_error;

    assign endpoint_rsp_ready = rsp_src_ready[0];

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

    lot_endpoint_adapter #(
        .ADDR_W(ADDR_W),
        .DATA_W(DATA_W),
        .LOT_W(LOT_W)
    ) u_endpoint2 (
        .clk(clk),
        .rst_n(rst_n),
        .req_valid(req_dst_valid[2]),
        .req_ready(req_dst_ready[2]),
        .req_payload(req_dst_data[2]),
        .rsp_valid(endpoint_rsp_valid),
        .rsp_ready(endpoint_rsp_ready),
        .rsp_rdata(endpoint_rsp_data),
        .rsp_error(endpoint_rsp_error)
    );

    always #5 clk = ~clk;

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
            @(posedge clk);
        end
    endtask

    task automatic cpu_write(
        input logic [ADDR_W-1:0] addr,
        input logic [DATA_W-1:0] data
    );
        begin
            cpu_req_write = 1'b1;
            cpu_req_addr = addr;
            cpu_req_wdata = data;
            cpu_req_valid = 1'b1;

            wait (cpu_req_ready);
            @(posedge clk);
            cpu_req_valid = 1'b0;

            wait (cpu_rsp_valid);
            if (cpu_rsp_error !== 1'b0) begin
                $error("Unexpected write error at address %h", addr);
                $fatal;
            end
            if (cpu_rsp_rdata !== data) begin
                $error("Write response mismatch at %h: got %h expected %h",
                       addr, cpu_rsp_rdata, data);
                $fatal;
            end

            cpu_rsp_ready = 1'b1;
            @(posedge clk);
            #1;
            cpu_rsp_ready = 1'b0;
        end
    endtask

    task automatic cpu_read(
        input logic [ADDR_W-1:0] addr,
        input logic [DATA_W-1:0] expected,
        input logic expected_error
    );
        begin
            cpu_req_write = 1'b0;
            cpu_req_addr = addr;
            cpu_req_wdata = '0;
            cpu_req_valid = 1'b1;

            wait (cpu_req_ready);
            @(posedge clk);
            cpu_req_valid = 1'b0;

            wait (cpu_rsp_valid);
            if (cpu_rsp_error !== expected_error) begin
                $error("Read error mismatch at %h: got %b expected %b",
                       addr, cpu_rsp_error, expected_error);
                $fatal;
            end
            if (cpu_rsp_rdata !== expected) begin
                $error("Read response mismatch at %h: got %h expected %h",
                       addr, cpu_rsp_rdata, expected);
                $fatal;
            end

            cpu_rsp_ready = 1'b1;
            @(posedge clk);
            #1;
            cpu_rsp_ready = 1'b0;
        end
    endtask

    task automatic cpu_read_with_backpressure(
        input logic [ADDR_W-1:0] addr,
        input logic [DATA_W-1:0] expected
    );
        logic [DATA_W-1:0] held_data;
        logic held_error;
        begin
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
                    $error("Response changed while CPU response was stalled");
                    $fatal;
                end
            end

            if (held_data !== expected || held_error !== 1'b0) begin
                $error("Backpressure response mismatch: got %h error %b expected %h",
                       held_data, held_error, expected);
                $fatal;
            end

            cpu_rsp_ready = 1'b1;
            @(posedge clk);
            #1;
            cpu_rsp_ready = 1'b0;

            if (cpu_rsp_valid !== 1'b0) begin
                $error("Stalled CPU response did not complete");
                $fatal;
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

        reset_dut();

        // Endpoint 2 local register map:
        // 0x0000 CONTROL RW
        // 0x0004 DATA RW
        // 0x0008 STATUS RO = 1
        // 0x000C ID RO = "LOT0"
        // The candidate address map adds 0x0002_0000 for endpoint 2.

        $display("=== END-TO-END LOT ENDPOINT VERIFICATION ===");

        $display("[1] CONTROL write");
        cpu_write(32'h0002_0000, 32'h0000_00A5);

        $display("[2] CONTROL readback");
        cpu_read(32'h0002_0000, 32'h0000_00A5, 1'b0);

        $display("[3] DATA write");
        cpu_write(32'h0002_0004, 32'hCAFE_BEEF);

        $display("[4] DATA readback");
        cpu_read(32'h0002_0004, 32'hCAFE_BEEF, 1'b0);

        $display("[5] STATUS read");
        cpu_read(32'h0002_0008, 32'h0000_0001, 1'b0);

        $display("[6] ID read");
        cpu_read(32'h0002_000C, 32'h4C4F_5430, 1'b0);

        $display("[7] Invalid endpoint register");
        cpu_read(32'h0002_0010, 32'h0000_0000, 1'b1);

        $display("[8] Response backpressure stability");
        cpu_read_with_backpressure(32'h0002_0008, 32'h0000_0001);

        $display("TB RESULT: PASS - CPU requests traversed the MIPS candidate adapter, LOT transaction router, request XBAR, endpoint register adapter, response XBAR and LOT response router; register access, error propagation and response backpressure were verified.");

        $stop;
    end

endmodule
