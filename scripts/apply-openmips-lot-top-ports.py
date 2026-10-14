#!/usr/bin/env python3
"""Expose transaction-aligned D-cache qualification from the pinned MIPS32 top."""
from pathlib import Path

p = Path("upstream/OpenMIPS/hardware/src/MIPS32/MIPS32.v")
s = p.read_text()

def replace_one(old: str, new: str, label: str) -> None:
    global s
    count = s.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one match, got {count}")
    s = s.replace(old, new, 1)

replace_one(
    "    output [3:0]          DataMem_WriteWordBE,     // Byte enable signals for a data write word command\n",
    "    output [3:0]          DataMem_WriteWordBE,     // Byte enable signals for a data write word command\n"
    "    output                DataMem_ReadWordPAddressValid, // Qualification captured with the active uncacheable read\n"
    "    output                DataMem_WriteWordPAddressValid, // Qualification captured with the queued word write\n",
    "expose qualification outputs",
)
replace_one(
    "    wire [3:0]           DCache_WordOutBE_M;\n",
    "    wire [3:0]           DCache_WordOutBE_M;\n"
    "    wire                 DCache_WordOutPAddressValid_M;\n"
    "    wire                 DCache_ReadWordPAddressValid_M;\n",
    "declare cache qualification wires",
)
replace_one(
    "    assign DataMem_WriteWordBE    = DCache_WordOutBE_M;\n",
    "    assign DataMem_WriteWordBE    = DCache_WordOutBE_M;\n"
    "    assign DataMem_ReadWordPAddressValid = DCache_ReadWordPAddressValid_M;\n"
    "    assign DataMem_WriteWordPAddressValid = DCache_WordOutPAddressValid_M;\n",
    "export cache qualification",
)
replace_one(
    "        .WordOutBE_M     (DCache_WordOutBE_M),      // output [3 : 0] WordOutBE_M\n",
    "        .WordOutBE_M     (DCache_WordOutBE_M),      // output [3 : 0] WordOutBE_M\n"
    "        .WordOutPAddressValid_M (DCache_WordOutPAddressValid_M),\n"
    "        .ReadWordPAddressValid_M (DCache_ReadWordPAddressValid_M),\n",
    "connect cache qualification ports",
)
p.write_text(s)
print("Exposed transaction-aligned D-cache qualification from the pinned MIPS32 top.")
