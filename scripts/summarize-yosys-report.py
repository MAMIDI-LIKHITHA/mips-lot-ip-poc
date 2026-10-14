#!/usr/bin/env python3
"""Summarize the final Yosys generic-statistics block without implying target PPA."""
from pathlib import Path
import re
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: summarize-yosys-report.py <yosys-log> <markdown-output>")

log_path, output_path = map(Path, sys.argv[1:])
text = log_path.read_text(errors="replace")
matches = list(re.finditer(r"(?m)^\s*Number of wires:\s+([0-9,]+)\s*$", text))
if not matches:
    raise SystemExit("could not find Yosys 'Number of wires' statistics")
start = matches[-1].start()
tail = text[start:]
def stat(name):
    match = re.search(rf"(?m)^\s*{re.escape(name)}:\s+([0-9,]+)\s*$", tail)
    return int(match.group(1).replace(",", "")) if match else None

wires = stat("Number of wires")
wire_bits = stat("Number of wire bits")
mem_bits = stat("Number of memory bits")
cells = stat("Number of cells")
if any(value is None for value in (wires, wire_bits, mem_bits, cells)):
    raise SystemExit("final Yosys statistics block is incomplete")

warning_lines = [line.strip() for line in text.splitlines()
                 if re.search(r"\bWarning:", line)]
rows = [
    "# OpenMIPS generic synthesis summary",
    "",
    f"- Yosys report source: `{log_path.name}`",
    "- Top: `openmips_mips32_lot_system`",
    "- Flow: generic Yosys synthesis with `synth -noabc`",
    f"- Generic cells: **{cells:,}**",
    f"- Wires: {wires:,}",
    f"- Wire bits: {wire_bits:,}",
    f"- Memory bits in generic netlist: {mem_bits:,}",
    f"- Warning lines in full log: {len(warning_lines)}",
    "",
    "## Interpretation limits",
    "",
    "These are generic synthesis statistics, not target FPGA LUT/BRAM/DSP utilization,",
    "ASIC standard-cell area, gate equivalents, timing, power, or physical implementation.",
    "Generated BRAM/DSP modules are black boxes and ABC target mapping is disabled.",
    "",
]
output_path.write_text("\n".join(rows))
print("\n".join(rows))
