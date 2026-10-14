// Validates the native OpenMIPS PABITS=36 word address before narrowing it
// for the candidate 32-bit bridge. This guard does not solve qualification
// alignment for queued writes; it is a deliberately separate adapter stage.
module openmips_native_addr_guard (
    input  logic [33:0] native_word_addr,
    input  logic        command_valid,
    output logic [29:0] bridge_word_addr,
    output logic        bridge_command_valid,
    output logic        address_rejected
);
    always_comb begin
        bridge_word_addr = native_word_addr[29:0];
        address_rejected = command_valid && (|native_word_addr[33:30]);
        bridge_command_valid = command_valid && !(|native_word_addr[33:30]);
    end
endmodule
