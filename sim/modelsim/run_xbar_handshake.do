# Ready/valid hardening regression for the 4x4 crossbar.
# Run from the repository root in ModelSim/Questa:
#   do sim/modelsim/run_xbar_handshake.do
#
# The script compiles once and runs all seven functional testbenches.
# -onfinish stop keeps $finish in a testbench from closing the simulator,
# allowing the Tcl loop to continue with the next test.
# SVA remains a separate optional run because some ModelSim Intel FPGA Edition
# versions have limited/unsupported concurrent assertion support.

transcript on

# Fail fast on simulator errors or an unexpected break (for example, $stop).
onerror {quit -code 1}
onbreak {quit -code 1}

# Unload any design left from a previous manual simulation.
catch {quit -sim}

# Reuse an existing work library instead of deleting it (vdel can fail on
# Windows when library database files are locked). Create it only if absent.
if {![file exists work]} {
    if {[catch {vlib work} err]} {
        puts "ERROR: Could not create work library: $err"
        quit -code 1
    }
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
    if {[catch {vsim -onfinish stop -voptargs=+acc work.$tb} err]} {
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
