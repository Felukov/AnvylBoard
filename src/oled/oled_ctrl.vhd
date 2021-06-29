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
        CLK             : in std_logic;
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
            CLK         : in std_logic;
            resetn      : in std_logic;
            EN          : in std_logic;
            CS          : out std_logic;
            SDO         : out std_logic;
            SCLK        : out std_logic;
            DC          : out std_logic;
            RES         : out std_logic;
            VBAT        : out std_logic;
            VDD         : out std_logic;
            FIN         : out std_logic
        );
    end component;

    component oled_data_ctrl is
        Port (
            CLK         : in std_logic;
            resetn      : in std_logic;
            EN          : in std_logic;
            CS          : out std_logic;
            SDO         : out std_logic;
            SCLK        : out std_logic;
            DC          : out std_logic;
            FIN         : out std_logic
        );
    end component;

    type states is (Idle, OledInitialize, OledExample, Done);

    signal current_state     : states := Idle;

    signal init_en      : std_logic := '0';
    signal init_done    : std_logic;
    signal init_cs      : std_logic;
    signal init_sdo     : std_logic;
    signal init_sclk    : std_logic;
    signal init_dc      : std_logic;

    signal example_en   : std_logic := '0';
    signal example_cs   : std_logic;
    signal example_sdo  : std_logic;
    signal example_sclk : std_logic;
    signal example_dc   : std_logic;
    signal example_done : std_logic;

    signal CS : std_logic;

begin

    oled_init_ctrl_inst: oled_init_ctrl port map(clk, resetn, init_en, init_cs, init_sdo, init_sclk, init_dc, RES, VBAT, VDD, init_done);
    oled_data_ctrl_inst: oled_data_ctrl port map(clk, resetn, example_en, example_cs, example_sdo, example_sclk, example_dc, example_done);

    --MUXes to indicate which outputs are routed out depending on which block is enabled
    CS <= init_cs when (current_state = OledInitialize) else
            example_cs;
    SDIN <= init_sdo when (current_state = OledInitialize) else
            example_sdo;
    SCLK <= init_sclk when (current_state = OledInitialize) else
            example_sclk;
    DC <= init_dc when (current_state = OledInitialize) else
            example_dc;
    --END output MUXes

    --MUXes that enable blocks when in the proper states
    init_en <= '1' when (current_state = OledInitialize) else
                    '0';
    example_en <= '1' when (current_state = OledExample) else
                    '0';
    --END enable MUXes

    process (clk) begin
        if(rising_edge(clk)) then
            if(resetn = '0') then
                current_state <= Idle;
            else
                case(current_state) is
                    when Idle =>
                        current_state <= OledInitialize;
                    --Go through the initialization sequence
                    when OledInitialize =>
                        if(init_done = '1') then
                            current_state <= OledExample;
                        end if;
                    --Do example and Do nothing when finished
                    when OledExample =>
                        if(example_done = '1') then
                            current_state <= Done;
                        end if;
                    --Do Nothing
                    when Done =>
                        current_state <= Done;
                    when others =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process;


end rtl;

