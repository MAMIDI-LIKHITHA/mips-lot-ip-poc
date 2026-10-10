# Unified functional regression for the LOT IP POC.
# Run from the repository root:
#   do sim/modelsim/run.do
#
# This runs seven crossbar tests plus the transaction router, response router,
# and end-to-end candidate integration test. It is a simulation-only regression;
# it does not claim FPGA hardware, synthesis, or timing validation.

transcript on
onerror {quit -code 1}

# Unload any design left from a previous manual simulation.
catch {quit -sim}

# Reuse the work library if present; create it only when absent.
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
      rtl/interconnect/lot_txn_router.sv \
      rtl/interconnect/lot_rsp_router.sv \
      rtl/mips_if/mips_mmio_adapter_candidate.sv \
      rtl/endpoints/lot_endpoint_adapter.sv \
      tb/tb_xbar_4x4.sv \
      tb/tb_xbar_backpressure_stability.sv \
      tb/tb_xbar_multi_output.sv \
      tb/tb_xbar_coverage.sv \
      tb/tb_xbar_invalid_dst.sv \
      tb/tb_xbar_reset.sv \
      tb/tb_xbar_stress_latency.sv \
      tb/tb_lot_txn_router.sv \
      tb/tb_lot_rsp_router.sv \
      tb/tb_end_to_end_candidate.sv
} err]} {
    puts "REGRESSION RESULT: FAIL - compilation failed"
    puts $err
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
    tb_lot_txn_router
    tb_lot_rsp_router
    tb_end_to_end_candidate
}

foreach tb $testbenches {
    puts "\n========== RUNNING $tb =========="
    if {[catch {vsim -onfinish stop -voptargs=+acc work.$tb} err]} {
        puts "REGRESSION RESULT: FAIL - could not load $tb"
        puts $err
        quit -code 1
    }
    if {[catch {run -all} err]} {
        puts "REGRESSION RESULT: FAIL - simulation failed in $tb"
        puts $err
        quit -code 1
    }
    quit -sim
}

puts "\nREGRESSION RESULT: SCRIPT COMPLETED - all 10 testbenches executed."
quit -f
