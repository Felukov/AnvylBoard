--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   20:32:44 03/31/2021
-- Design Name:
-- Module Name:   T:/Projects/AnvylBoard/top_tb.vhd
-- Project Name:  AnvylBoard
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: top
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes:
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation
-- simulation model.
--------------------------------------------------------------------------------
library ieee;
library unisim;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

ENTITY top_tb IS
END top_tb;

ARCHITECTURE behavior OF top_tb IS
    -- Constants
    constant C3_MEMCLK_PERIOD           : integer := 5000;
    constant C3_RST_ACT_LOW             : integer := 0;
    constant C3_INPUT_CLK_TYPE          : string := "SINGLE_ENDED";
    constant C3_CLK_PERIOD_NS           : real := 5000.0 / 1000.0;
    constant C3_TCYC_SYS                : real := C3_CLK_PERIOD_NS/2.0;
    constant C3_TCYC_SYS_DIV2           : time := C3_TCYC_SYS * 1 ns;
    constant C3_NUM_DQ_PINS             : integer := 16;
    constant C3_MEM_ADDR_WIDTH          : integer := 13;
    constant C3_MEM_BANKADDR_WIDTH      : integer := 3;
    constant C3_MEM_ADDR_ORDER          : string := "ROW_BANK_COLUMN";
    constant C3_P0_MASK_SIZE            : integer := 16;
    constant C3_P0_DATA_PORT_SIZE       : integer := 128;
    constant C3_P1_MASK_SIZE            : integer := 16;
    constant C3_P1_DATA_PORT_SIZE       : integer := 128;
    constant C3_CALIB_SOFT_IP           : string := "TRUE";
    constant C3_SIMULATION              : string := "TRUE";

    -- Clock period definitions
    constant CLK_period                 : time := 10 ns;

    -- Component Declaration for the Unit Under Test (UUT)
    component top
        generic (
            SIMULATION              : string
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
            LED                     : out std_logic_vector(7 downto 0);
            SW                      : in std_logic_vector(7 downto 0);
            BTN                     : in std_logic_vector(3 downto 0);
            SEG                     : out std_logic_vector(7 downto 0);
            AN                      : out std_logic_vector(5 downto 0);
            KYPD_COL                : out std_logic_vector(3 downto 0);
            KYPD_ROW                : in std_logic_vector(3 downto 0);
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
    end component;

    -- DDR companion
    component ddr2_model_c3 is
        port (
            ck                      : in    std_logic;
            ck_n                    : in    std_logic;
            cke                     : in    std_logic;
            cs_n                    : in    std_logic;
            ras_n                   : in    std_logic;
            cas_n                   : in    std_logic;
            we_n                    : in    std_logic;
            dm_rdqs                 : inout std_logic_vector((C3_NUM_DQ_PINS/16) downto 0);
            ba                      : in    std_logic_vector((C3_MEM_BANKADDR_WIDTH-1) downto 0);
            addr                    : in    std_logic_vector((C3_MEM_ADDR_WIDTH-1) downto 0);
            dq                      : inout std_logic_vector((C3_NUM_DQ_PINS-1) downto 0);
            dqs                     : inout std_logic_vector((C3_NUM_DQ_PINS/16) downto 0);
            dqs_n                   : inout std_logic_vector((C3_NUM_DQ_PINS/16) downto 0);
            rdqs_n                  : out   std_logic_vector((C3_NUM_DQ_PINS/16) downto 0);
            odt                     : in    std_logic
          );
    end component;

    -- UART TX
    component uart_tx is
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;
            tx_s_tvalid             : in std_logic;
            tx_s_tdata              : in std_logic_vector(7 downto 0);
            tx                      : out std_logic
        );
    end component;

    -- Clock signal
    signal CLK                      : std_logic := '0';
    -- Testbench reset signal
    signal c3_sys_rst               : std_logic := '0';
    --DDR2 Signals
    signal mcb3_dram_a              : std_logic_vector(C3_MEM_ADDR_WIDTH-1 downto 0);
    signal mcb3_dram_ba             : std_logic_vector(C3_MEM_BANKADDR_WIDTH-1 downto 0);
    signal mcb3_dram_ck             : std_logic;
    signal mcb3_dram_ck_n           : std_logic;
    signal mcb3_dram_dq             : std_logic_vector(C3_NUM_DQ_PINS-1 downto 0);
    signal mcb3_dram_dqs            : std_logic;
    signal mcb3_dram_dqs_n          : std_logic;
    signal mcb3_dram_dm             : std_logic;
    signal mcb3_dram_ras_n          : std_logic;
    signal mcb3_dram_cas_n          : std_logic;
    signal mcb3_dram_we_n           : std_logic;
    signal mcb3_dram_cke            : std_logic;
    signal mcb3_dram_odt            : std_logic;
    signal mcb3_dram_udqs           : std_logic;
    signal mcb3_dram_udqs_n         : std_logic;
    signal mcb3_dram_dqs_vector     : std_logic_vector(1 downto 0);
    signal mcb3_dram_dqs_n_vector   : std_logic_vector(1 downto 0);
    signal mcb3_dram_udm            : std_logic;     -- for X16 parts
    signal mcb3_dram_dm_vector      : std_logic_vector(1 downto 0);
    signal mcb3_command             : std_logic_vector(2 downto 0);
    signal mcb3_enable1             : std_logic;
    signal mcb3_enable2             : std_logic;

    signal rzq3                     : std_logic;
    signal zio3                     : std_logic;

    signal calib_done               : std_logic;
    signal error                    : std_logic;

    signal uart_tvalid              : std_logic;
    signal uart_tdata               : std_logic_vector(7 downto 0);
    signal uart_rx_tx_in            : std_logic;
    signal uart_rx_tx_out           : std_logic;

BEGIN

    -- The PULLDOWN component is connected to the ZIO signal primarily to avoid the
    -- unknown state in simulation. In real hardware, ZIO should be a no connect(NC) pin.
    zio_pulldown3 : PULLDOWN port map(O => zio3);
    rzq_pulldown3 : PULLDOWN port map(O => rzq3);

	-- Instantiate the Unit Under Test (UUT)
    uut: top generic map (
        SIMULATION      => "TRUE"
    ) port map (
        CLK           => CLK,
        DDR_CLK_P     => mcb3_dram_ck,
        DDR_CLK_N     => mcb3_dram_ck_n,
        DDR_CLK_EN    => mcb3_dram_cke,
        DDR_ADDR      => mcb3_dram_a,
        DDR_BA        => mcb3_dram_ba,
        DDR_DATA      => mcb3_dram_dq,
        DDR_RAS_N     => mcb3_dram_ras_n,
        DDR_CAS_N     => mcb3_dram_cas_n,
        DDR_WE_N      => mcb3_dram_we_n,
        DDR_ODT       => mcb3_dram_odt,
        DDR_LDM       => mcb3_dram_dm,
        DDR_UDM       => mcb3_dram_udm,
        DDR_UDQS_P    => mcb3_dram_udqs,
        DDR_UDQS_N    => mcb3_dram_udqs_n,
        DDR_LDQS_P    => mcb3_dram_dqs,
        DDR_LDQS_N    => mcb3_dram_dqs_n,
        SW            => "00000000",
        RZQ           => rzq3,
        ZIO           => zio3,
        TFT_CLK_O     => open,
        TFT_VDDEN_O   => open,
        TFT_DE_O      => open,
        TFT_BKLT_O    => open,
        TFT_DISP_O    => open,
        TFT_R_O       => open,
        TFT_G_O       => open,
        TFT_B_O       => open,
        BTN           => "0000",
        SEG           => open,
        AN            => open,
        KYPD_COL      => open,
        KYPD_ROW      => "0000",
        RS232_UART_TX => uart_rx_tx_out,
        RS232_UART_RX => uart_rx_tx_in
    );

    -- Instantiate the DDR2 model
    ddr2_model_inst : ddr2_model_c3 port map (
        ck        => mcb3_dram_ck,
        ck_n      => mcb3_dram_ck_n,
        cke       => mcb3_dram_cke,
        cs_n      => '0',
        ras_n     => mcb3_dram_ras_n,
        cas_n     => mcb3_dram_cas_n,
        we_n      => mcb3_dram_we_n,
        dm_rdqs   => mcb3_dram_dm_vector,
        ba        => mcb3_dram_ba,
        addr      => mcb3_dram_a,
        dq        => mcb3_dram_dq,
        dqs       => mcb3_dram_dqs_vector,
        dqs_n     => mcb3_dram_dqs_n_vector,
        rdqs_n    => open,
        odt       => mcb3_dram_odt
    );

    uart_tx_inst : uart_tx port map (
        clk                 => CLK,
        resetn              => c3_sys_rst,
        tx_s_tvalid         => uart_tvalid,
        tx_s_tdata          => uart_tdata,
        tx                  => uart_rx_tx_in
    );

    -- Assigns
    -- ddr cmd
    mcb3_command <= (mcb3_dram_ras_n & mcb3_dram_cas_n & mcb3_dram_we_n);
    process (mcb3_dram_ck) begin
        if (rising_edge(mcb3_dram_ck)) then
            if (c3_sys_rst = '0') then
                mcb3_enable2 <= '0';
            elsif (mcb3_command = "100") then
                mcb3_enable2 <= '0';
            elsif (mcb3_command = "101") then
                mcb3_enable2 <= '1';
            else
                mcb3_enable2 <= mcb3_enable2;
            end if;

            if (c3_sys_rst = '0') then
                mcb3_enable1 <= '0';
            else
                mcb3_enable1 <= mcb3_enable2;
            end if;

        end if;
    end process;
    -- ddr read
    mcb3_dram_dqs_vector(1 downto 0) <= (mcb3_dram_udqs & mcb3_dram_dqs) when (mcb3_enable2 = '0' and mcb3_enable1 = '0') else "ZZ";
    mcb3_dram_dqs_n_vector(1 downto 0) <= (mcb3_dram_udqs_n & mcb3_dram_dqs_n) when (mcb3_enable2 = '0' and mcb3_enable1 = '0') else "ZZ";
    -- ddr write
    mcb3_dram_dqs <= mcb3_dram_dqs_vector(0) when ( mcb3_enable1 = '1') else 'Z';
    mcb3_dram_udqs <= mcb3_dram_dqs_vector(1) when (mcb3_enable1 = '1') else 'Z';
    mcb3_dram_dqs_n <= mcb3_dram_dqs_n_vector(0) when (mcb3_enable1 = '1') else 'Z';
    mcb3_dram_udqs_n <= mcb3_dram_dqs_n_vector(1) when (mcb3_enable1 = '1') else 'Z';
    -- ddr other signals
    mcb3_dram_dm_vector <= (mcb3_dram_udm & mcb3_dram_dm);

    -- Clock process definitions
    clk_process : process begin
    	CLK <= '0';
    	wait for CLK_period/2;
    	CLK <= '1';
    	wait for CLK_period/2;
    end process;

    -- Reset process
    reset_process : process begin
        c3_sys_rst <= '0';
        wait for 200 ns;
        c3_sys_rst <= '1';
        wait;
    end process;

   -- Stimulus process
   stim_proc: process
   begin
        -- hold reset state for 200 ns.
        wait for 30 us;

        -- insert stimulus here
        uart_tvalid <= '1';
        uart_tdata <= x"AB";

        wait for CLK_period;
        uart_tvalid <= '0';

      wait;
   end process;

END;
