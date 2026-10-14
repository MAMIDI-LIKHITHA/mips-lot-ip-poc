`timescale 1ns/1ps
module tb_openmips_native_cache_adapter;
  reg [33:0] native_addr=0;
  reg native_read_line=0, native_read_word=0;
  reg native_line_write_ready=0, native_word_write_ready=0;
  reg [3:0] native_word_write_be=0;
  reg [127:0] native_data_out=0;
  reg native_read_word_paddr_valid=0, native_word_write_paddr_valid=0;
  wire [29:0] bridge_word_addr;
  wire bridge_read_line, bridge_read_word, bridge_line_write_ready, bridge_word_write_ready;
  wire [3:0] bridge_word_write_be;
  wire [127:0] bridge_data_out;
  wire bridge_paddr_valid;
  wire [2:0] bridge_cache_attr;
  wire address_rejected;

  openmips_native_cache_adapter dut (.*);

  initial begin
    // Uncacheable native read: exact transaction qualification follows the command.
    native_addr=34'h07c0_0000; // byte address 0x1F00_0000, expressed in words
    native_read_word=1;
    native_read_word_paddr_valid=1;
    #1;
    if (!bridge_read_word || bridge_read_line || !bridge_paddr_valid ||
        bridge_cache_attr !== 3'b010 || address_rejected)
      $fatal(1, "valid uncacheable read was not qualified/routed correctly");
    if (bridge_word_addr !== 30'h07c0_0000)
      $fatal(1, "word address changed unexpectedly: %h", bridge_word_addr);

    // Queued uncacheable write uses its queued validity, not the read sideband.
    native_read_word=0;
    native_word_write_ready=1;
    native_word_write_paddr_valid=1;
    native_word_write_be=4'b1111;
    native_data_out[31:0]=32'hCAFE_BABE;
    #1;
    if (!bridge_word_write_ready || bridge_word_write_be !== 4'b1111 ||
        !bridge_paddr_valid || bridge_cache_attr !== 3'b010)
      $fatal(1, "valid queued word write was not routed correctly");
    if (bridge_data_out[31:0] !== 32'hCAFE_BABE)
      $fatal(1, "write payload changed");

    // A cache-line fill remains a RAM command and is not marked uncacheable.
    native_word_write_ready=0;
    native_read_line=1;
    native_addr=34'h0000_0004;
    #1;
    if (!bridge_read_line || bridge_read_word || bridge_cache_attr !== 3'b000 ||
        !bridge_paddr_valid || address_rejected)
      $fatal(1, "cache-line read did not remain on the RAM path");

    // High physical-address bits must suppress every downstream command.
    native_read_line=0;
    native_word_write_ready=1;
    native_addr=34'h4000_0001;
    #1;
    if (!address_rejected || bridge_word_write_ready || bridge_read_word ||
        bridge_line_write_ready || bridge_read_line)
      $fatal(1, "out-of-range physical address was not fail-closed");

    $display("TB RESULT: PASS - native command qualification, line routing, and high-address rejection");
    $finish;
  end
endmodule
