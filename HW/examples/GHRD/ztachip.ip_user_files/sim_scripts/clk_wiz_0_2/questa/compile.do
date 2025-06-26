vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xpm
vlib questa_lib/msim/xil_defaultlib

vmap xpm questa_lib/msim/xpm
vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xpm  -sv "+incdir+../../../ipstatic" \
"E:/vivado/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"E:/vivado/Vivado/2020.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm  -93 \
"E:/vivado/Vivado/2020.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  "+incdir+../../../ipstatic" \
"../../../../ztachip.gen/sources_1/ip/clk_wiz_0_2/clk_wiz_0_clk_wiz.v" \
"../../../../ztachip.gen/sources_1/ip/clk_wiz_0_2/clk_wiz_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

