#!/usr/bin/env python3
"""Apply reviewed qualification changes to the pinned OpenMIPS cache source."""
from pathlib import Path

p = Path("upstream/OpenMIPS/hardware/src/MIPS32/Cache/DCache/DataCache_2KB.v")
lines = p.read_text().splitlines(keepends=True)

def find_all(predicate):
    return [i for i, line in enumerate(lines) if predicate(line)]

def replace_one(predicate, replacement, label):
    found = find_all(predicate)
    if len(found) != 1:
        raise SystemExit(f"{label}: expected one match, got {len(found)}")
    lines[found[0]] = replacement

# Add a sideband sourced from the exact FIFO head, not live CPU-side pins.
replace_one(lambda x: "output [3:0]" in x and "WordOutBE_M," in x,
            "    output [3:0]           WordOutBE_M,      // Byte enable bits for single-word memory writes (using 'WordOutReady_M').\n    output                 WordOutPAddressValid_M, // Validity captured with this queued word transaction.\n    output                 ReadWordPAddressValid_M, // Validity captured with this uncacheable read transaction.\n",
            "add queued qualification port")

replace_one(lambda x: "wire        s_uncacheable;" in x,
            "    reg         s_uncacheable;         // Latched cache attribute for the service request\n    reg         s_paddr_valid;         // Latched physical-address-valid for the service request\n",
            "latch service qualification")

replace_one(lambda x: "WB_DataIn;" in x and "reg" in x,
            "    reg  [((PABITS-5)+130):0] WB_DataIn;    // Existing payload plus queued PAddressValid metadata\n",
            "extend write buffer input")
replace_one(lambda x: "WB_DataOut;" in x and "wire" in x,
            "    wire [((PABITS-5)+130):0] WB_DataOut;   // Existing payload plus queued PAddressValid metadata\n",
            "extend write buffer output")

replace_one(lambda x: "assign WordOutBE_M" in x,
            "    assign WordOutBE_M    = WB_DataOut[36:33];\n    assign WordOutPAddressValid_M = WB_DataOut[((PABITS-5)+130)];\n    assign ReadWordPAddressValid_M = ReadWord_M & s_paddr_valid;\n",
            "export queued qualification")

replace_one(lambda x: "assign s_uncacheable" in x,
            "",
            "remove live cache attribute")

replace_one(lambda x: "ff_using_delay_data" in x,
            "    DFF_E #(.WIDTH(1)) ff_using_delay_data (.clock(clock), .enable(1'b1),          .D(delay_update),     .Q(using_delay_data));\n\n    // Keep qualification aligned with the service request, not live processor\n    // sidebands that may change while a queued write waits for Ready_M.\n    always @(posedge clock) begin\n        if (reset) begin\n            s_uncacheable <= 1'b0;\n            s_paddr_valid <= 1'b0;\n        end\n        else if (new_request) begin\n            s_uncacheable <= (CacheAttr_C == 3'b010);\n            s_paddr_valid <= PAddressValid_C;\n        end\n    end\n",
            "latch request qualification")

# Store the service qualification in every FIFO entry; word commands expose it.
la = find_all(lambda x: "// {la[160:129]" in x)
if len(la) != 1:
    raise SystemExit(f"write-buffer data block: expected one header, got {len(la)}")
starts = [i for i, line in enumerate(lines) if "always @(*) begin" in line and 0 <= la[0] - i <= 6]
if len(starts) != 1:
    raise SystemExit("write-buffer data block: could not locate its combinational block")
lines.insert(starts[0] + 1, "        WB_DataIn[((PABITS-5)+130)] <= s_paddr_valid;\n")

replace_one(lambda x: ".DATA_WIDTH" in x and "PABITS-5" in x,
            "        .DATA_WIDTH  (((PABITS-5)+130+1)),\n",
            "widen write buffer")

p.write_text("".join(lines))
print("Applied queued qualification metadata to the pinned OpenMIPS cache.")
