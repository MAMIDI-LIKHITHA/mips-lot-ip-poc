`timescale 1ns/1ps
// Behavioral simulation model for the Xilinx-generated dual-port BRAM used
// by upstream Set_RW_128x64. Simulation-only; not a synthesis replacement.
module BRAM_32x256_128x64_TDP_BE(
 input clka, input rsta, input [3:0] wea, input [7:0] addra,
 input [31:0] dina, output reg [31:0] douta,
 input clkb, input rstb, input [15:0] web, input [5:0] addrb,
 input [127:0] dinb, output reg [127:0] doutb
);
 reg [127:0] mem [0:63];
 integer i;
 initial begin douta=0; doutb=0; for(i=0;i<64;i=i+1) mem[i]=0; end
 always @(posedge clka) begin
   if (rsta) douta<=0;
   else begin
     douta<=mem[addra[7:2]][addra[1:0]*32 +: 32];
     if (|wea) begin
       case(addra[1:0])
         0: begin if(wea[0]) mem[addra[7:2]][7:0]<=dina[7:0]; if(wea[1]) mem[addra[7:2]][15:8]<=dina[15:8]; if(wea[2]) mem[addra[7:2]][23:16]<=dina[23:16]; if(wea[3]) mem[addra[7:2]][31:24]<=dina[31:24]; end
         1: begin if(wea[0]) mem[addra[7:2]][39:32]<=dina[7:0]; if(wea[1]) mem[addra[7:2]][47:40]<=dina[15:8]; if(wea[2]) mem[addra[7:2]][55:48]<=dina[23:16]; if(wea[3]) mem[addra[7:2]][63:56]<=dina[31:24]; end
         2: begin if(wea[0]) mem[addra[7:2]][71:64]<=dina[7:0]; if(wea[1]) mem[addra[7:2]][79:72]<=dina[15:8]; if(wea[2]) mem[addra[7:2]][87:80]<=dina[23:16]; if(wea[3]) mem[addra[7:2]][95:88]<=dina[31:24]; end
         3: begin if(wea[0]) mem[addra[7:2]][103:96]<=dina[7:0]; if(wea[1]) mem[addra[7:2]][111:104]<=dina[15:8]; if(wea[2]) mem[addra[7:2]][119:112]<=dina[23:16]; if(wea[3]) mem[addra[7:2]][127:120]<=dina[31:24]; end
       endcase
     end
   end
 end
 always @(posedge clkb) begin
   if (rstb) doutb<=0;
   else begin
     doutb<=mem[addrb];
     if (|web) begin
       if(web[0]) mem[addrb][7:0]<=dinb[7:0]; if(web[1]) mem[addrb][15:8]<=dinb[15:8];
       if(web[2]) mem[addrb][23:16]<=dinb[23:16]; if(web[3]) mem[addrb][31:24]<=dinb[31:24];
       if(web[4]) mem[addrb][39:32]<=dinb[39:32]; if(web[5]) mem[addrb][47:40]<=dinb[47:40];
       if(web[6]) mem[addrb][55:48]<=dinb[55:48]; if(web[7]) mem[addrb][63:56]<=dinb[63:56];
       if(web[8]) mem[addrb][71:64]<=dinb[71:64]; if(web[9]) mem[addrb][79:72]<=dinb[79:72];
       if(web[10]) mem[addrb][87:80]<=dinb[87:80]; if(web[11]) mem[addrb][95:88]<=dinb[95:88];
       if(web[12]) mem[addrb][103:96]<=dinb[103:96]; if(web[13]) mem[addrb][111:104]<=dinb[111:104];
       if(web[14]) mem[addrb][119:112]<=dinb[119:112]; if(web[15]) mem[addrb][127:120]<=dinb[127:120];
     end
   end
 end
endmodule
