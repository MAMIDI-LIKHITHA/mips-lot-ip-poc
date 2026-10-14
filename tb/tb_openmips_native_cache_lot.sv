`timescale 1ns/1ps
module tb_openmips_native_cache_lot;
  localparam PABITS=36;
  reg clk=0, reset=1;
  always #5 clk=~clk;
  reg [9:0] VAddressIn_C=0;
  reg [23:0] PAddressIn_C=24'h01F000;
  reg PAddressValid_C=0;
  reg [2:0] CacheAttr_C=3'b010;
  reg Stall_C=0;
  reg [31:0] DataIn_C=0;
  reg Read_C=0;
  reg [3:0] Write_C=0;
  reg DoCacheOp_C=0;
  reg [2:0] CacheOp_C=0;
  reg [27:0] CacheOpData_C=0;
  wire [31:0] DataOut_C;
  wire Ready_C;
  wire [33:0] Address_M;
  wire ReadLine_M, ReadWord_M, LineOutReady_M, WordOutReady_M;
  wire [3:0] WordOutBE_M;
  wire WordOutPAddressValid_M, ReadWordPAddressValid_M;
  wire [127:0] DataOut_M;
  wire [31:0] DataIn_M;
  wire [1:0] DataInOffset_M;
  wire Ready_M;

  wire [29:0] ram_addr;
  wire ram_read_line, ram_read_word, ram_write_line_ready, ram_write_word_ready;
  wire [3:0] ram_write_word_be;
  wire [127:0] ram_data_out;
  wire lot_valid, lot_rsp_ready;
  reg lot_ready=1, lot_rsp_valid=0;
  wire [1:0] lot_dst;
  wire [64:0] lot_payload;
  reg [31:0] lot_rsp_rdata=0;
  reg lot_rsp_error=0;
  wire native_address_rejected, protocol_fault;

  DataCache_2KB #(.PABITS(PABITS)) cache (
    .clock(clk), .reset(reset),
    .VAddressIn_C(VAddressIn_C), .PAddressIn_C(PAddressIn_C),
    .PAddressValid_C(PAddressValid_C), .CacheAttr_C(CacheAttr_C),
    .Stall_C(Stall_C), .DataIn_C(DataIn_C), .Read_C(Read_C),
    .Write_C(Write_C), .DataOut_C(DataOut_C), .Ready_C(Ready_C),
    .DoCacheOp_C(DoCacheOp_C), .CacheOp_C(CacheOp_C),
    .CacheOpData_C(CacheOpData_C), .Address_M(Address_M),
    .ReadLine_M(ReadLine_M), .ReadWord_M(ReadWord_M),
    .DataIn_M(DataIn_M), .DataInOffset_M(DataInOffset_M),
    .LineOutReady_M(LineOutReady_M), .WordOutReady_M(WordOutReady_M),
    .WordOutBE_M(WordOutBE_M), .WordOutPAddressValid_M(WordOutPAddressValid_M),
    .ReadWordPAddressValid_M(ReadWordPAddressValid_M),
    .DataOut_M(DataOut_M), .Ready_M(Ready_M)
  );

  openmips_native_cache_lot_wrapper dut (
    .clk(clk), .reset_n(~reset),
    .native_addr(Address_M), .native_read_line(ReadLine_M), .native_read_word(ReadWord_M),
    .native_line_write_ready(LineOutReady_M), .native_word_write_ready(WordOutReady_M),
    .native_word_write_be(WordOutBE_M), .native_data_out(DataOut_M),
    .native_read_word_paddr_valid(ReadWordPAddressValid_M),
    .native_word_write_paddr_valid(WordOutPAddressValid_M),
    .native_data_in(DataIn_M), .native_data_offset(DataInOffset_M), .native_ready(Ready_M),
    .ram_addr(ram_addr), .ram_read_line(ram_read_line), .ram_read_word(ram_read_word),
    .ram_write_line_ready(ram_write_line_ready), .ram_write_word_ready(ram_write_word_ready),
    .ram_write_word_be(ram_write_word_be), .ram_data_out(ram_data_out),
    .ram_data_in(32'b0), .ram_data_offset(2'b0), .ram_ready(1'b0),
    .lot_valid(lot_valid), .lot_ready(lot_ready), .lot_dst(lot_dst),
    .lot_payload(lot_payload), .lot_rsp_valid(lot_rsp_valid),
    .lot_rsp_ready(lot_rsp_ready), .lot_rsp_rdata(lot_rsp_rdata),
    .lot_rsp_error(lot_rsp_error), .native_address_rejected(native_address_rejected),
    .protocol_fault(protocol_fault)
  );

  integer delay_count=0, lot_request_count=0;
  reg endpoint_pending=0;
  reg [64:0] captured_payload=0;
  always @(posedge clk) begin
    if (reset) begin
      endpoint_pending <= 0;
      delay_count <= 0;
      lot_rsp_valid <= 0;
      lot_rsp_rdata <= 0;
      lot_request_count <= 0;
      captured_payload <= 0;
    end else begin
      if (lot_valid && lot_ready) begin
        endpoint_pending <= 1;
        delay_count <= 3;
        captured_payload <= lot_payload;
        lot_request_count <= lot_request_count + 1;
      end
      if (endpoint_pending && delay_count > 0)
        delay_count <= delay_count - 1;
      if (endpoint_pending && delay_count == 0 && !lot_rsp_valid) begin
        lot_rsp_valid <= 1;
        lot_rsp_rdata <= 32'h1234_ABCD;
      end
      if (lot_rsp_valid && lot_rsp_ready) begin
        lot_rsp_valid <= 0;
        endpoint_pending <= 0;
      end
    end
  end

  initial begin
    repeat (3) @(negedge clk);
    reset=0;
    @(negedge clk);
    PAddressValid_C=1;
    CacheAttr_C=3'b010;
    VAddressIn_C=10'h000;
    Read_C=1;
    wait (lot_valid === 1'b1);
    if (lot_dst !== 2'd0 || lot_payload[64] !== 1'b0 ||
        lot_payload[63:32] !== 32'h1F00_0000)
      $fatal(1, "native cache read generated wrong LOT command: dst=%0d payload=%h", lot_dst, lot_payload);
    wait (Ready_C === 1'b1);
    if (DataOut_C !== 32'h1234_ABCD)
      $fatal(1, "CPU-side uncacheable read returned %h", DataOut_C);
    @(negedge clk);
    Read_C=0;
    repeat (2) @(negedge clk);
    if (lot_request_count != 1)
      $fatal(1, "expected one LOT read request, got %0d", lot_request_count);
    if (ram_read_line || ram_read_word || ram_write_line_ready || ram_write_word_ready)
      $fatal(1, "uncacheable LOT read leaked to RAM");
    if (protocol_fault || native_address_rejected)
      $fatal(1, "unexpected fault during LOT read");

    // Issue a queued uncacheable store and prove it does not retire while the
    // endpoint deliberately delays its response.
    @(negedge clk);
    VAddressIn_C=10'h001; // next word: byte address 0x1F000004 -> DATA destination
    DataIn_C=32'hCAFE_BABE;
    Write_C=4'b1111;
    wait (cache.state == 2); // WRITEBACK: retire the one-shot CPU request before enqueue.
    Write_C=0;
    wait (WordOutReady_M === 1'b1);
    wait (lot_valid === 1'b1);
    if (lot_dst !== 2'd1 || lot_payload[64] !== 1'b1 ||
        lot_payload[63:32] !== 32'h1F00_0004 ||
        lot_payload[31:0] !== 32'hCAFE_BABE)
      $fatal(1, "native cache store generated wrong LOT command: dst=%0d payload=%h", lot_dst, lot_payload);
    repeat (2) @(negedge clk);
    if (!WordOutReady_M)
      $fatal(1, "write-buffer entry retired before delayed LOT response");
    wait (lot_rsp_valid && lot_rsp_ready);
    @(posedge clk);
    @(negedge clk);
    repeat (2) @(negedge clk);
    if (WordOutReady_M || LineOutReady_M)
      $fatal(1, "write-buffer entry did not retire after LOT response");
    if (lot_request_count != 2)
      $fatal(1, "expected exactly two LOT requests, got %0d", lot_request_count);
    if (protocol_fault || native_address_rejected)
      $fatal(1, "unexpected fault during LOT write");
    $display("TB RESULT: PASS - actual native cache to adapter/bridge to delayed LOT endpoint read/write");
    $finish;
  end

  initial begin
    repeat (400) @(posedge clk);
    $fatal(1, "timeout waiting for cache-to-LOT integration test");
  end
endmodule
