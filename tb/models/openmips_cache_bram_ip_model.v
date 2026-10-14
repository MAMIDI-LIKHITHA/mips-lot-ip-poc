// Simulation-only behavioral replacement for the upstream Xilinx-generated BRAM IP.
// It preserves the 32-bit single-word and 128-bit four-word line interfaces used by
// Set_RW_128x64.v; it is not a vendor timing/primitive model.
module BRAM_32x256_128x64_TDP_BE (
  input clka, input rsta, input [3:0] wea, input [7:0] addra,
  input [31:0] dina, output reg [31:0] douta,
  input clkb, input rstb, input [15:0] web, input [5:0] addrb,
  input [127:0] dinb, output reg [127:0] doutb
);
  reg [31:0] mem [0:255];
  integer i;
  always @(posedge clka) begin
    if (rsta) begin
      douta <= 32'b0;
    end else begin
      douta <= mem[addra];
      for (i=0; i<4; i=i+1)
        if (wea[i]) mem[addra][i*8 +: 8] <= dina[i*8 +: 8];
    end
  end
  integer j;
  always @(posedge clkb) begin
    if (rstb) begin
      doutb <= 128'b0;
    end else begin
      for (j=0; j<4; j=j+1) begin
        doutb[j*32 +: 32] <= mem[{addrb,2'b00}+j];
        if (web[j*4 +: 4] != 4'b0000) begin
          if (web[j*4+0]) mem[{addrb,2'b00}+j][7:0]   <= dinb[j*32+0 +: 8];
          if (web[j*4+1]) mem[{addrb,2'b00}+j][15:8]  <= dinb[j*32+8 +: 8];
          if (web[j*4+2]) mem[{addrb,2'b00}+j][23:16] <= dinb[j*32+16 +: 8];
          if (web[j*4+3]) mem[{addrb,2'b00}+j][31:24] <= dinb[j*32+24 +: 8];
        end
      end
    end
  end
endmodule
