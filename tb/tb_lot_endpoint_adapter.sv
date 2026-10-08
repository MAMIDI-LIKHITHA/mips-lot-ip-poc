`timescale 1ns/1ps
module tb_lot_endpoint_adapter;
    localparam int ADDR_W=32, DATA_W=32, LOT_W=65;
    logic clk,rst_n,req_valid,req_ready,rsp_valid,rsp_ready,rsp_error;
    logic [LOT_W-1:0] req_payload;
    logic [DATA_W-1:0] rsp_rdata;
    lot_endpoint_adapter #(.ADDR_W(ADDR_W),.DATA_W(DATA_W),.LOT_W(LOT_W)) dut (.*);
    always #5 clk=~clk;
    task automatic write_reg(input logic [31:0] a,input logic [31:0] d);
      begin req_payload={1'b1,a,d}; req_valid=1; wait(req_ready); @(posedge clk); req_valid=0; wait(rsp_valid);
        if(rsp_error||rsp_rdata!==d) $fatal(1,"Write failed at %h",a); rsp_ready=1; @(posedge clk); rsp_ready=0; end
    endtask
    task automatic read_reg(input logic [31:0] a,input logic [31:0] exp,input logic err);
      begin req_payload={1'b0,a,32'b0}; req_valid=1; wait(req_ready); @(posedge clk); req_valid=0; wait(rsp_valid);
        if(rsp_error!==err || rsp_rdata!==exp) $fatal(1,"Read failed at %h: got %h err=%b",a,rsp_rdata,rsp_error); rsp_ready=1; @(posedge clk); rsp_ready=0; end
    endtask
    initial begin
      clk=0; rst_n=0; req_valid=0; req_payload='0; rsp_ready=0;
      repeat(2) @(posedge clk); rst_n=1;
      write_reg(32'h0,32'hA5); read_reg(32'h0,32'hA5,0);
      write_reg(32'h4,32'h1234_ABCD); read_reg(32'h4,32'h1234_ABCD,0);
      read_reg(32'h8,32'h1,0); read_reg(32'hC,32'h4C4F_5430,0);
      read_reg(32'h10,32'h0,1);
      $display("TB RESULT: PASS - LOT endpoint register reads/writes, status/ID reads and invalid-address error response verified.");
      $stop;
    end
endmodule