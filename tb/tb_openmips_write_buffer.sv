`timescale 1ns/1ps
// Focused regression for the real OpenMIPS DataCache_2KB write-buffer path.
// This isolates uncacheable word-store enqueue/payload/retirement from fills.
module tb_openmips_write_buffer;
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

  integer cycles=0;
  always @(posedge clock) begin
    if (!reset) begin
      cycles <= cycles + 1;
      if (cycles > 80)
        $fatal(1, "write-buffer test timeout: state=%0d WB_Empty=%b WB_Full=%b WordOutReady=%b Ready_M=%b",
               dut.state, dut.WB_Empty, dut.WB_Full, WordOutReady_M, Ready_M);
    end
  end

  initial begin
    repeat (3) @(negedge clock);
    reset=0;
    @(negedge clock);
    PAddressValid_C=1;
    CacheAttr_C=3'b010; // OpenMIPS uncacheable attribute
    VAddressIn_C=10'h00C;
    PAddressIn_C=24'h000003;
    DataIn_C=32'hCAFE_BABE;
    Write_C=4'b1111;

    // Stop presenting the CPU request as soon as WRITEBACK is entered.
    // WB_EnQ is sampled at the following rising edge.
    wait (dut.state == 2); // WRITEBACK
    Write_C=4'b0000;
    wait (WordOutReady_M === 1'b1);
    if (LineOutReady_M !== 1'b0)
      $fatal(1, "uncacheable store incorrectly classified as line write");
    if (WordOutBE_M !== 4'b1111)
      $fatal(1, "byte enables=%b, expected 1111", WordOutBE_M);
    if (DataOut_M[31:0] !== 32'hCAFE_BABE)
      $fatal(1, "store data=%h, expected CAFEBABE", DataOut_M[31:0]);
    if (Address_M[1:0] !== 2'b00)
      $fatal(1, "unexpected memory address low bits %b", Address_M[1:0]);

    // Acknowledge the queued write with one Ready_M pulse.
    @(negedge clock);
    Ready_M=1;
    @(negedge clock);
    Ready_M=0;
    repeat (3) @(negedge clock);
    if (WordOutReady_M || LineOutReady_M)
      $fatal(1, "write buffer did not retire after one acknowledgement");
    $display("TB RESULT: PASS - isolated uncacheable word-store payload and write-buffer retirement");
    $finish;
  end
endmodule
