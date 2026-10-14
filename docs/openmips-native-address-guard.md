# Native OpenMIPS Address Guard

## Purpose

The pinned OpenMIPS `DataCache_2KB` defaults to `PABITS=36`, so its native memory-side `Address_M` is a 34-bit **word address**. The candidate LOT bridge currently uses a 30-bit word address for its 32-bit byte-address map. `openmips_native_addr_guard` checks native bits `[33:30]` before allowing the lower 30 bits to reach a bridge-facing adapter input.

## Contract

- Input `command_valid` qualifies whether an address is being presented as a command.
- If any `native_word_addr[33:30]` bit is set while a command is valid, `bridge_command_valid` is suppressed and `address_rejected` is asserted.
- If the upper bits are zero, the lower 30 word-address bits are preserved unchanged.
- Convert a validated bridge word address to byte address by appending `2'b00` exactly once downstream.

## Verification

`tb/tb_openmips_native_addr_guard.sv` checks idle behavior, zero address, the LOT aperture address, the highest 32-bit byte address representable by the 30-bit word address, and rejection of a nonzero upper physical-address bit. The dedicated workflow compiles and runs this test with Icarus Verilog.

## Important limitation

This guard is an isolated, verified-width-checking stage; it is **not yet wired into** `openmips_lot_memory_bridge`. It also does not solve transaction-aligned physical-valid/cache-attribute qualification for write-buffer entries. Do not claim native cache-to-LOT integration until both the address guard and correctly aligned qualification are connected in a testbench instantiating the pinned cache, and the end-to-end regression passes.