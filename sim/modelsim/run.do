vlib work
vmap work work

vlog -sv \
  rtl/crossbar/xbar_scheduler.sv \
  rtl/crossbar/xbar_4x4.sv \
  rtl/interconnect/lot_txn_router.sv \
  rtl/interconnect/lot_rsp_router.sv \
  rtl/mips_if/mips_mmio_adapter_candidate.sv \
  tb/tb_xbar_4x4.sv \
  tb/tb_lot_rsp_router.sv

vsim -c tb_xbar_4x4 -do "run -all; quit -f"
vsim -c tb_lot_rsp_router -do "run -all; quit -f"
