#!/usr/bin/env python3
"""Apply reviewed qualification changes to the pinned OpenMIPS cache source."""
from pathlib import Path

p = Path("upstream/OpenMIPS/hardware/src/MIPS32/Cache/DCache/DataCache_2KB.v")
lines = p.read_text().splitlines(keepends=True)

def indices(needle):
    return [i for i, line in enumerate(lines) if needle in line]

def replace_one(needle, replacement, label):
    found = indices(needle)
    if len(found) != 1:
        raise SystemExit(f"{label}: expected one line containing {needle!r}, got {len(found)}")
    lines[found[0]] = replacement

# Export the validity metadata associated with the write-buffer head.
i = indices("WordOutBE_M,")
if len(i) != 1:
    raise SystemExit(f"WordOutBE port: expected one match, got {len(i)}")
lines.insert(i[0] + 1, "    output                 WordOutPAddressValid_M, // Validity captured with this queued word transaction.\n")

replace_one("wire        s_uncacheable;", "    reg         s_uncacheable;         // Latched cache attribute for the service request\n", "latch cache attribute")
replace_one("wire        s_uncacheable;", "    reg         s_uncacheable;         // Latched cache attribute for the service request\n", "latch cache attribute")
