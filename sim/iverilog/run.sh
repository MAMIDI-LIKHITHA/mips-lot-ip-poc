#!/bin/sh
set -eu

iverilog -g2012 -s tb_xbar_4x4 -o sim.out \
  rtl/crossbar/xbar_scheduler.sv \
  rtl/crossbar/xbar_4x4.sv \
  tb/tb_xbar_4x4.sv

vvp sim.out
