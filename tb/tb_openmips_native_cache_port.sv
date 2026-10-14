`timescale 1ns/1ps
// Drives the real upstream DataCache_2KB module from a minimal processor-side
// request, then checks a cacheable line-fill sequence through the native port.
module tb_openmips_native_cache_port;
  localparam PABITS=36;
  reg clock=0, reset=1;
  always #5 clock=~clock;
  reg [9:0] VAddressIn_C=0;
  reg [23:0] PAddressIn_C=0;
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
  wire [127:0] DataOut_M;
  reg [31:0] DataIn_M=0;
  reg [1:0] DataInOffset_M=0;
  reg Ready_M=0;

  DataCache_2KB #(.PABITS(PABITS)) dut (
    .clock(clock), .reset(reset),
    .VAddressIn_C(VAddressIn_C), .PAddressIn_C(PAddressIn_C),
    .PAddressValid_C(PAddressValid_C), .CacheAttr_C(CacheAttr_C),
    .Stall_C(Stall_C), .DataIn_C(DataIn_C), .Read_C(Read_C),
    .Write_C(Write_C), .DataOut_C(DataOut_C), .Ready_C(Ready_C),
    .DoCacheOp_C(DoCacheOp_C), .CacheOp_C(CacheOp_C),
    .CacheOpData_C(CacheOpData_C), .Address_M(Address_M),
    .ReadLine_M(ReadLine_M), .ReadWord_M(ReadWord_M),
    .DataIn_M(DataIn_M), .DataInOffset_M(DataInOffset_M),
    .LineOutReady_M(LineOutReady_M), .WordOutReady_M(WordOutReady_M),
    .WordOutBE_M(WordOutBE_M), .DataOut_M(DataOut_M), .Ready_M(Ready_M)
  );

  integer cycles=0, ready_count=0, line_request_count=0;
  reg saw_readword=0, saw_readline=0, line_test=0;

  task send_line_beat;
    input [1:0] offset;
    input [31:0] value;
    begin
      @(negedge clock);
      DataInOffset_M=offset;
      DataIn_M=value;
      Ready_M=1;
      @(negedge clock);
      Ready_M=0;
    end
  endtask
  always @(posedge clock) begin
    if (!reset) begin
      cycles <= cycles + 1;
      if (ReadWord_M) saw_readword <= 1'b1;
      if (ReadLine_M) begin
        saw_readline <= 1'b1;
        line_request_count <= line_request_count + 1;
      end
      if (Ready_C) ready_count <= ready_count + 1;
      if (!line_test && (ReadLine_M || LineOutReady_M || WordOutReady_M))
        $fatal(1, "unexpected line/write-buffer traffic during isolated uncacheable read");
      if (cycles > 160) begin $display("TIMEOUT state=%0d ReadLine=%b ReadWord=%b Ready_M=%b Ready_C=%b ready_count=%0d line_test=%b Read_C=%b vaddr=%h s_vaddr=%h WB_Empty=%b WB_Full=%b new_request=%b new_request_r=%b pseudo_new_request_r=%b", dut.state, ReadLine_M, ReadWord_M, Ready_M, Ready_C, ready_count, line_test, Read_C, VAddressIn_C, dut.s_vaddr, dut.WB_Empty, dut.WB_Full, dut.new_request, dut.new_request_r, dut.pseudo_new_request_r); $fatal(1, "timeout waiting for native cache completion"); end
    end
  end

  initial begin
    repeat (3) @(negedge clock);
    reset=0;
    @(negedge clock);
    PAddressValid_C=1;
    CacheAttr_C=3'b010;
    VAddressIn_C=10'h004;
    PAddressIn_C=24'h000001;
    Read_C=1;
    wait (ReadWord_M === 1'b1);
    // The cache's FILL_WAIT_WORD state can re-sample a held CPU request;
    // retire the one-shot test request before returning the memory response.
    Read_C=0;
    repeat (2) @(negedge clock);
    DataIn_M=32'hA55A_3CC3;
    Ready_M=1;
    @(negedge clock);
    Ready_M=0;
    wait (Ready_C === 1'b1);
    @(negedge clock);
    Read_C=0;
    repeat (3) @(negedge clock);
    if (!saw_readword)
      $fatal(1, "expected native ReadWord_M request to be observed");
    if (ready_count != 1)
      $fatal(1, "expected exactly one processor-side Ready_C completion, got %0d", ready_count);

    // A different, cacheable address should take the four-word line-fill path.
    @(negedge clock);
    line_test=1;
    CacheAttr_C=3'b000;
    VAddressIn_C=10'h008; // word offset 0 within the cache line
    PAddressIn_C=24'h000002;
    Read_C=1;
    wait (ReadLine_M === 1'b1); // Observe the actual native memory request before accepting beats.
    wait (dut.state == 4); // FILL_WAIT_1: request has been captured.
    Read_C=0;
    send_line_beat(2'd0, 32'h1111_0000);
    send_line_beat(2'd1, 32'h2222_0001);
    send_line_beat(2'd2, 32'h3333_0002);
    send_line_beat(2'd3, 32'h4444_0003);
    wait (Ready_C === 1'b1);
    if (DataOut_C !== 32'h1111_0000)
      $fatal(1, "line-fill read returned %h, expected word at offset 0 = 11110000", DataOut_C);
    @(negedge clock);
    Read_C=0;
    repeat (3) @(negedge clock);
    if (!saw_readline)
      $fatal(1, "expected native ReadLine_M request to be observed");
    if (ready_count != 2)
      $fatal(1, "expected two processor-side completions (word + line fill), got %0d", ready_count);

    // Re-read the same cacheable address: this should hit and return the
    // selected word without another external line-fill request.
    @(negedge clock);
    Read_C=1;
    wait (Ready_C === 1'b1);
    if (DataOut_C !== 32'h1111_0000)
      $fatal(1, "cache-hit read returned %h, expected 11110000", DataOut_C);
    @(negedge clock);
    Read_C=0;
    repeat (3) @(negedge clock);
    if (ready_count != 3)
      $fatal(1, "expected third processor-side completion for cache hit, got %0d", ready_count);
    if (line_request_count != 1)
      $fatal(1, "expected exactly one external line request (fill only), got %0d", line_request_count);

    // Write a full word to the resident cache line, then verify a subsequent
    // read observes the updated value without triggering another line fill.
    @(negedge clock);
    DataIn_C=32'hDEAD_BEEF;
    Write_C=4'b1111;
    wait (dut.state == 9); // WRITE_RECOVER after the cache-hit store.
    Write_C=4'b0000;
    wait (Ready_C === 1'b1);
    @(negedge clock);
    repeat (3) @(negedge clock);
    Read_C=1;
    wait (Ready_C === 1'b1);
    if (DataOut_C !== 32'hDEAD_BEEF)
      $fatal(1, "store/readback mismatch: got %h, expected DEADBEEF", DataOut_C);
    @(negedge clock);
    Read_C=0;
    repeat (3) @(negedge clock);
    if (line_request_count != 1)
      $fatal(1, "cache-hit store/readback unexpectedly issued another line request: %0d", line_request_count);

    // Exercise the native write buffer for an uncacheable word store. This
    // checks the buffered payload and byte enables before acknowledging it.
    @(negedge clock);
    CacheAttr_C=3'b010;
    VAddressIn_C=10'h00C;
    PAddressIn_C=24'h000003;
    DataIn_C=32'hCAFE_BABE;
    Write_C=4'b1111;
    // Retire the processor-side write request as soon as the cache enters
    // WRITEBACK, before the FIFO enqueue edge, to avoid re-sampling it.
    wait (dut.state == 2); // WRITEBACK
    Write_C=4'b0000;
    wait (WordOutReady_M === 1'b1);
    if (LineOutReady_M !== 1'b0)
      $fatal(1, "uncacheable word store was incorrectly presented as a line write");
    if (WordOutBE_M !== 4'b1111)
      $fatal(1, "buffered word-store byte enables were %b, expected 1111", WordOutBE_M);
    if (DataOut_M[31:0] !== 32'hCAFE_BABE)
      $fatal(1, "buffered word-store data was %h, expected CAFEBABE", DataOut_M[31:0]);
    @(negedge clock);
    Ready_M=1;
    @(negedge clock);
    Ready_M=0;
    repeat (3) @(negedge clock);
    if (WordOutReady_M || LineOutReady_M)
      $fatal(1, "write buffer did not retire after one-cycle Ready_M acknowledgement");
    $display("TB RESULT: PASS - cache fill/hit/store plus uncacheable buffered word-store payload and retirement");
    $finish;
  end
endmodule
