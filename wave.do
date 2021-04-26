onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top_tb/uut/CLK
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/rd_tvalid
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/rd_tready
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/rd_tfirst
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/wr_tvalid
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/wr_tready
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/wr_tfirst
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/ch
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/ddr_s_tvalid
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/ddr_s_tready
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/ddr_s_tlast
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/ddr_s_tdata
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/ddr_s_tcmd
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/ddr_s_taddr
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/cmd_tvalid
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/cmd_tready
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/cmd_instr
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/cmd_byte_addr
add wave -noupdate /top_tb/uut/ddr2_interconnect_inst/cmd_bl
add wave -noupdate /top_tb/uut/ddr2_inst/c3_p0_rd_clk
add wave -noupdate /top_tb/uut/ddr2_inst/c3_p0_rd_count
add wave -noupdate /top_tb/uut/ddr2_inst/c3_p0_rd_data
add wave -noupdate /top_tb/uut/ddr2_inst/c3_p0_rd_empty
add wave -noupdate /top_tb/uut/ddr2_inst/c3_p0_rd_en
add wave -noupdate /top_tb/uut/ddr2_inst/c3_p0_rd_error
add wave -noupdate /top_tb/uut/ddr2_inst/c3_p0_rd_full
add wave -noupdate /top_tb/uut/ddr2_inst/c3_p0_rd_overflow
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {29922785 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 20
configure wave -griddelta 160
configure wave -timeline 1
configure wave -timelineunits us
update
WaveRestoreZoom {33420479 ps} {49170495 ps}
