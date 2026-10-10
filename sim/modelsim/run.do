# Unified functional regression for the LOT IP POC.
# Run from the repository root:
#   do sim/modelsim/run.do
#
# Runs seven crossbar tests plus the transaction router, response router,
# and end-to-end integration test. Simulation-only: no FPGA hardware,
# synthesis, or timing-closure claims.

transcript on
onerror {quit -code 1}

# Unload any design left from a previous manual simulation.
catch {quit -sim}

# Reuse the work library if present; create it only when absent.
if {![file exists work]} {
    if {[catch {vlib work} err]} {
        puts "REGRESSION RESULT: FAIL - could not create work library: $err"
        quit -code 1
    }
}
if {[catch {vmap work work} err]} {
    puts "REGRESSION RESULT: FAIL - could not map work library: $err"
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

set passed 0
set failed 0

foreach tb $testbenches {
    set log_file "sim/modelsim/regression_${tb}.log"
    puts "\n========== RUNNING $tb =========="

    # Capture this test alone so a prior PASS cannot hide a later failure.
    catch {transcript file -close}
    catch {file delete -force $log_file}
    transcript file $log_file

    if {[catch {vsim -onfinish stop -voptargs=+acc work.$tb} err]} {
        catch {transcript file -close}
        puts "REGRESSION RESULT: FAIL - could not load $tb"
        puts $err
        quit -code 1
    }
    if {[catch {run -all} err]} {
        catch {transcript file -close}
        puts "REGRESSION RESULT: FAIL - simulation error in $tb"
        puts $err
        quit -code 1
    }

    # Close the transcript before reading the test-specific log.
    catch {transcript file -close}
    if {![file exists $log_file]} {
        puts "REGRESSION RESULT: FAIL - no transcript generated for $tb"
        quit -code 1
    }

    set fp [open $log_file r]
    set output [read $fp]
    close $fp

    if {![string match "*TB RESULT: PASS*" $output]} {
        incr failed
        puts "FAIL: $tb did not emit the required 'TB RESULT: PASS' marker."
        puts "See $log_file for the test transcript."
        quit -code 1
    }

    incr passed
    puts "PASS: $tb"
    quit -sim
}

puts "\n=============================================="
puts "REGRESSION SUMMARY: $passed passed, $failed failed"
if {$failed == 0 && $passed == [llength $testbenches]} {
    puts "REGRESSION RESULT: PASS"
} else {
    puts "REGRESSION RESULT: FAIL"
}
puts "Per-test transcripts: sim/modelsim/regression_<testbench>.log"
puts "=============================================="

if {$failed != 0 || $passed != [llength $testbenches]} {
    quit -code 1
}
quit -f
