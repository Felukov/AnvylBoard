----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    20:32:02 03/31/2021
-- Design Name:
-- Module Name:    top - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
--
----------------------------------------------------------------------------------
-- Additional Comments:
library UNISIM;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity top is
    generic (
        SIMULATION              : string := "FALSE"
    );
    port (
        CLK                     : in std_logic;
        DDR_CLK_P               : out std_logic;
        DDR_CLK_N               : out std_logic;
        DDR_CLK_EN              : out std_logic;
        DDR_ADDR                : out std_logic_vector(12 downto 0);
        DDR_BA                  : out std_logic_vector(2 downto 0);
        DDR_DATA                : inout std_logic_vector(15 downto 0);
        DDR_RAS_N               : out std_logic;
        DDR_CAS_N               : out std_logic;
        DDR_WE_N                : out std_logic;
        DDR_ODT                 : out std_logic;
        DDR_LDM                 : out std_logic;
        DDR_UDM                 : out std_logic;
        DDR_UDQS_P              : inout std_logic;
        DDR_UDQS_N              : inout std_logic;
        DDR_LDQS_P              : inout std_logic;
        DDR_LDQS_N              : inout std_logic;
        RZQ                     : inout std_logic;
        ZIO                     : inout std_logic;

        SW                      : in std_logic_vector(7 downto 0);
        BTN                     : in std_logic_vector(3 downto 0);
        LED                     : out std_logic_vector(7 downto 0);

        SEG                     : out std_logic_vector(7 downto 0);
        AN                      : out std_logic_vector(5 downto 0);

        TFT_CLK_O               : out std_logic;
        TFT_VDDEN_O             : out std_logic;
        TFT_DE_O                : out std_logic;
        TFT_BKLT_O              : out std_logic;
        TFT_DISP_O              : out std_logic;
        TFT_R_O                 : out std_logic_vector(7 downto 0);
        TFT_G_O                 : out std_logic_vector(7 downto 0);
        TFT_B_O                 : out std_logic_vector(7 downto 0);

        RS232_UART_TX           : out std_logic;
        RS232_UART_RX           : in std_logic
    );
end top;

architecture Behavioral of top is

    constant C3_NUM_DQ_PINS              : integer := 16;
    constant C3_MEM_ADDR_WIDTH           : integer := 13;
    constant C3_MEM_BANKADDR_WIDTH       : integer := 3;
    constant C3_P0_MASK_SIZE             : integer := 16;
    constant C3_P0_DATA_PORT_SIZE        : integer := 128;

    component ddr2 is
        generic (
            C3_SIMULATION                : string
        );
        port (
            mcb3_dram_dq                 : inout std_logic_vector(C3_NUM_DQ_PINS-1 downto 0);
            mcb3_dram_a                  : out std_logic_vector(C3_MEM_ADDR_WIDTH-1 downto 0);
            mcb3_dram_ba                 : out std_logic_vector(C3_MEM_BANKADDR_WIDTH-1 downto 0);
            mcb3_dram_ras_n              : out std_logic;
            mcb3_dram_cas_n              : out std_logic;
            mcb3_dram_we_n               : out std_logic;
            mcb3_dram_odt                : out std_logic;
            mcb3_dram_cke                : out std_logic;
            mcb3_dram_dm                 : out std_logic;
            mcb3_dram_udqs               : inout std_logic;
            mcb3_dram_udqs_n             : inout std_logic;
            mcb3_rzq                     : inout std_logic;
            mcb3_zio                     : inout std_logic;
            mcb3_dram_udm                : out std_logic;
            c3_sys_clk                   : in std_logic;
            c3_sys_rst_i                 : in std_logic;
            c3_calib_done                : out std_logic;
            c3_clk0                      : out std_logic;
            c3_rst0                      : out std_logic;
            mcb3_dram_dqs                : inout std_logic;
            mcb3_dram_dqs_n              : inout std_logic;
            mcb3_dram_ck                 : out std_logic;
            mcb3_dram_ck_n               : out std_logic;
            c3_p0_cmd_clk                : in std_logic;
            c3_p0_cmd_en                 : in std_logic;
            c3_p0_cmd_instr              : in std_logic_vector(2 downto 0);
            c3_p0_cmd_bl                 : in std_logic_vector(5 downto 0);
            c3_p0_cmd_byte_addr          : in std_logic_vector(29 downto 0);
            c3_p0_cmd_empty              : out std_logic;
            c3_p0_cmd_full               : out std_logic;
            c3_p0_wr_clk                 : in std_logic;
            c3_p0_wr_en                  : in std_logic;
            c3_p0_wr_mask                : in std_logic_vector(C3_P0_MASK_SIZE - 1 downto 0);
            c3_p0_wr_data                : in std_logic_vector(C3_P0_DATA_PORT_SIZE - 1 downto 0);
            c3_p0_wr_full                : out std_logic;
            c3_p0_wr_empty               : out std_logic;
            c3_p0_wr_count               : out std_logic_vector(6 downto 0);
            c3_p0_wr_underrun            : out std_logic;
            c3_p0_wr_error               : out std_logic;
            c3_p0_rd_clk                 : in std_logic;
            c3_p0_rd_en                  : in std_logic;
            c3_p0_rd_data                : out std_logic_vector(C3_P0_DATA_PORT_SIZE - 1 downto 0);
            c3_p0_rd_full                : out std_logic;
            c3_p0_rd_empty               : out std_logic;
            c3_p0_rd_count               : out std_logic_vector(6 downto 0);
            c3_p0_rd_overflow            : out std_logic;
            c3_p0_rd_error               : out std_logic
        );
    end component;

    COMPONENT tft
        generic (
            SIMULATION                  : string
        );
        port (
            clk_100                     : in std_logic;
            init_done                   : in std_logic;
            ctrl_en                     : in std_logic;
            tft_clk                     : out std_logic;
            tft_de                      : out std_logic;
            tft_vidden                  : out std_logic;
            tft_disp                    : out std_logic;
            tft_bklt                    : out std_logic;
            tft_r                       : out std_logic_vector(7 downto 0);
            tft_g                       : out std_logic_vector(7 downto 0);
            tft_b                       : out std_logic_vector(7 downto 0);
            --rd cmd channel to ddr
            rd_cmd_m_tvalid             : out std_logic;
            rd_cmd_m_tready             : in std_logic;
            rd_cmd_m_tlast              : out std_logic;
            rd_cmd_m_taddr              : out std_logic_vector(25 downto 0);
            -- rd data channel from ddr
            rd_data_s_tvalid            : in std_logic;
            rd_data_s_tready            : out std_logic;
            rd_data_s_tdata             : in std_logic_vector(127 downto 0)
        );
    END COMPONENT;

    component vid_mem_gen is
        port (
            clk                         : in std_logic;
            resetn                      : in std_logic;

            event_s_tvalid              : in std_logic;

            wr_m_tvalid                 : out std_logic;
            wr_m_tready                 : in std_logic;
            wr_m_tlast                  : out std_logic;
            wr_m_tdata                  : out std_logic_vector(127 downto 0);
            wr_m_taddr                  : out std_logic_vector(25 downto 0)
        );
    end component;

    component ddr2_interconnect is
        port (
            clk                         : in std_logic;
            resetn                      : in std_logic;
            --rd channel
            rd_s_tvalid                 : in std_logic;
            rd_s_tready                 : out std_logic;
            rd_s_tlast                  : in std_logic;
            rd_s_taddr                  : in std_logic_vector(25 downto 0);
            --wr channel
            wr_s_tvalid                 : in std_logic;
            wr_s_tready                 : out std_logic;
            wr_s_tlast                  : in std_logic;
            wr_s_tdata                  : in std_logic_vector(127 downto 0);
            wr_s_taddr                  : in std_logic_vector(25 downto 0);
            --read back channel
            rd_m_tvalid                 : out std_logic;
            rd_m_tready                 : in std_logic;
            rd_m_tdata                  : out std_logic_vector(127 downto 0);
            --DDR interface
            cmd_en                      : out std_logic;
            cmd_instr                   : out std_logic_vector(2 downto 0);
            cmd_bl                      : out std_logic_vector(5 downto 0);
            cmd_byte_addr               : out std_logic_vector(29 downto 0);
            cmd_empty                   : in std_logic;
            cmd_full                    : in std_logic;
            -- WR interface
            wr_en                       : out std_logic;
            wr_mask                     : out std_logic_vector(16 - 1 downto 0);
            wr_data                     : out std_logic_vector(128 - 1 downto 0);
            wr_full                     : in std_logic;
            wr_empty                    : in std_logic;
            wr_count                    : in std_logic_vector(6 downto 0);
            wr_underrun                 : in std_logic;
            wr_error                    : in std_logic;
            -- RD interface
            rd_en                       : out std_logic;
            rd_data                     : in std_logic_vector(128 - 1 downto 0);
            rd_full                     : in std_logic;
            rd_empty                    : in std_logic;
            rd_count                    : in std_logic_vector(6 downto 0);
            rd_overflow                 : in std_logic;
            rd_error                    : in std_logic
        );

    end component;

    component uart_tx is
        port (
            clk                         : in std_logic;
            resetn                      : in std_logic;
            tx_s_tvalid                 : in std_logic;
            tx_s_tdata                  : in std_logic_vector(7 downto 0);
            tx                          : out std_logic
        );
    end component;

    component uart_rx is
        port (
            clk                         : in std_logic;
            resetn                      : in std_logic;
            rx                          : in std_logic;
            rx_m_tvalid                 : out std_logic;
            rx_m_tdata                  : out std_logic_vector(7 downto 0)
        );
    end component;

    component timer is
        port (
            clk_100                     : in std_logic;

            cmd_s_tvalid                : in std_logic;
            cmd_s_tdata                 : in std_logic_vector(15 downto 0);
            cmd_s_tuser                 : in std_logic;

            pulse1ms_m_tvalid           : out std_logic;
            pulse_m_tvalid              : out std_logic
        );
    end component;

    component debouncer is
        port (
            clk                         : in std_logic;
            resetn                      : in std_logic;

            pulse1ms_s_tvalid           : in std_logic;
            data_s_tvalid               : in std_logic;
            data_m_tvalid               : out std_logic;
            posedge_m_tvalid            : out std_logic;
            negedge_m_tvalid            : out std_logic
        );
    end component;

    component seven_seg_ctrl is
        port (
            clk                         : in std_logic;
            resetn                      : in std_logic;

            seg                         : out std_logic_vector(7 downto 0);
            an                          : out std_logic_vector(5 downto 0)
        );
    end component;

    --Local signals
    signal sys_clk_ibufg                : std_logic;
    signal board_reset_delay_cnt        : integer range 0 to 7;
    signal board_reset_n                : std_logic := '0';
    -- Memory UI signals
    signal mem_calib_done               : std_logic;
    signal mem_clk                      : std_logic;
    signal mem_rst                      : std_logic;
    signal mem_cmd_clk                  : std_logic;
    signal mem_cmd_en                   : std_logic;
    signal mem_cmd_instr                : std_logic_vector(2 downto 0);
    signal mem_cmd_bl                   : std_logic_vector(5 downto 0);
    signal mem_cmd_byte_addr            : std_logic_vector(29 downto 0);
    signal mem_cmd_empty                : std_logic;
    signal mem_cmd_full                 : std_logic;
    signal mem_wr_clk                   : std_logic;
    signal mem_wr_en                    : std_logic;
    signal mem_wr_mask                  : std_logic_vector(C3_P0_MASK_SIZE - 1 downto 0);
    signal mem_wr_data                  : std_logic_vector(C3_P0_DATA_PORT_SIZE - 1 downto 0);
    signal mem_wr_full                  : std_logic;
    signal mem_wr_empty                 : std_logic;
    signal mem_wr_count                 : std_logic_vector(6 downto 0);
    signal mem_wr_underrun              : std_logic;
    signal mem_wr_error                 : std_logic;
    signal mem_rd_clk                   : std_logic;
    signal mem_rd_en                    : std_logic;
    signal mem_rd_data                  : std_logic_vector(C3_P0_DATA_PORT_SIZE - 1 downto 0);
    signal mem_rd_full                  : std_logic;
    signal mem_rd_empty                 : std_logic;
    signal mem_rd_count                 : std_logic_vector(6 downto 0);
    signal mem_rd_overflow              : std_logic;
    signal mem_rd_error                 : std_logic;

    signal uart_rx_buf                  : std_logic_vector(2 downto 0);

    signal vid_gen_wr_tvalid            : std_logic;
    signal vid_gen_wr_tready            : std_logic;
    signal vid_gen_wr_tlast             : std_logic;
    signal vid_gen_wr_tdata             : std_logic_vector(127 downto 0);
    signal vid_gen_wr_taddr             : std_logic_vector(25 downto 0);

    signal tft_rd_cmd_tvalid            : std_logic;
    signal tft_rd_cmd_tready            : std_logic;
    signal tft_rd_cmd_tlast             : std_logic;
    signal tft_rd_cmd_taddr             : std_logic_vector(25 downto 0);

    signal tft_rd_data_tvalid           : std_logic;
    signal tft_rd_data_tready           : std_logic;
    signal tft_rd_data_tdata            : std_logic_vector(127 downto 0);

    signal sw_buf                       : std_logic_vector(7 downto 0);

    signal uart_tvalid                  : std_logic;
    signal uart_tdata                   : std_logic_vector(7 downto 0);

    signal pulse_tvalid                 : std_logic;
    signal pulse1ms_tvalid              : std_logic;

    signal btn_0_push_up_tvalid         : std_logic;
    signal toggler_fl                   : std_logic;

begin

    u_ibufg_sys_clk : IBUFG port map (
        I  => CLK,
        O  => sys_clk_ibufg
    );

    -- Instantiate DDR2
    ddr2_inst: ddr2 generic map (
        C3_SIMULATION        => SIMULATION
    ) port map (
        c3_sys_clk           => sys_clk_ibufg,
        c3_sys_rst_i         => board_reset_n,
        mcb3_dram_dq         => DDR_DATA,
        mcb3_dram_a          => DDR_ADDR,
        mcb3_dram_ba         => DDR_BA,
        mcb3_dram_ras_n      => DDR_RAS_N,
        mcb3_dram_cas_n      => DDR_CAS_N,
        mcb3_dram_we_n       => DDR_WE_N,
        mcb3_dram_odt        => DDR_ODT,
        mcb3_dram_ck         => DDR_CLK_P,
        mcb3_dram_ck_n       => DDR_CLK_N,
        mcb3_dram_cke        => DDR_CLK_EN,
        mcb3_dram_dm         => DDR_LDM,
        mcb3_dram_udm        => DDR_UDM,
        mcb3_dram_dqs        => DDR_LDQS_P,
        mcb3_dram_dqs_n      => DDR_LDQS_N,
        mcb3_dram_udqs       => DDR_UDQS_P,
        mcb3_dram_udqs_n     => DDR_UDQS_N,
        mcb3_rzq             => RZQ,
        mcb3_zio             => ZIO,

        c3_calib_done        => mem_calib_done,
        c3_clk0              => mem_clk,
        c3_rst0              => mem_rst,
        c3_p0_cmd_clk        => mem_clk,
        c3_p0_cmd_en         => mem_cmd_en,
        c3_p0_cmd_instr      => mem_cmd_instr,
        c3_p0_cmd_bl         => mem_cmd_bl,
        c3_p0_cmd_byte_addr  => mem_cmd_byte_addr,
        c3_p0_cmd_empty      => mem_cmd_empty,
        c3_p0_cmd_full       => mem_cmd_full,
        c3_p0_wr_clk         => mem_clk,
        c3_p0_wr_en          => mem_wr_en,
        c3_p0_wr_mask        => mem_wr_mask,
        c3_p0_wr_data        => mem_wr_data,
        c3_p0_wr_full        => mem_wr_full,
        c3_p0_wr_empty       => mem_wr_empty,
        c3_p0_wr_count       => mem_wr_count,
        c3_p0_wr_underrun    => mem_wr_underrun,
        c3_p0_wr_error       => mem_wr_error,
        c3_p0_rd_clk         => mem_clk,
        c3_p0_rd_en          => mem_rd_en,
        c3_p0_rd_data        => mem_rd_data,
        c3_p0_rd_full        => mem_rd_full,
        c3_p0_rd_empty       => mem_rd_empty,
        c3_p0_rd_count       => mem_rd_count,
        c3_p0_rd_overflow    => mem_rd_overflow,
        c3_p0_rd_error       => mem_rd_error
    );

    tft_inst: tft generic map (
        SIMULATION          => SIMULATION
    ) port map(
        clk_100             => mem_clk,
		init_done           => mem_calib_done,
		ctrl_en             => '1',
		tft_clk             => TFT_CLK_O,
		tft_de              => TFT_DE_O,
		tft_vidden          => TFT_VDDEN_O,
		tft_disp            => TFT_DISP_O,
		tft_bklt            => TFT_BKLT_O,
		tft_r               => TFT_R_O,
		tft_g               => TFT_G_O,
		tft_b               => TFT_B_O,
        rd_cmd_m_tvalid     => tft_rd_cmd_tvalid,
        rd_cmd_m_tready     => tft_rd_cmd_tready,
        rd_cmd_m_tlast      => tft_rd_cmd_tlast,
        rd_cmd_m_taddr      => tft_rd_cmd_taddr,

        rd_data_s_tvalid    => tft_rd_data_tvalid,
        rd_data_s_tready    => tft_rd_data_tready,
        rd_data_s_tdata     => tft_rd_data_tdata

    );

    vid_mem_gen_inst : vid_mem_gen port map (
        clk                 => mem_clk,
        resetn              => mem_calib_done,

        event_s_tvalid      => btn_0_push_up_tvalid,

        wr_m_tvalid         => vid_gen_wr_tvalid,
        wr_m_tready         => vid_gen_wr_tready,
        wr_m_tlast          => vid_gen_wr_tlast,
        wr_m_tdata          => vid_gen_wr_tdata,
        wr_m_taddr          => vid_gen_wr_taddr
    );

    ddr2_interconnect_inst: ddr2_interconnect port map (
        clk                 => mem_clk,
        resetn              => mem_calib_done,

        rd_s_tvalid         => tft_rd_cmd_tvalid,
        rd_s_tready         => tft_rd_cmd_tready,
        rd_s_tlast          => tft_rd_cmd_tlast,
        rd_s_taddr          => tft_rd_cmd_taddr,

        wr_s_tvalid         => vid_gen_wr_tvalid,
        wr_s_tready         => vid_gen_wr_tready,
        wr_s_tlast          => vid_gen_wr_tlast,
        wr_s_tdata          => vid_gen_wr_tdata,
        wr_s_taddr          => vid_gen_wr_taddr,

        rd_m_tvalid         => tft_rd_data_tvalid,
        rd_m_tready         => tft_rd_data_tready,
        rd_m_tdata          => tft_rd_data_tdata,

        cmd_en              => mem_cmd_en,
        cmd_instr           => mem_cmd_instr,
        cmd_bl              => mem_cmd_bl,
        cmd_byte_addr       => mem_cmd_byte_addr,
        cmd_empty           => mem_cmd_empty,
        cmd_full            => mem_cmd_full,

        wr_en               => mem_wr_en,
        wr_mask             => mem_wr_mask,
        wr_data             => mem_wr_data,
        wr_full             => mem_wr_full,
        wr_empty            => mem_wr_empty,
        wr_count            => mem_wr_count,
        wr_underrun         => mem_wr_underrun,
        wr_error            => mem_wr_error,

        rd_en               => mem_rd_en,
        rd_data             => mem_rd_data,
        rd_full             => mem_rd_full,
        rd_empty            => mem_rd_empty,
        rd_count            => mem_rd_count,
        rd_overflow         => mem_rd_overflow,
        rd_error            => mem_rd_error
    );

    uart_rx_inst : uart_rx port map (
        clk                 => mem_clk,
        resetn              => mem_calib_done,

        rx                  => uart_rx_buf(2),
        rx_m_tvalid         => uart_tvalid,
        rx_m_tdata          => uart_tdata
    );

    uart_tx_inst : uart_tx port map (
        clk                 => mem_clk,
        resetn              => mem_calib_done,

        tx_s_tvalid         => uart_tvalid,
        tx_s_tdata          => uart_tdata,
        tx                  => RS232_UART_TX
    );

    timer_inst : timer port map (
        clk_100             => mem_clk,

        cmd_s_tvalid        => btn_0_push_up_tvalid,
        cmd_s_tdata         => x"1388", --5 secs
        cmd_s_tuser         => '0',

        pulse1ms_m_tvalid   => pulse1ms_tvalid,
        pulse_m_tvalid      => pulse_tvalid
    );

    debouncer_btn_0_inst : debouncer port map (
        clk                 => mem_clk,
        resetn              => mem_calib_done,

        pulse1ms_s_tvalid   => pulse1ms_tvalid,
        data_s_tvalid       => BTN(0),

        data_m_tvalid       => LED(4),
        posedge_m_tvalid    => open,
        negedge_m_tvalid    => btn_0_push_up_tvalid
    );

    debouncer_btn_1_inst : debouncer port map (
        clk                 => mem_clk,
        resetn              => mem_calib_done,

        pulse1ms_s_tvalid   => pulse1ms_tvalid,
        data_s_tvalid       => BTN(1),

        data_m_tvalid       => LED(5),
        posedge_m_tvalid    => open,
        negedge_m_tvalid    => open
    );

    seven_seg_ctrl_inst : seven_seg_ctrl port map (
        clk                 => mem_clk,
        resetn              => mem_calib_done,

        seg                 => SEG,
        an                  => AN
    );

    internal_reset: process (sys_clk_ibufg) begin
        if (rising_edge(sys_clk_ibufg)) then
            if (board_reset_delay_cnt = 7) then
                board_reset_n <= '1';
            end if;

            if (board_reset_delay_cnt /= 7) then
                board_reset_delay_cnt <= board_reset_delay_cnt + 1;
            end if;
        end if;
	end process;

    timer_configuration_process: process (mem_clk) begin
        if rising_edge(mem_clk) then
            if (mem_rst = '1') then
                toggler_fl <= '0';
            else

                if (pulse_tvalid = '1') then
                    toggler_fl <= not toggler_fl;
                end if;

            end if;
        end if;
    end process;

    read_rom: process (mem_clk) begin
        if (rising_edge(mem_clk)) then
            LED(3 downto 2) <= "00";
            LED(7 downto 6) <= "00";
            LED(1) <= toggler_fl;
        end if;
    end process;

    leds_monitor: process(mem_clk) begin
        if (rising_edge(mem_clk)) then
            if (mem_rst = '1') then
                LED(0) <= '0';
            else
                LED(0) <= mem_calib_done;
            end if;

            sw_buf <= SW;

            -- if (std_match(sw_buf(7 downto 0), "1111----")) then
            --     LED(7 downto 1) <= (others => '1');
            -- else
            --     LED(7 downto 1) <= (others => '0');
            -- end if;
        end if;
    end process;

    uart_rx_buf_process: process (mem_clk)  begin
        uart_rx_buf <= uart_rx_buf(1 downto 0) & RS232_UART_RX;
    end process;

    --RS232_UART_TX <= uart_rx_buf(2);

end Behavioral;
