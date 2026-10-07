#!/bin/sh
set -eu

COMMON="rtl/crossbar/xbar_scheduler.sv \
rtl/crossbar/xbar_4x4.sv \
rtl/interconnect/lot_txn_router.sv \
rtl/interconnect/lot_rsp_router.sv \
rtl/mips_if/mips_mmio_adapter_candidate.sv"

iverilog -g2012 -s tb_xbar_4x4 -o sim_xbar.out $COMMON tb/tb_xbar_4x4.sv
vvp sim_xbar.out

iverilog -g2012 -s tb_lot_rsp_router -o sim_rsp.out $COMMON tb/tb_lot_rsp_router.sv
vvp sim_rsp.out

iverilog -g2012 -s tb_end_to_end_candidate -o sim_e2e.out $COMMON tb/tb_end_to_end_candidate.sv
vvp sim_e2e.out
