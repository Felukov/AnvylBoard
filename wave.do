onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/clk
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/resetn
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/next_frame_s_tvalid
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/next_frame_s_tready
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/next_frame_tvalid
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/next_frame_tready
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_cmd_m_tvalid
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_cmd_m_tready
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_cmd_tvalid
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_cmd_tready
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_cmd_cnt
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_cmd_m_tlast
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_cmd_m_taddr
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_cmd_taddr
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_data_s_tvalid
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_data_s_tready
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_data_s_tdata
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/fifo_tvalid
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/fifo_tready
add wave -noupdate -expand -group tft_reader -radix decimal /top_tb/uut/tft_inst/tft_ddr2_reader_inst/fifo_cnt
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/fifo_tdata
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/filter_tvalid
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/filter_tready
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/filter_tdata
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_data_m_tvalid
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_data_m_tready
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_data_m_tdata
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_data_tvalid
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_data_tready
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_data_idx
add wave -noupdate -expand -group tft_reader /top_tb/uut/tft_inst/tft_ddr2_reader_inst/rd_data_tdata
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/clk
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/resetn
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/ch
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/cmd_en
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/cmd_instr
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/cmd_addr
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/cmd_bl
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/cmd_byte_addr
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/cmd_empty
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/cmd_full
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/cmd_tvalid
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/cmd_tready
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_s_tvalid
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_tvalid
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_s_tready
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_tready
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_s_tlast
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_s_taddr
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_s_tvalid
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_tvalid
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_s_tready
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_tready
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_s_tlast
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_s_taddr
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_s_tdata
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/ddr_s_tvalid
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/ddr_s_tready
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/ddr_s_tlast
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/ddr_s_tcmd
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/ddr_s_taddr
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/ddr_s_tdata
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_en
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_empty
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_full
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_overflow
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_count
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_error
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_data
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_m_tvalid
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_m_tready
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_m_tlast
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_m_tdata
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_en
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_empty
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_full
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_underrun
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_count
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_data
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_error
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_mask
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/rd_tfirst
add wave -noupdate -group ddr_interconnect /top_tb/uut/ddr2_interconnect_inst/wr_tfirst
add wave -noupdate -group vid_mem_gen /top_tb/uut/vid_mem_gen_inst/clk
add wave -noupdate -group vid_mem_gen -radix decimal /top_tb/uut/vid_mem_gen_inst/x
add wave -noupdate -group vid_mem_gen /top_tb/uut/vid_mem_gen_inst/y
add wave -noupdate -group vid_mem_gen /top_tb/uut/vid_mem_gen_inst/pixel_tvalid
add wave -noupdate -group vid_mem_gen /top_tb/uut/vid_mem_gen_inst/pixel_tready
add wave -noupdate -group vid_mem_gen -expand /top_tb/uut/vid_mem_gen_inst/pixel_tdata
add wave -noupdate -group vid_mem_gen /top_tb/uut/vid_mem_gen_inst/pixel_tlast
add wave -noupdate -group vid_mem_gen /top_tb/uut/vid_mem_gen_inst/ddr_data_tvalid
add wave -noupdate -group vid_mem_gen /top_tb/uut/vid_mem_gen_inst/ddr_data_tready
add wave -noupdate -group vid_mem_gen /top_tb/uut/vid_mem_gen_inst/ddr_data_tlast
add wave -noupdate -group vid_mem_gen /top_tb/uut/vid_mem_gen_inst/ddr_data_tdata
add wave -noupdate -group vid_mem_gen -radix decimal /top_tb/uut/vid_mem_gen_inst/wr_fifo_cnt
add wave -noupdate -group vid_mem_gen /top_tb/uut/vid_mem_gen_inst/wr_tvalid
add wave -noupdate -group vid_mem_gen /top_tb/uut/vid_mem_gen_inst/wr_tready
add wave -noupdate -group vid_mem_gen /top_tb/uut/vid_mem_gen_inst/wr_taddr
add wave -noupdate -group vid_mem_gen -expand /top_tb/uut/vid_mem_gen_inst/wr_tdata
add wave -noupdate -expand -group tft /top_tb/uut/tft_inst/clk_100
add wave -noupdate -expand -group tft /top_tb/uut/tft_inst/init_done
add wave -noupdate -expand -group tft /top_tb/uut/tft_inst/local_rst
add wave -noupdate -expand -group tft /top_tb/uut/tft_inst/next_frame_tvalid
add wave -noupdate -expand -group tft -radix unsigned -radixshowbase 0 /top_tb/uut/tft_inst/delay_cnt
add wave -noupdate -expand -group tft /top_tb/uut/tft_inst/state
add wave -noupdate -expand -group tft /top_tb/uut/tft_inst/state_next
add wave -noupdate -expand -group tft /top_tb/uut/tft_inst/tft_clk_en
add wave -noupdate -expand -group tft /top_tb/uut/tft_inst/vde
add wave -noupdate -expand -group tft -radix decimal /top_tb/uut/tft_inst/x
add wave -noupdate -expand -group tft -radix decimal /top_tb/uut/tft_inst/y
add wave -noupdate -expand -group tft /top_tb/uut/tft_inst/tft_r
add wave -noupdate -expand -group tft /top_tb/uut/tft_inst/tft_g
add wave -noupdate -expand -group tft /top_tb/uut/tft_inst/tft_b
add wave -noupdate -group tft_reader_fifo -radix decimal /top_tb/uut/tft_inst/tft_ddr2_reader_inst/tft_fifo_inst/wr_addr
add wave -noupdate -group tft_reader_fifo -radix decimal /top_tb/uut/tft_inst/tft_ddr2_reader_inst/tft_fifo_inst/rd_addr
add wave -noupdate -group tft_reader_fifo /top_tb/uut/tft_inst/tft_ddr2_reader_inst/tft_fifo_inst/fifo_s_tvalid
add wave -noupdate -group tft_reader_fifo /top_tb/uut/tft_inst/tft_ddr2_reader_inst/tft_fifo_inst/fifo_m_tvalid
add wave -noupdate -group tft_reader_fifo /top_tb/uut/tft_inst/tft_ddr2_reader_inst/tft_fifo_inst/in_tvalid
add wave -noupdate -group tft_reader_fifo /top_tb/uut/tft_inst/tft_ddr2_reader_inst/tft_fifo_inst/in_tready
add wave -noupdate -group tft_reader_fifo /top_tb/uut/tft_inst/tft_ddr2_reader_inst/tft_fifo_inst/out_tvalid
add wave -noupdate -group tft_reader_fifo /top_tb/uut/tft_inst/tft_ddr2_reader_inst/tft_fifo_inst/out_tready
add wave -noupdate -group tft_reader_fifo /top_tb/uut/tft_inst/tft_ddr2_reader_inst/tft_fifo_inst/out_tdata
add wave -noupdate -group tft_reader_fifo /top_tb/uut/tft_inst/tft_ddr2_reader_inst/tft_fifo_inst/fifo_is_empty
add wave -noupdate -group tft_reader_fifo /top_tb/uut/tft_inst/tft_ddr2_reader_inst/tft_fifo_inst/fifo_is_full
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {823775000 ps} 0} {{Cursor 2} {276393008 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 215
configure wave -valuecolwidth 204
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
WaveRestoreZoom {553121272 ps} {977748728 ps}
