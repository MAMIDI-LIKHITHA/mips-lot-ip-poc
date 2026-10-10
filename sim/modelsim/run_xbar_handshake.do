# Ready/valid hardening regression for the 4x4 crossbar.
# Run from the repository root in ModelSim/Questa:
#   do sim/modelsim/run_xbar_handshake.do
#
# The script compiles once, runs every functional testbench in sequence, and
# exits with a non-zero status on Tcl/simulator errors. The stress test ends
# with $finish so it does not leave the simulator paused at an unexpected $stop.
# SVA remains a separate optional run because some ModelSim Intel FPGA Edition
# versions have limited/unsupported concurrent assertion support.

transcript on

# Fail fast on simulator errors or an unexpected break (for example, $stop).
onerror {quit -code 1}
onbreak {quit -code 1}

if {[file exists work]} {
    if {[catch {vdel -lib work -all} err]} {
        puts "ERROR: Could not remove existing work library: $err"
        quit -code 1
    }
}
if {[catch {vlib work} err]} {
    puts "ERROR: Could not create work library: $err"
    quit -code 1
}
if {[catch {vmap work work} err]} {
    puts "ERROR: Could not map work library: $err"
    quit -code 1
}

if {[catch {
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
} err]} {
    puts "ERROR: Compilation failed: $err"
    quit -code 1
}

set testbenches {
    tb_xbar_4x4
    tb_xbar_backpressure_stability
    tb_xbar_multi_output
    tb_xbar_coverage
    tb_xbar_invalid_dst
    tb_xbar_reset
    tb_xbar_stress_latency
}

foreach tb $testbenches {
    puts "\n========== RUNNING $tb =========="
    if {[catch {vsim -voptargs=+acc work.$tb} err]} {
        puts "ERROR: Could not load $tb: $err"
        quit -code 1
    }
    if {[catch {run -all} err]} {
        puts "ERROR: Simulation failed in $tb: $err"
        quit -code 1
    }
    quit -sim
}

puts "\nREGRESSION RESULT: PASS - all seven functional testbenches completed."
# Leave the ModelSim GUI open after a successful run so the transcript can be reviewed.
