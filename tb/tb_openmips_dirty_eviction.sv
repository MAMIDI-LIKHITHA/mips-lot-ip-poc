`timescale 1ns/1ps
// Dedicated dirty-victim eviction test for the pinned OpenMIPS DataCache_2KB.
// Two tags occupy one index; a dirty least-recently-used line must be queued
// as a line writeback before the third tag is filled.
module tb_openmips_dirty_eviction;
  localparam PABITS=36;
  reg clock=0, reset=1;
  always #5 clock=~clock;
  reg [9:0] VAddressIn_C=0;
  reg [23:0] PAddressIn_C=0;
  reg PAddressValid_C=0;
  reg [2:0] CacheAttr_C=3'b000;
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

  integer cycles=0, line_reads=0;
  always @(posedge clock) if (!reset) begin
    cycles <= cycles+1;
    if (ReadLine_M) line_reads <= line_reads+1;
    if (cycles > 300)
      $fatal(1,"timeout state=%0d ReadLine=%b Ready_M=%b Ready_C=%b LineOut=%b WordOut=%b WB_Empty=%b vaddr=%h paddr=%h s_vaddr=%h dirty_evict=%b",
        dut.state,ReadLine_M,Ready_M,Ready_C,LineOutReady_M,WordOutReady_M,dut.WB_Empty,VAddressIn_C,PAddressIn_C,dut.s_vaddr,dut.s_dirty_evict_e);
  end

  task fill_line;
    input [23:0] tag;
    input [31:0] a,b,c,d;
    begin
      @(negedge clock);
      PAddressIn_C=tag; VAddressIn_C=10'h008;
      CacheAttr_C=3'b000; Read_C=1;
      wait (ReadLine_M === 1'b1);
      wait (dut.state == 4); // FILL_WAIT_1
      Read_C=0;
      @(negedge clock); DataInOffset_M=0; DataIn_M=a; Ready_M=1;
      @(negedge clock); DataInOffset_M=1; DataIn_M=b;
      @(negedge clock); DataInOffset_M=2; DataIn_M=c;
      @(negedge clock); DataInOffset_M=3; DataIn_M=d;
      @(negedge clock); Ready_M=0;
      wait (Ready_C === 1'b1);
      @(negedge clock); Read_C=0;
      repeat (2) @(negedge clock);
    end
  endtask

  task read_hit;
    input [23:0] tag;
    input [31:0] expected;
    begin
      @(negedge clock); PAddressIn_C=tag; VAddressIn_C=10'h008;
      CacheAttr_C=3'b000; Read_C=1;
      wait (Ready_C === 1'b1);
      if (DataOut_C !== expected)
        $fatal(1,"cache hit tag=%h returned %h expected %h",tag,DataOut_C,expected);
      @(negedge clock); Read_C=0;
      repeat (2) @(negedge clock);
    end
  endtask

  initial begin
    repeat (3) @(negedge clock); reset=0;
    PAddressValid_C=1;
    fill_line(24'h000002,32'h1111_0000,32'h1111_0001,32'h1111_0002,32'h1111_0003);
    fill_line(24'h000003,32'h2222_0000,32'h2222_0001,32'h2222_0002,32'h2222_0003);

    // Store to tag 2, then touch tag 3 so tag 2 becomes the LRU candidate.
    @(negedge clock); PAddressIn_C=24'h000002; VAddressIn_C=10'h008;
    DataIn_C=32'hDEAD_BEEF; Write_C=4'b1111;
    wait (dut.state == 9); // WRITE_RECOVER after cacheable store
    Write_C=0;
    wait (Ready_C === 1'b1);
    @(negedge clock); repeat (2) @(negedge clock);
    read_hit(24'h000003,32'h2222_0000);

    // A third physical tag at the same index must evict the dirty tag-2 line.
    @(negedge clock); PAddressIn_C=24'h000004; VAddressIn_C=10'h008;
    Read_C=1;
    wait (dut.state == 2); // WRITEBACK for dirty victim
    wait (LineOutReady_M === 1'b1);
    if (WordOutReady_M !== 1'b0)
      $fatal(1,"dirty cache line incorrectly classified as word write");
    if (!(DataOut_M[31:0] == 32'hDEAD_BEEF ||
          DataOut_M[63:32] == 32'hDEAD_BEEF ||
          DataOut_M[95:64] == 32'hDEAD_BEEF ||
          DataOut_M[127:96] == 32'hDEAD_BEEF))
      $fatal(1,"dirty writeback payload did not contain DEADBEEF: %h",DataOut_M);
    $display("Observed dirty line writeback payload: %h",DataOut_M);

    // Acknowledge the queued line writeback, then verify replacement fill begins.
    @(negedge clock); Ready_M=1;
    @(negedge clock); Ready_M=0;
    wait (ReadLine_M === 1'b1);
    wait (dut.state == 4);
    Read_C=0;
    @(negedge clock); DataInOffset_M=0; DataIn_M=32'h4444_0000; Ready_M=1;
    @(negedge clock); DataInOffset_M=1; DataIn_M=32'h4444_0001;
    @(negedge clock); DataInOffset_M=2; DataIn_M=32'h4444_0002;
    @(negedge clock); DataInOffset_M=3; DataIn_M=32'h4444_0003;
    @(negedge clock); Ready_M=0;
    wait (Ready_C === 1'b1);
    @(negedge clock); Read_C=0;
    repeat (3) @(negedge clock);
    if (line_reads != 3)
      $fatal(1,"expected 3 line reads (two fills plus replacement), got %0d",line_reads);
    $display("TB RESULT: PASS - dirty LRU victim queued as line writeback before replacement fill");
    $finish;
  end
endmodule
