# Anvyl Board Demo Project

## Short Description
This project is a simple digital hex calculator. The project has been implemented in pure HDL (mostly VHDL) without any usage of CPU.

## Goals
The main goals of the project is to implement a relatively simple but complete system in HDL that utilizes different components of Digilent Anvyl FPGA Board and can be served as a reference design.

The design icludes the following subcomponents that can be reused in the different projects:
* Xilinx MIG DDR2 controller instantiation and access to data stored in DDR from different sources.
* TFT Controller (mostly rework of reference designs from Digilent)
* Touch Screen Controller (communication with ADC via SPI and convertion of sampled data to XY coordinates)
* OLED Controller (mostly rework of reference designs from Digilent)
* DSP (wrappers with AXI-stream interfaces over DSP macros)
* UART RX/TX support
* Handling of user input (buttons, keypads, touchscreen)
* Common components such as AXI-stream Register, Interconnect, Divider, Debouncers, Timers, etc

The design also includes some testbenches that were developed mostly for debug purposes. They mostly cover only straightway behaviour of the components.

![Board](https://github.com/Felukov/AnvylBoard/blob/master/doc/IMG_2663.JPEG)
