if {![file exists work]} {
  vlib work
}

vlog -sv \
  rtl/crossbar/xbar_scheduler.sv \
  rtl/crossbar/xbar_4x4.sv \
  rtl/interconnect/lot_txn_router.sv \
  rtl/interconnect/lot_rsp_router.sv \
  rtl/mips_if/mips_mmio_adapter_candidate.sv \
  tb/tb_xbar_4x4.sv \
  tb/tb_lot_txn_router.sv \
  tb/tb_lot_rsp_router.sv \
  tb/tb_end_to_end_candidate.sv

vsim work.tb_xbar_4x4
onfinish stop
run -all
quit -sim

vsim work.tb_lot_txn_router
onfinish stop
run -all
quit -sim

vsim work.tb_lot_rsp_router
onfinish stop
run -all
quit -sim

vsim work.tb_end_to_end_candidate
onfinish stop
run -all
quit -sim

quit -f
