# Ready/valid hardening regression for the 4x4 crossbar.
# Run from the repository root in ModelSim/Questa:
#   do sim/modelsim/run_xbar_handshake.do
#
# This script runs the directed and stress tests affected by the handshake change.
# SVA is kept as a separate optional run because some ModelSim Intel FPGA Edition
# versions report limited/unsupported concurrent assertion support.

transcript on
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

vlog -sv \
  rtl/crossbar/xbar_scheduler.sv \
  rtl/crossbar/xbar_4x4.sv \
  verification/xbar_coverage.sv \
  tb/tb_xbar_4x4.sv \
  tb/tb_xbar_backpressure_stability.sv \
  tb/tb_xbar_multi_output.sv \
  tb/tb_xbar_coverage.sv \
  tb/tb_xbar_invalid_dst.sv \
  tb/tb_xbar_reset.sv \
  tb/tb_xbar_stress_latency.sv

if {[catch {vsim -c work.tb_xbar_4x4 -do "run -all; quit -f"} err]} { puts $err; quit -code 1 }
if {[catch {vsim -c work.tb_xbar_backpressure_stability -do "run -all; quit -f"} err]} { puts $err; quit -code 1 }
if {[catch {vsim -c work.tb_xbar_multi_output -do "run -all; quit -f"} err]} { puts $err; quit -code 1 }
if {[catch {vsim -c work.tb_xbar_coverage -do "run -all; quit -f"} err]} { puts $err; quit -code 1 }
if {[catch {vsim -c work.tb_xbar_invalid_dst -do "run -all; quit -f"} err]} { puts $err; quit -code 1 }
if {[catch {vsim -c work.tb_xbar_reset -do "run -all; quit -f"} err]} { puts $err; quit -code 1 }
if {[catch {vsim -c work.tb_xbar_stress_latency -do "run -all; quit -f"} err]} { puts $err; quit -code 1 }

puts "Ready/valid crossbar regression completed. Confirm every TB RESULT is PASS in the transcript."
quit -f
