## Clock signal

set_property -dict { PACKAGE_PIN AE10  IOSTANDARD DIFF_SSTL12 } [get_ports CLK_125_P]
set_property -dict { PACKAGE_PIN AF10  IOSTANDARD DIFF_SSTL12 } [get_ports CLK_125_N]
create_clock -period 8.000 -name clk_125_pin -waveform {0.000 4.000} [get_ports CLK_125_P]

# SI570 Differential Clock (300 MHz) for DDR4 MIG sys_clk_i
set_property PACKAGE_PIN AL8 [get_ports SI570_P]
set_property PACKAGE_PIN AL7 [get_ports SI570_N]
set_property IOSTANDARD DIFF_SSTL12 [get_ports {SI570_P SI570_N}]
set_property DIFF_TERM TRUE [get_ports {SI570_P SI570_N}]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_ports {SI570_P}]



##C  SW15
set_property -dict {PACKAGE_PIN AG13 IOSTANDARD LVCMOS33} [get_ports sys_resetn]  

##LEDs

set_property -dict {PACKAGE_PIN AG14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN AF13 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN AE13 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN AJ14 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports UART_TXD]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports UART_RXD]
#set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports UART_TXD]
#set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33} [get_ports UART_RXD]
##E    SW17
set_property -dict {PACKAGE_PIN AE14 IOSTANDARD LVCMOS33} [get_ports {pushbutton[0]}] 
##S    16
set_property -dict {PACKAGE_PIN AE15 IOSTANDARD LVCMOS33} [get_ports {pushbutton[1]}]
##N   18 
set_property -dict {PACKAGE_PIN AG15 IOSTANDARD LVCMOS33} [get_ports {pushbutton[2]}] 
##W   14
set_property -dict {PACKAGE_PIN AF15 IOSTANDARD LVCMOS33} [get_ports {pushbutton[3]}] 

##Pmod Header JA

set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS33} [get_ports {VGA_R[0]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS33} [get_ports {VGA_R[1]}]
set_property -dict {PACKAGE_PIN A22 IOSTANDARD LVCMOS33} [get_ports {VGA_R[2]}]
set_property -dict {PACKAGE_PIN A21 IOSTANDARD LVCMOS33} [get_ports {VGA_R[3]}]
set_property -dict {PACKAGE_PIN B21 IOSTANDARD LVCMOS33} [get_ports {VGA_B[0]}]
set_property -dict {PACKAGE_PIN C21 IOSTANDARD LVCMOS33} [get_ports {VGA_B[1]}]
set_property -dict {PACKAGE_PIN C22 IOSTANDARD LVCMOS33} [get_ports {VGA_B[2]}]
set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS33} [get_ports {VGA_B[3]}]

##Pmod Header JB

set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports {VGA_G[0]}]
set_property -dict {PACKAGE_PIN E20 IOSTANDARD LVCMOS33} [get_ports {VGA_G[1]}]
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVCMOS33} [get_ports {VGA_G[2]}]
set_property -dict {PACKAGE_PIN E22 IOSTANDARD LVCMOS33} [get_ports {VGA_G[3]}]
set_property -dict {PACKAGE_PIN F20 IOSTANDARD LVCMOS33} [get_ports VGA_HS_O]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33} [get_ports VGA_VS_O]

##Pmod Header JC
set_property -dict {PACKAGE_PIN J20 IOSTANDARD LVCMOS33} [get_ports CAMERA_SCL]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports CAMERA_VS]
set_property -dict {PACKAGE_PIN AJ15 IOSTANDARD LVCMOS33} [get_ports CAMERA_PCLK]
set_property -dict {PACKAGE_PIN AH13 IOSTANDARD LVCMOS33} [get_ports {CAMERA_D[7]}]
set_property -dict {PACKAGE_PIN AH14 IOSTANDARD LVCMOS33} [get_ports {CAMERA_D[5]}]
set_property -dict {PACKAGE_PIN AL12 IOSTANDARD LVCMOS33} [get_ports {CAMERA_D[3]}]
set_property -dict {PACKAGE_PIN AK13 IOSTANDARD LVCMOS33} [get_ports {CAMERA_D[1]}]
set_property -dict {PACKAGE_PIN AL13 IOSTANDARD LVCMOS33} [get_ports CAMERA_RESET]

##Pmod Header JD
set_property -dict {PACKAGE_PIN AP12 IOSTANDARD LVCMOS33} [get_ports CAMERA_SDR]
set_property -dict {PACKAGE_PIN AN12 IOSTANDARD LVCMOS33} [get_ports CAMERA_RS]
set_property -dict {PACKAGE_PIN AN13 IOSTANDARD LVCMOS33} [get_ports CAMERA_MCLK]
set_property -dict {PACKAGE_PIN AM14 IOSTANDARD LVCMOS33} [get_ports {CAMERA_D[6]}]
set_property -dict {PACKAGE_PIN AP14 IOSTANDARD LVCMOS33} [get_ports {CAMERA_D[4]}]
set_property -dict {PACKAGE_PIN AN14 IOSTANDARD LVCMOS33} [get_ports {CAMERA_D[2]}]
set_property -dict {PACKAGE_PIN K20 IOSTANDARD LVCMOS33} [get_ports {CAMERA_D[0]}]
set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS33} [get_ports CAMERA_PWDN]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets CAMERA_PCLK_IBUF]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]

set_false_path -from [filter [all_fanout -from [get_ports clka]
-flat -endpoints_only] {IS_LEAF}] -through [get_pins -of_objects
[get_cells -hier * -filter {PRIMITIVE_SUBGROUP==LUTRAM ||
PRIMITIVE_SUBGROUP==dram || PRIMITIVE_SUBGROUP==drom}]
-filter {DIRECTION==OUT}]
