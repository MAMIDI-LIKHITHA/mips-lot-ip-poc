// Simulation-only models for Xilinx-generated IP used by pinned OpenMIPS.
// These are functional test models, not vendor primitive/timing replacements.
module BRAM_32x1024_SDP (
  input clka, input wea, input [9:0] addra, input [31:0] dina,
  input clkb, input rstb, input [9:0] addrb, output reg [31:0] doutb
);
  reg [31:0] mem [0:1023];
  always @(posedge clka)
    if (wea) mem[addra] <= dina;
  always @(posedge clkb) begin
    if (rstb) doutb <= 32'b0;
    else doutb <= mem[addrb];
  end
endmodule

module DSP_MAddSub_32x32x64 (
  input clock, input reset,
  input [31:0] A, input [31:0] B, input [63:0] C,
  input sign, input fused, input subtract, input start,
  output reg busy, output reg [63:0] D
);
  reg [63:0] product;
  always @(posedge clock) begin
    if (reset) begin
      busy <= 1'b0;
      D <= 64'b0;
    end else if (start && !busy) begin
      if (sign) product = $signed(A) * $signed(B);
      else product = A * B;
      if (fused) begin
        if (subtract) D <= C - product;
        else D <= C + product;
      end else D <= product;
      busy <= 1'b1;
    end else if (busy) begin
      busy <= 1'b0;
    end
  end
endmodule
