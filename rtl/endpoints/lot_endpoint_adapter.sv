module lot_endpoint_adapter #(
    parameter int ADDR_W = 32,
    parameter int DATA_W = 32,
    parameter int LOT_W  = ADDR_W + DATA_W + 1
) (
    input logic clk, input logic rst_n,
    input logic req_valid, output logic req_ready,
    input logic [LOT_W-1:0] req_payload,
    output logic rsp_valid, input logic rsp_ready,
    output logic [DATA_W-1:0] rsp_rdata, output logic rsp_error
);

    localparam logic [15:0] REG_CONTROL = 16'h0000;
    localparam logic [15:0] REG_DATA    = 16'h0004;
    localparam logic [15:0] REG_STATUS  = 16'h0008;
    localparam logic [15:0] REG_ID      = 16'h000C;

    logic [31:0] control_reg, data_reg;
    logic response_pending;
    logic [DATA_W-1:0] response_data;
    logic response_error;
    logic req_write;
    logic [ADDR_W-1:0] req_addr;
    logic [DATA_W-1:0] req_wdata;

    assign req_write = req_payload[LOT_W-1];
    assign req_addr  = req_payload[LOT_W-2 -: ADDR_W];
    assign req_wdata = req_payload[DATA_W-1:0];
    assign req_ready = !response_pending && rst_n;
    assign rsp_valid = response_pending;
    assign rsp_rdata = response_data;
    assign rsp_error = response_error;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            control_reg <= '0; data_reg <= '0;
            response_pending <= 1'b0; response_data <= '0; response_error <= 1'b0;
        end else begin
            if (response_pending && rsp_ready) response_pending <= 1'b0;
            if (req_valid && req_ready) begin
                response_pending <= 1'b1;
                response_error <= 1'b0;
                if (req_write) begin
                    case (req_addr[15:0])
                        REG_CONTROL: control_reg <= req_wdata;
                        REG_DATA:    data_reg <= req_wdata;
                        default:    response_error <= 1'b1;
                    endcase
                    response_data <= req_wdata;
                end else begin
                    case (req_addr[15:0])
                        REG_CONTROL: response_data <= control_reg;
                        REG_DATA:    response_data <= data_reg;
                        REG_STATUS:  response_data <= 32'h0000_0001;
                        REG_ID:      response_data <= 32'h4C4F_5430;
                        default: begin response_data <= '0; response_error <= 1'b1; end
                    endcase
                end
            end
        end
    end
endmodule