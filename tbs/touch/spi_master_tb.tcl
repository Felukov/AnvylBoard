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
vdel -all
vlib work

#
# Compile sources
#

#Compile files (excluding model parameter file)#

vcom -explicit  -93 "./src/utils/axis_reg.vhd"
#vcom -explicit  -93 "./src/utils/axis_interconnect.vhd"


vcom -explicit  -93 "./src/touch/spi_master.vhd"
vcom -explicit  -2002 "./tbs/touch/spi_master_tb.vhd"

#Run simulation
vsim -novopt -t ps +notimingchecks work.spi_master_tb

#Add waves
add wave -position insertpoint sim:/spi_master_tb/uut/*

# Run simulation for this time
run 200us

