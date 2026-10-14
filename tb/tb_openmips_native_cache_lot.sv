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
  reg [31:0] ram_data_in=0;
  reg [1:0] ram_data_offset=0;
  reg ram_ready=0;
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
    .ram_data_in(ram_data_in), .ram_data_offset(ram_data_offset), .ram_ready(ram_ready),
    .lot_valid(lot_valid), .lot_ready(lot_ready), .lot_dst(lot_dst),
    .lot_payload(lot_payload), .lot_rsp_valid(lot_rsp_valid),
    .lot_rsp_ready(lot_rsp_ready), .lot_rsp_rdata(lot_rsp_rdata),
    .lot_rsp_error(lot_rsp_error), .native_address_rejected(native_address_rejected),
    .protocol_fault(protocol_fault)
  );

  integer delay_count=0, lot_request_count=0;
  integer ram_line_count=0, ram_line_write_count=0, ram_word_write_count=0;
  reg ram_read_line_d=0, ram_write_line_d=0, ram_write_word_d=0;
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
      ram_read_line_d <= 0;
      ram_write_line_d <= 0;
      ram_write_word_d <= 0;
      ram_line_count <= 0;
      ram_line_write_count <= 0;
      ram_word_write_count <= 0;
    end else begin
      ram_read_line_d <= ram_read_line;
      ram_write_line_d <= ram_write_line_ready;
      ram_write_word_d <= ram_write_word_ready;
      if (ram_read_line && !ram_read_line_d) begin
        $display("RAM READLINE edge state=%0d addr=%h attr=%b vaddr=%h Read_C=%b", cache.state, Address_M, CacheAttr_C, VAddressIn_C, Read_C);
        ram_line_count <= ram_line_count + 1;
      end
      if (ram_write_line_ready && !ram_write_line_d)
        ram_line_write_count <= ram_line_write_count + 1;
      if (ram_write_word_ready && !ram_write_word_d)
        ram_word_write_count <= ram_word_write_count + 1;
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

  task send_ram_line_beat;
    input [1:0] offset;
    input [31:0] value;
    begin
      @(negedge clk);
      ram_data_offset=offset;
      ram_data_in=value;
      ram_ready=1;
      @(posedge clk); #1;
      $display("RAM BEAT offset=%0d Ready_M=%b route_ram=%b ram_pending=%b cache_state=%0d", offset, Ready_M, dut.u_bridge.route_ram, dut.u_bridge.ram_pending, cache.state);
      @(negedge clk);
      ram_ready=0;
    end
  endtask

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

    // A cacheable miss must use the RAM line-fill path, not LOT.
    @(negedge clk);
    PAddressValid_C=1;
    CacheAttr_C=3'b000;
    PAddressIn_C=24'h000002;
    VAddressIn_C=10'h008;
    Read_C=1;
    wait (ram_read_line === 1'b1);
    wait (cache.state == 4); // FILL_WAIT_1: line request captured; begin RAM beats only now.
    Read_C=0;
    send_ram_line_beat(2'd0, 32'h1111_0000);
    send_ram_line_beat(2'd1, 32'h2222_0001);
    send_ram_line_beat(2'd2, 32'h3333_0002);
    send_ram_line_beat(2'd3, 32'h4444_0003);
    wait (Ready_C === 1'b1);
    if (DataOut_C !== 32'h1111_0000)
      $fatal(1, "RAM line fill returned %h, expected 11110000", DataOut_C);
    @(negedge clk);
    Read_C=0;
    repeat (2) @(negedge clk);
    if (ram_line_count != 1)
      $fatal(1, "expected exactly one RAM line fill, got %0d", ram_line_count);
    if (lot_request_count != 1 || lot_valid)
      $fatal(1, "cacheable line fill unexpectedly used LOT");
    if (protocol_fault || native_address_rejected)
      $fatal(1, "unexpected fault during cacheable RAM line fill");

    $display("RAM line-fill test complete; entering LOT write phase addr=%h PAddressIn_C=%h", Address_M, PAddressIn_C);
    // Issue a queued uncacheable store and prove it does not retire while the
    // endpoint deliberately delays its response.
    @(negedge clk);
    VAddressIn_C=10'h001; // next word: byte address 0x1F000004 -> DATA destination
    PAddressIn_C=24'h01F000;
    PAddressValid_C=1;
    CacheAttr_C=3'b010;
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

    // Dirty a cacheable line, then access a conflicting physical tag at the
    // same virtual index. The dirty line must be written back to RAM, not LOT.
    @(negedge clk);
    VAddressIn_C=10'h008;
    PAddressIn_C=24'h000002;
    PAddressValid_C=1;
    CacheAttr_C=3'b000;
    DataIn_C=32'hDEAD_BEEF;
    Write_C=4'b1111;
    wait (cache.state == 9); // WRITE_RECOVER after the cache-hit store.
    Write_C=0;
    wait (Ready_C === 1'b1);
    @(negedge clk);
    repeat (2) @(negedge clk);

    PAddressIn_C=24'h000003; // Different physical tag, same virtual index.
    Read_C=1;
    wait (ram_write_line_ready === 1'b1);
    if (!(ram_data_out[31:0] === 32'hDEAD_BEEF ||
          ram_data_out[63:32] === 32'hDEAD_BEEF ||
          ram_data_out[95:64] === 32'hDEAD_BEEF ||
          ram_data_out[127:96] === 32'hDEAD_BEEF))
      $fatal(1, "dirty RAM writeback payload did not contain updated DEAD_BEEF word: %h", ram_data_out);
    Read_C=0;
    @(negedge clk);
    ram_ready=1;
    @(negedge clk);
    ram_ready=0;

    wait (ram_read_line === 1'b1);
    wait (cache.state == 4); // FILL_WAIT_1 for the replacement line.
    Read_C=0;
    send_ram_line_beat(2'd0, 32'h5555_0000);
    send_ram_line_beat(2'd1, 32'h6666_0001);
    send_ram_line_beat(2'd2, 32'h7777_0002);
    send_ram_line_beat(2'd3, 32'h8888_0003);
    wait (Ready_C === 1'b1);
    if (ram_line_write_count != 1)
      $fatal(1, "expected exactly one dirty-line RAM writeback, got %0d", ram_line_write_count);
    if (ram_line_count != 2)
      $fatal(1, "expected initial and replacement line fills, got %0d", ram_line_count);
    if (lot_request_count != 2)
      $fatal(1, "cacheable dirty writeback incorrectly generated a LOT request");
    if (protocol_fault || native_address_rejected)
      $fatal(1, "unexpected fault during RAM dirty-line eviction");
    if (ram_word_write_count != 0)
      $fatal(1, "unexpected single-word RAM write in this regression: %0d", ram_word_write_count);
    $display("TB RESULT: PASS - actual cache RAM line fill/dirty writeback plus LOT read/write and delayed response");
    $finish;
  end

  initial begin
    repeat (400) @(posedge clk);
    $display("TIMEOUT state=%0d Ready_C=%b ReadLine=%b ReadWord=%b ram_line=%b ram_ready=%b ram_lines=%0d lot_valid=%b lot_count=%0d", cache.state, Ready_C, ReadLine_M, ReadWord_M, ram_read_line, ram_ready, ram_line_count, lot_valid, lot_request_count);
    $fatal(1, "timeout waiting for cache-to-LOT integration test");
  end
endmodule
