vlib work
vmap work work

vlog -sv \
  rtl/crossbar/xbar_scheduler.sv \
  rtl/crossbar/xbar_4x4.sv \
  tb/tb_xbar_4x4.sv

vsim -c tb_xbar_4x4 -do "run -all; quit -f"
