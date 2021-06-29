library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity oled_ctrl_tb is
end entity oled_ctrl_tb;

architecture rtl of oled_ctrl_tb is
    constant CLK_PERIOD         : time := 10 ns;

    signal clk                  : std_logic;
    signal resetn               : std_logic;

    component oled_ctrl is
        Port (
            CLK             : in std_logic;
            resetn          : in std_logic;
    --        CS            : out std_logic;
            SDIN            : out std_logic;
            SCLK            : out std_logic;
            DC              : out std_logic;
            RES             : out std_logic;
            VBAT            : out std_logic;
            VDD             : out std_logic
        );
    end component;

    signal SDIN              : std_logic;
    signal SCLK              : std_logic;
    signal DC                : std_logic;
    signal RES               : std_logic;
    signal VBAT              : std_logic;
    signal VDD               : std_logic;

begin

    uut: oled_ctrl port map (
        clk         => clk,
        resetn      => resetn,
        SDIN        => SDIN,
        SCLK        => SCLK,
        DC          => DC,
        RES         => RES,
        VBAT        => VBAT,
        VDD         => VDD
    );

    -- continuous clock
    process begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    resetn <= '0', '1' after 10*CLK_PERIOD;

    -- stimuli


end architecture;
