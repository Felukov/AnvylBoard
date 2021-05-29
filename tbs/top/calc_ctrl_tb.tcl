#Maximize window
wm state . zoom

#Show all as hex
radix -hexadecimal

#Supress Numeric Std package and Arith package warnings.#
#For VHDL designs we get some warnings due to unknown values on some signals at startup#
# ** Warning: NUMERIC_STD.TO_INTEGER: metavalue detected, returning 0#
#We may also get some Arithmetic packeage warnings because of unknown values on#
#some of the signals that are used in an Arithmetic operation.#
#In order to suppress these warnings, we use following two commands#
set NumericStdNoWarnings 1
set StdArithNoWarnings 1

#
# Create work library
#
#vdel -all
vlib work

#
# Compile sources
#

#Compile files (excluding model parameter file)#

vcom -explicit  -93 "./src/utils/axis_reg.vhd"
vcom -explicit  -93 "./src/utils/axis_interconnect.vhd"


vcom -explicit  -93 "./src/top/calc_ctrl.vhd"
vcom -explicit  -93 "./tbs/top/calc_ctrl_tb.vhd"

#Run simulation
vsim -novopt -t ps +notimingchecks work.calc_ctrl_tb

#Add waves
add wave -position insertpoint sim:/calc_ctrl_tb/uut/*

# Run simulation for this time
run 1us

