// Black-box declarations for vendor-generated OpenMIPS IP during generic
// synthesis. Their resources/timing are excluded from generic logic statistics.
(* blackbox *) module BRAM_32x1024_SDP (
  input clka, input wea, input [9:0] addra, input [31:0] dina,
  input clkb, input rstb, input [9:0] addrb, output [31:0] doutb
);
endmodule

(* blackbox *) module BRAM_32x256_128x64_TDP_BE (
  input clka, input rsta, input [3:0] wea, input [7:0] addra,
  input [31:0] dina, output [31:0] douta,
  input clkb, input rstb, input [15:0] web, input [5:0] addrb,
  input [127:0] dinb, output [127:0] doutb
);
endmodule

(* blackbox *) module DSP_MAddSub_32x32x64 (
  input clock, input reset,
  input [31:0] A, input [31:0] B, input [63:0] C,
  input sign, input fused, input subtract, input start,
  output busy, output [63:0] D
);
endmodule
