`timescale 1ns/1ps
module tb_openmips_native_addr_guard;
    logic [33:0] native_word_addr;
    logic command_valid;
    logic [29:0] bridge_word_addr;
    logic bridge_command_valid, address_rejected;

    openmips_native_addr_guard dut (.*);

    task automatic check(input logic ok, input string msg);
        if (!ok) $fatal(1, "FAIL: %s", msg);
        $display("PASS: %s", msg);
    endtask

    initial begin
        command_valid = 0;
        native_word_addr = 34'h0;
        #1;
        check(!bridge_command_valid && !address_rejected, "idle command remains inactive");

        command_valid = 1;
        native_word_addr = 34'h000000000;
        #1;
        check(bridge_command_valid && !address_rejected && bridge_word_addr == 30'h0,
              "zero address is preserved");

        native_word_addr = 34'h01F000000 >> 2;
        #1;
        check(bridge_command_valid && !address_rejected &&
              bridge_word_addr == (30'h1F000000 >> 2),
              "LOT aperture address survives native word-address conversion");

        native_word_addr = {4'h0, 30'h3FFFFFFF};
        #1;
        check(bridge_command_valid && !address_rejected &&
              bridge_word_addr == 30'h3FFFFFFF,
              "highest representable 32-bit byte address does not alias");

        native_word_addr = {4'h1, 30'h00001234};
        #1;
        check(!bridge_command_valid && address_rejected,
              "nonzero upper physical-address bits block command");

        command_valid = 0;
        #1;
        check(!bridge_command_valid && !address_rejected,
              "invalid upper bits are not reported when no command is active");

        $display("TB RESULT: PASS - native OpenMIPS address guard");
        $finish;
    end
endmodule
