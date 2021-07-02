----------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Ryan Kim
--
-- Create Date:    14:35:33 10/10/2011
-- Module Name:    oled_ctrl - rtl
-- Project Name:   PmodOLED Demo
-- Tool versions:  ISE 13.2
-- Description:    Top level controller that controls the PmodOLED blocks
--
-- Revision: 1.1
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity oled_ctrl is
    port (
        clk             : in std_logic;
        resetn          : in std_logic;
        SDIN            : out std_logic;
        SCLK            : out std_logic;
        DC              : out std_logic;
        RES             : out std_logic;
        VBAT            : out std_logic;
        VDD             : out std_logic
    );
end oled_ctrl;

architecture rtl of oled_ctrl is

    component oled_init_ctrl is
        Port (
            clk         : in std_logic;
            resetn      : in std_logic;
            en          : in std_logic;
            fin         : out std_logic;
            CS          : out std_logic;
            SDO         : out std_logic;
            SCLK        : out std_logic;
            DC          : out std_logic;
            RES         : out std_logic;
            VBAT        : out std_logic;
            VDD         : out std_logic
        );
    end component;

    component oled_data_ctrl is
        Port (
            clk         : in std_logic;
            resetn      : in std_logic;
            en          : in std_logic;
            fin         : out std_logic;
            CS          : out std_logic;
            SDO         : out std_logic;
            SCLK        : out std_logic;
            DC          : out std_logic
        );
    end component;

    type state_t is (Idle, OledInitialize, OledExample, Done);

    signal state        : state_t := Idle;

    signal init_en      : std_logic := '0';
    signal init_done    : std_logic;
    signal init_sdo     : std_logic;
    signal init_sclk    : std_logic;
    signal init_dc      : std_logic;

    signal data_en      : std_logic := '0';
    signal data_sdo     : std_logic;
    signal data_sclk    : std_logic;
    signal data_dc      : std_logic;
    signal data_done    : std_logic;


begin

    oled_init_ctrl_inst: oled_init_ctrl port map(
        clk             => clk,
        resetn          => resetn,

        en              => init_en,
        fin             => init_done,

        CS              => open,
        SDO             => init_sdo,
        SCLK            => init_sclk,
        DC              => init_dc,

        RES             => RES,
        VBAT            => VBAT,
        VDD             => VDD
    );

    oled_data_ctrl_inst: oled_data_ctrl port map(
        clk             => clk,
        resetn          => resetn,

        en              => data_en,
        fin             => data_done,

        CS              => open,
        SDO             => data_sdo,
        SCLK            => data_sclk,
        DC              => data_dc
    );

    --MUXes that enable blocks when in the proper state_t
    init_en <= '1' when (state = OledInitialize) else '0';
    data_en <= '1' when (state = OledExample) else '0';
    --END enable MUXes

    process (clk) begin
        if rising_edge(clk) then
            if (state = OledInitialize) then
                SDIN <= init_sdo;
                SCLK <= init_sclk;
                DC <= init_dc;
            else
                SDIN <= data_sdo;
                SCLK <= data_sclk;
                DC <= data_dc;
            end if;
        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if (resetn = '0') then
                state <= Idle;
            else
                case (state) is
                    when Idle =>
                        state <= OledInitialize;
                    --Go through the initialization sequence
                    when OledInitialize =>
                        if (init_done = '1') then
                            state <= OledExample;
                        end if;
                    --Do example and Do nothing when finished
                    when OledExample =>
                        if(data_done = '1') then
                            state <= Done;
                        end if;
                    --Do Nothing
                    when Done =>
                        state <= Done;
                    when others =>
                        state <= Idle;
                end case;
            end if;
        end if;
    end process;


end rtl;

