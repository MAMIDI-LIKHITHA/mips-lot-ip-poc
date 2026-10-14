#!/usr/bin/env python3
"""Apply the qualification sideband patch to the pinned OpenMIPS cache source."""
from pathlib import Path

p = Path("upstream/OpenMIPS/hardware/src/MIPS32/Cache/DCache/DataCache_2KB.v")
s = p.read_text()

def once(old, new, label):
    global s
    n = s.count(old)
    if n != 1:
        raise SystemExit(f"{label}: expected exactly one match, got {n}")
    s = s.replace(old, new, 1)

once("    output [3:0]           WordOutBE_M,      // Byte enable bits for single-word memory writes (using 'WordOutReady_M').\n",
     "    output [3:0]           WordOutBE_M,      // Byte enable bits for single-word memory writes (using 'WordOutReady_M').\n    output                 WordOutPAddressValid_M, // Validity captured with this queued word transaction.\n",
     "add queued qualification port")
once("    wire        s_uncacheable;         // The service address is in the uncacheable range\n",
     "    reg         s_uncacheable;         // Latched cache attribute for the service request\n    reg         s_paddr_valid;         // Latched physical-address-valid for the service request\n",
     "latch service qualification")
once("    reg  [((PABITS-5)+129):0] WB_DataIn;    // {32-bit line addr, 128-bit line, 1-bit cacheable} OR\n    wire [((PABITS-5)+129):0] WB_DataOut;   // {34-bit word addr, 90-bit X, 4-bit write-enable, 32-bit word, 1-bit uncacheable}\n",
     "    reg  [((PABITS-5)+130):0] WB_DataIn;    // Adds queued PAddressValid above the existing payload/type fields\n    wire [((PABITS-5)+130):0] WB_DataOut;   // Adds queued PAddressValid above the existing payload/type fields\n",
     "extend write buffer metadata")
once("    assign WordOutBE_M    = WB_DataOut[36:33];\n",
     "    assign WordOutBE_M    = WB_DataOut[36:33];\n    assign WordOutPAddressValid_M = WB_DataOut[((PABITS-5)+130)];\n",
     "export queued qualification")
once("    assign s_uncacheable    = (CacheAttr_C == 3'b010);\n",
     "",
     "replace live cache attribute")
once("    DFF_E #(.WIDTH(1)) ff_using_delay_data (.clock(clock), .enable(1'b1),          .D(delay_update),     .Q(using_delay_data));\n",
     "    DFF_E #(.WIDTH(1)) ff_using_delay_data (.clock(clock), .enable(1'b1),          .D(delay_update),     .Q(using_delay_data));\n\n    // Keep qualification aligned with the service request, not live processor\n    // sidebands that may change while a queued write waits for Ready_M.\n    always @(posedge clock) begin\n        if (reset) begin\n            s_uncacheable <= 1'b0;\n            s_paddr_valid <= 1'b0;\n        end\n        else if (new_request) begin\n            s_uncacheable <= (CacheAttr_C == 3'b010);\n            s_paddr_valid <= PAddressValid_C;\n        end\n    end\n",
     "latch request qualification")
once("    // {la[160:129], line[128:1], 1-bit cacheable} OR\n    // {wa[160:127], X[126:37], we[36:33], data[32:1], cached[0]}\n    always @(*) begin\n",
     "    // {la[160:129], line[128:1], 1-bit cacheable} OR\n    // {wa[160:127], X[126:37], we[36:33], data[32:1], cached[0]}\n    always @(*) begin\n        WB_DataIn[((PABITS-5)+130)] <= s_paddr_valid;\n",
     "store qualification in FIFO entry")
once("        .DATA_WIDTH  (((PABITS-5)+129+1)),\n",
     "        .DATA_WIDTH  (((PABITS-5)+130+1)),\n",
     "widen write buffer")
p.write_text(s)
print("Applied queued physical-address-valid/cache-attribute qualification patch.")
