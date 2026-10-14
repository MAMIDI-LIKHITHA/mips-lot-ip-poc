`timescale 1ns/1ps
module tb_openmips_full_core_lot_program;
  reg clk=0, reset=1;
  always #5 clk=~clk;

  wire [33:0] inst_addr;
  wire inst_read_line, inst_read_word;
  reg inst_ready=0;
  reg [31:0] inst_in=0;
  reg [1:0] inst_offset=0;

  wire [33:0] data_addr;
  wire data_read_line, data_read_word, data_write_line, data_write_word;
  wire [3:0] data_write_be;
  wire [127:0] data_out;
  wire data_read_word_paddr_valid, data_write_word_paddr_valid;
  wire [31:0] data_in;
  wire [1:0] data_offset;
  wire data_ready;

  wire [29:0] ram_addr;
  wire ram_read_line, ram_read_word, ram_write_line, ram_write_word;
  wire [3:0] ram_write_be;
  wire [127:0] ram_data_out;
  reg [31:0] ram_data_in=0;
  reg [1:0] ram_data_offset=0;
  reg ram_ready=0;
  integer ram_line_fill_count=0, ram_line_write_count=0;
  reg ram_read_line_d=0, ram_write_line_d=0, ram_write_word_d=0;
  reg ram_line_pending=0, ram_write_pending=0;
  integer ram_beat=0;
  reg [127:0] ram_write_payload=0;
  wire lot_valid, lot_rsp_ready;
  wire [1:0] lot_dst;
  wire [64:0] lot_payload;
  reg lot_ready=1, lot_rsp_valid=0;
  reg [31:0] lot_rsp_rdata=0;
  reg lot_rsp_error=0;
  wire native_address_rejected, protocol_fault;

  MIPS32 #(.PABITS(36)) cpu (
    .clock(clk), .reset(reset), .Core_Reset(reset),
    .InstMem_Address(inst_addr), .InstMem_ReadLine(inst_read_line),
    .InstMem_ReadWord(inst_read_word), .InstMem_Ready(inst_ready),
    .InstMem_In(inst_in), .InstMem_Offset(inst_offset),
    .DataMem_Address(data_addr), .DataMem_ReadLine(data_read_line),
    .DataMem_ReadWord(data_read_word), .DataMem_In(data_in),
    .DataMem_Ready(data_ready), .DataMem_Offset(data_offset),
    .DataMem_WriteLineReady(data_write_line), .DataMem_WriteWordReady(data_write_word),
    .DataMem_WriteWordBE(data_write_be), .DataMem_Out(data_out),
    .DataMem_ReadWordPAddressValid(data_read_word_paddr_valid),
    .DataMem_WriteWordPAddressValid(data_write_word_paddr_valid),
    .Interrupts(5'b0), .NMI(1'b0)
  );

  openmips_native_cache_lot_wrapper wrapper (
    .clk(clk), .reset_n(~reset),
    .native_addr(data_addr), .native_read_line(data_read_line),
    .native_read_word(data_read_word), .native_line_write_ready(data_write_line),
    .native_word_write_ready(data_write_word), .native_word_write_be(data_write_be),
    .native_data_out(data_out),
    .native_read_word_paddr_valid(data_read_word_paddr_valid),
    .native_word_write_paddr_valid(data_write_word_paddr_valid),
    .native_data_in(data_in), .native_data_offset(data_offset), .native_ready(data_ready),
    .ram_addr(ram_addr), .ram_read_line(ram_read_line), .ram_read_word(ram_read_word),
    .ram_write_line_ready(ram_write_line), .ram_write_word_ready(ram_write_word),
    .ram_write_word_be(ram_write_be), .ram_data_out(ram_data_out),
    .ram_data_in(ram_data_in), .ram_data_offset(ram_data_offset), .ram_ready(ram_ready),
    .lot_valid(lot_valid), .lot_ready(lot_ready), .lot_dst(lot_dst),
    .lot_payload(lot_payload), .lot_rsp_valid(lot_rsp_valid),
    .lot_rsp_ready(lot_rsp_ready), .lot_rsp_rdata(lot_rsp_rdata),
    .lot_rsp_error(lot_rsp_error), .native_address_rejected(native_address_rejected),
    .protocol_fault(protocol_fault)
  );

  // Small ROM at both plausible reset/BEV entry locations. KSEG1 is uncached,
  // so the core normally issues one-word instruction reads.
  function [31:0] rom_word(input [33:0] word_addr);
    reg [5:0] idx;
    begin
      if (word_addr >= 34'h07F00000 && word_addr <= 34'h07F00026)
        idx = word_addr - 34'h07F00000;
      else if (word_addr >= 34'h07F000E0 && word_addr <= 34'h07F00106)
        idx = word_addr - 34'h07F000E0;
      else
        idx = 5'd31;
      case (idx)
        0:  rom_word=32'h3C0B_8000; // lui t3,0x8000: cacheable RAM base
        1:  rom_word=32'h356B_1000; // ori t3,t3,0x1000
        2:  rom_word=32'h8D6C_0000; // lw t4,0(t3): first line fill
        3:  rom_word=32'h0000_0000;
        4:  rom_word=32'h0000_0000;
        5:  rom_word=32'hAD6C_0000; // sw t4,0(t3): dirty first way
        6:  rom_word=32'h0000_0000;
        7:  rom_word=32'h0000_0000;
        8:  rom_word=32'h3C0D_8000; // lui t5,0x8000
        9:  rom_word=32'h35AD_1400; // ori t5,t5,0x1400: same D-cache set
        10: rom_word=32'h8DAE_0000; // lw t6,0(t5): fill second way
        11: rom_word=32'h0000_0000;
        12: rom_word=32'h0000_0000;
        13: rom_word=32'h8DAE_0000; // hit second way; set replacement state
        14: rom_word=32'h0000_0000;
        15: rom_word=32'h0000_0000;
        16: rom_word=32'h3C0F_8000; // lui t7,0x8000
        17: rom_word=32'h35EF_1800; // ori t7,t7,0x1800: third tag, same set
        18: rom_word=32'h8DF8_0000; // lw t8,0(t7): evict dirty first line
        19: rom_word=32'h0000_0000;
        20: rom_word=32'h0000_0000;
        21: rom_word=32'h3C08_BF00; // lui t0,0xBF00: LOT aperture
        22: rom_word=32'h0000_0000;
        23: rom_word=32'h8D09_0000; // lw t1,0(t0) -> LOT CONTROL
        24: rom_word=32'h0000_0000;
        25: rom_word=32'h0000_0000;
        26: rom_word=32'hAD09_0008; // sw t1,8(t0) -> STATUS gets read value
        27: rom_word=32'h0000_0000;
        28: rom_word=32'h0000_0000;
        29: rom_word=32'h3C0A_1234; // lui t2,0x1234
        30: rom_word=32'h0000_0000;
        31: rom_word=32'h354A_5678; // ori t2,t2,0x5678
        32: rom_word=32'h0000_0000;
        33: rom_word=32'h0000_0000;
        34: rom_word=32'hAD0A_0004; // sw t2,4(t0) -> DATA
        35: rom_word=32'h0000_0000;
        36: rom_word=32'h0000_0000;
        37: rom_word=32'h1000_FFFF; // beq zero,zero,self
        38: rom_word=32'h0000_0000; // branch delay slot
        default: rom_word=32'h1000_FFFF;
      endcase
    end
  endfunction

  function [31:0] little_endian_bus_word(input [31:0] instruction);
    begin
      little_endian_bus_word = {instruction[7:0], instruction[15:8],
                                instruction[23:16], instruction[31:24]};
    end
  endfunction

  reg inst_pending=0, inst_line_pending=0, inst_command_seen=0;
  reg [33:0] inst_saved_addr=0;
  reg [1:0] inst_beat=0;
  integer inst_delay=0;
  always @(posedge clk) begin
    if (reset) begin
      inst_ready <= 0;
      inst_in <= 0;
      inst_offset <= 0;
      inst_pending <= 0;
      inst_line_pending <= 0;
      inst_command_seen <= 0;
      inst_saved_addr <= 0;
      inst_beat <= 0;
      inst_delay <= 0;
    end else begin
      inst_ready <= 0;
      if (!(inst_read_word || inst_read_line))
        inst_command_seen <= 0;
      if (!inst_pending && !inst_command_seen && (inst_read_word || inst_read_line)) begin
        inst_pending <= 1;
        inst_command_seen <= 1;
        inst_line_pending <= inst_read_line;
        inst_saved_addr <= inst_read_line ? {inst_addr[33:2],2'b00} : inst_addr;
        inst_beat <= 0;
        inst_delay <= 1;
      end else if (inst_pending) begin
        if (inst_delay > 0) begin
          inst_delay <= inst_delay - 1;
        end else begin
          inst_ready <= 1;
          inst_offset <= inst_line_pending ? inst_beat : inst_saved_addr[1:0];
          // OpenMIPS is configured little-endian; its core byte-swaps the
          // instruction bus before decode, so the ROM bus word is reversed.
          inst_in <= little_endian_bus_word(rom_word(inst_saved_addr + (inst_line_pending ? inst_beat : 0)));
          if (inst_line_pending && inst_beat != 2'd3)
            inst_beat <= inst_beat + 1'b1;
          else
            inst_pending <= 0;
        end
      end
    end
  end

  // RAM model for cacheable data: delayed four-beat line fills and one-cycle
  // acknowledgement of a 128-bit dirty-line writeback.
  always @(posedge clk) begin
    if (reset) begin
      ram_ready <= 0;
      ram_data_in <= 0;
      ram_data_offset <= 0;
      ram_read_line_d <= 0;
      ram_write_line_d <= 0;
      ram_write_word_d <= 0;
      ram_line_pending <= 0;
      ram_write_pending <= 0;
      ram_beat <= 0;
      ram_line_fill_count <= 0;
      ram_line_write_count <= 0;
      ram_write_payload <= 0;
    end else begin
      ram_read_line_d <= ram_read_line;
      ram_write_line_d <= ram_write_line;
      ram_write_word_d <= ram_write_word;
      if (ram_write_line && !ram_write_line_d) begin
        $display("RAM WRITEBACK addr=%h data=%h cache_state=%0d", ram_addr, ram_data_out, cpu.DCache.state);
        ram_line_write_count <= ram_line_write_count + 1;
        ram_write_payload <= ram_data_out;
        ram_write_pending <= 1;
      end
      if (ram_write_word && !ram_write_word_d)
        ram_write_pending <= 1;
      if (ram_read_line && !ram_read_line_d) begin
        $display("RAM READ CMD addr=%h cache_state=%0d", ram_addr, cpu.DCache.state);
        ram_line_fill_count <= ram_line_fill_count + 1;
        ram_line_pending <= 1;
        ram_beat <= 0;
      end
      if (ram_write_line && !ram_write_line_d) begin
      end
      if (ram_read_line && !ram_read_line_d) begin
        ram_ready <= 0;
      end else if (ram_line_pending) begin
        $display("RAM BEAT offset=%0d ready_old=%b route=%b pending=%b cache_state=%0d", ram_beat, ram_ready, wrapper.u_bridge.route_ram, wrapper.u_bridge.ram_pending, cpu.DCache.state);
        ram_ready <= 1;
        ram_data_offset <= ram_beat[1:0];
        ram_data_in <= 32'h1111_0000 + ram_beat;
        if (ram_beat == 3) begin
          ram_line_pending <= 0;
          ram_beat <= 0;
        end else begin
          ram_beat <= ram_beat + 1;
        end
      end else if (ram_write_pending) begin
        ram_ready <= 1;
        ram_data_offset <= 0;
        ram_write_pending <= 0;
      end else begin
        ram_ready <= 0;
      end
    end
  end

  integer lot_count=0, delay_count=0;
  reg endpoint_pending=0;
  reg [64:0] payload_read=0, payload_status_write=0, payload_data_write=0;
  always @(posedge clk) begin
    if (reset) begin
      lot_rsp_valid <= 0;
      lot_rsp_rdata <= 0;
      lot_rsp_error <= 0;
      endpoint_pending <= 0;
      delay_count <= 0;
      lot_count <= 0;
      payload_read <= 0;
      payload_status_write <= 0;
      payload_data_write <= 0;
    end else begin
      if (lot_valid && lot_ready) begin
        if (lot_count == 0) begin
          payload_read <= lot_payload;
          if (lot_payload[64] !== 1'b0 || lot_payload[63:32] !== 32'h1F00_0000)
            $fatal(1, "CPU load did not issue expected LOT CONTROL read: %h", lot_payload);
        end else if (lot_count == 1) begin
          payload_status_write <= lot_payload;
          if (lot_payload[64] !== 1'b1 || lot_payload[63:32] !== 32'h1F00_0008 ||
              lot_payload[31:0] !== 32'h0BAD_C0DE)
            $fatal(1, "CPU store of loaded value did not reach STATUS: %h", lot_payload);
        end else if (lot_count == 2) begin
          payload_data_write <= lot_payload;
          if (lot_payload[64] !== 1'b1 || lot_payload[63:32] !== 32'h1F00_0004 ||
              lot_payload[31:0] !== 32'h7856_3412)
            $fatal(1, "CPU DATA store payload/address mismatch (little-endian bus byte order): %h", lot_payload);
        end else begin
          $fatal(1, "unexpected extra LOT transaction #%0d: %h", lot_count, lot_payload);
        end
        lot_count <= lot_count + 1;
        endpoint_pending <= 1;
        delay_count <= 3;
      end
      if (endpoint_pending && delay_count > 0)
        delay_count <= delay_count - 1;
      if (endpoint_pending && delay_count == 0 && !lot_rsp_valid) begin
        lot_rsp_valid <= 1;
        lot_rsp_rdata <= (payload_read[63:32] == 32'h1F00_0000) ? 32'h0BAD_C0DE : 32'b0;
      end
      if (lot_rsp_valid && lot_rsp_ready) begin
        lot_rsp_valid <= 0;
        endpoint_pending <= 0;
      end
    end
  end

  initial begin
    repeat (4) @(negedge clk);
    reset=0;
    repeat (2000) begin
      @(negedge clk);
      if (lot_count == 3 && ram_line_fill_count == 3 && ram_line_write_count == 1) begin
        if (!(ram_write_payload[31:0] === 32'h1111_0000 ||
              ram_write_payload[63:32] === 32'h1111_0000 ||
              ram_write_payload[95:64] === 32'h1111_0000 ||
              ram_write_payload[127:96] === 32'h1111_0000))
          $fatal(1, "full-core dirty RAM writeback did not contain the modified word: %h", ram_write_payload);
        if (protocol_fault || native_address_rejected)
          $fatal(1, "unexpected wrapper fault during full-core program");
        $display("TB RESULT: PASS - full MIPS32 program executed cacheable RAM fills/dirty eviction and LOT load/status/data transactions");
        $finish;
      end
    end
    $display("DBG PC=%h F1_PC=%h ICacheState=%0d ICacheReady=%b ICacheBlocked=%b inst_pending=%b cmd_seen=%b inst_ready=%b DataRead=%b DataWrite=%b DataV=%h DataP=%h PValid=%b Attr=%b DCacheState=%0d M1Kernel=%b AdEL=%b AdES=%b M1Exc=%b M1Code=%h M2Exc=%b M2Codes=%b W1Exc=%b W1Code=%h", inst_addr, cpu.Core.F1_PC, cpu.ICache.state, cpu.ICache.Ready_C, cpu.ICache.Blocked_C, inst_pending, inst_command_seen, inst_ready, cpu.Core.DataMem_Read, cpu.Core.DataMem_Write, cpu.Core.DataMem_VAddress, cpu.Core.DataMem_PAddress, cpu.Core.DataMem_PAddressValid, cpu.Core.DataMem_CacheAttr, cpu.DCache.state, cpu.Core.M1_KernelMode, cpu.Core.M1_EXC_AdEL, cpu.Core.M1_EXC_AdES, cpu.Core.M1_Exception, cpu.Core.M1_ExcCode, cpu.Core.M2_Exception, cpu.Core.M2_ExcCodes, cpu.Core.W1_ExcActive, cpu.Core.W1_ExcCode);
    $fatal(1, "timeout: full-core program did not issue all expected LOT transactions; count=%0d PC-fetch=%h inst_readword=%b inst_readline=%b data_addr=%h data_read=%b data_write=%b state=%0d", lot_count, inst_addr, inst_read_word, inst_read_line, data_addr, data_read_word, data_write_word, cpu.DCache.state);
  end
endmodule
