library ieee;
library unisim;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

entity calc_ctrl_tb is
end entity calc_ctrl_tb;

architecture rtl of calc_ctrl_tb is

    -- Clock period definitions
    constant CLK_PERIOD                 : time := 10 ns;

    component calc_ctrl is
        port (
            clk                         : in std_logic;
            resetn                      : in std_logic;

            key_pad_s_tvalid            : in std_logic;
            key_pad_s_tdata             : in std_logic_vector(3 downto 0);

            key_btn0_s_tvalid           : in std_logic;
            key_btn1_s_tvalid           : in std_logic;
            key_btn2_s_tvalid           : in std_logic;
            key_btn3_s_tvalid           : in std_logic;

            touch_s_tvalid              : in std_logic;
            touch_s_tdata               : in std_logic_vector(7 downto 0);

            tft_upd_s_tvalid            : in std_logic;

            sseg_m_tvalid               : out std_logic;
            sseg_m_taddr                : out std_logic_vector(2 downto 0);
            sseg_m_tdata                : out std_logic_vector(3 downto 0);
            sseg_m_tuser                : out std_logic_vector(3 downto 0);

            tft_m_tvalid                : out std_logic;
            tft_m_tready                : in std_logic;
            tft_m_tlast                 : out std_logic;
            tft_m_tdata                 : out std_logic_vector(55 downto 0);
            tft_m_tuser                 : out std_logic_vector(6 downto 0);

            led_m_tdata                 : out std_logic_vector(3 downto 0)
        );
    end component;

    signal CLK                          : std_logic := '0';
    signal RESETN                       : std_logic := '0';

    signal key_pad_s_tvalid             : std_logic := '0';
    signal key_pad_s_tdata              : std_logic_vector(3 downto 0);
    signal key_btn0_s_tvalid            : std_logic := '0';
    signal key_btn1_s_tvalid            : std_logic := '0';
    signal key_btn2_s_tvalid            : std_logic := '0';
    signal key_btn3_s_tvalid            : std_logic := '0';
    signal sseg_m_tvalid                : std_logic := '0';
    signal sseg_m_taddr                 : std_logic_vector(2 downto 0);
    signal sseg_m_tdata                 : std_logic_vector(3 downto 0);
    signal sseg_m_tuser                 : std_logic_vector(3 downto 0);
    signal tft_upd_s_tvalid             : std_logic := '0';
    signal tft_m_tvalid                 : std_logic := '0';
    signal tft_m_tready                 : std_logic := '1';
    signal tft_m_tlast                  : std_logic;
    signal tft_m_tdata                  : std_logic_vector(55 downto 0);
    signal tft_m_tuser                  : std_logic_vector(6 downto 0);
    signal led_m_tdata                  : std_logic_vector(3 downto 0);

    signal touch_s_tvalid               : std_logic := '0';
    signal touch_s_tdata                : std_logic_vector(7 downto 0);


begin

    uut: calc_ctrl port map (
        clk                 => CLK,
        resetn              => RESETN,

        key_pad_s_tvalid    => key_pad_s_tvalid,
        key_pad_s_tdata     => key_pad_s_tdata,

        key_btn0_s_tvalid   => key_btn0_s_tvalid,
        key_btn1_s_tvalid   => key_btn1_s_tvalid,
        key_btn2_s_tvalid   => key_btn2_s_tvalid,
        key_btn3_s_tvalid   => key_btn3_s_tvalid,

        touch_s_tvalid      => touch_s_tvalid,
        touch_s_tdata       => touch_s_tdata,

        tft_upd_s_tvalid    => tft_upd_s_tvalid,

        tft_m_tvalid        => tft_m_tvalid,
        tft_m_tready        => tft_m_tready,
        tft_m_tlast         => tft_m_tlast,
        tft_m_tdata         => tft_m_tdata,
        tft_m_tuser         => tft_m_tuser,

        sseg_m_tvalid       => sseg_m_tvalid,
        sseg_m_taddr        => sseg_m_taddr,
        sseg_m_tdata        => sseg_m_tdata,
        sseg_m_tuser        => sseg_m_tuser,

        led_m_tdata         => led_m_tdata
    );

    -- Clock process
    clk_process : process begin
    	CLK <= '0';
    	wait for CLK_PERIOD/2;
    	CLK <= '1';
    	wait for CLK_PERIOD/2;
    end process;

    -- Reset process
    reset_process : process begin
        RESETN <= '0';
        wait for 200 ns;
        RESETN <= '1';
        wait;
    end process;

    -- Stimuli
    stimuli: process begin

        key_btn0_s_tvalid <= '0';
        wait for 300 ns;

        key_btn0_s_tvalid <= '1';
        wait for CLK_PERIOD;

        key_btn0_s_tvalid <= '0';
        wait for CLK_PERIOD;

        key_btn0_s_tvalid <= '1';
        wait for CLK_PERIOD;

        key_btn0_s_tvalid <= '0';

        for i in 0 to 12 loop
            wait for 40*CLK_PERIOD;

            key_pad_s_tvalid <= '1';
            key_pad_s_tdata <= x"1";
            wait for CLK_PERIOD;
            key_pad_s_tvalid <= '0';
        end loop;

        wait;

    end process;

    tft_ready : process begin
        tft_m_tready <= '1';
        wait until tft_m_tvalid = '1' and tft_m_tready = '1' and tft_m_tlast = '1';
        wait for CLK_PERIOD;

        tft_m_tready <= '0';
        wait for 100 ns;

        tft_m_tready <= '1';
        wait for CLK_PERIOD;

        tft_m_tready <= '0';
    end process;

    -- TFT UPD Call Back
    tft_upd : process begin
        tft_upd_s_tvalid <= '0';
        wait until tft_m_tvalid = '1' and tft_m_tready = '1' and tft_m_tlast = '1';
        wait for 2*CLK_PERIOD;

        wait until tft_m_tready = '1';
        wait for CLK_PERIOD;

        tft_upd_s_tvalid <= '1';
        wait for CLK_PERIOD;

        tft_upd_s_tvalid <= '0';
    end process;

end architecture;
