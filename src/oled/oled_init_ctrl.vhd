----------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Ryan Kim
--
-- Create Date:    16:05:03 10/10/2011
-- Module Name:    oled_init_ctrl - rtl
-- Project Name:   PmodOLED Demo
-- Tool versions:  ISE 13.2
-- Description:    Runs the initialization sequence for the PmodOLED
--
-- Revision: 1.2
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity oled_init_ctrl is
    port (
        CLK         : in std_logic;     --System Clock
        resetn      : in std_logic;     --Global Synchronous Reset
        EN          : in std_logic;     --Block enable pin
        CS          : out std_logic;    --SPI Chip Select
        SDO         : out std_logic;    --SPI data out
        SCLK        : out std_logic;    --SPI Clock
        DC          : out std_logic;    --Data/Command Pin
        RES         : out std_logic;    --PmodOLED RES
        VBAT        : out std_logic;    --VBAT enable
        VDD         : out std_logic;    --VDD enable
        FIN         : out std_logic     --oled_init_ctrl Finish Flag
    );
end oled_init_ctrl;

architecture rtl of oled_init_ctrl is

    component oled_spi_ctrl
        port(
            clk        : in std_logic;
            resetn     : in std_logic;
            SPI_EN     : in std_logic;
            SPI_DATA   : in std_logic_vector(7 downto 0);
            CS         : out std_logic;
            SDO        : out std_logic;
            SCLK       : out std_logic;
            SPI_FIN    : out std_logic
            );
    end component;

    component oled_delay
        port(
            clk        : in std_logic;
            resetn     : in std_logic;
            delay_ms   : in std_logic_vector(11 downto 0);
            delay_en   : in std_logic;
            delay_fin  : out std_logic
        );
    end component;

    type state_t is (
        SendSPI,
        WaitSPI,
        SetDelay,
        WaitDelay,
        ClearAndBack,
        Idle,
        VddOn,
        VddOnWait,
        DispOff,
        ResetOn,
        ResetHold,
        ResetOff,
        ChargePump1,
        ChargePump2,
        PreCharge1,
        PreCharge2,
        VbatOn,
        VbatOnWait,
        DispContrast1,
        DispContrast2,
        InvertDisp1,
        InvertDisp2,
        ComConfig1,
        ComConfig2,
        DispOn,
        FullDisp,
        Done
    );

    signal current_state    : state_t;
    signal next_cmd         : state_t;

    signal temp_dc          : std_logic;
    signal temp_res         : std_logic;
    signal temp_vbat        : std_logic;
    signal temp_vdd         : std_logic;
    signal temp_fin         : std_logic;

    signal temp_delay_ms    : std_logic_vector (11 downto 0) := (others => '0');
    signal temp_delay_en    : std_logic := '0';
    signal temp_delay_fin   : std_logic;
    signal temp_spi_en      : std_logic := '0';
    signal temp_spi_data    : std_logic_vector (7 downto 0) := (others => '0');
    signal temp_spi_fin     : std_logic;

begin

    oled_spi_ctrl_inst: oled_spi_ctrl port map (
        CLK         => CLK,
        resetn      => resetn,
        spi_en      => temp_spi_en,
        spi_data    => temp_spi_data,
        spi_fin     => temp_spi_fin,
        CS          => CS,
        SDO         => SDO,
        SCLK        => SCLK
    );

   oled_delay_inst: oled_delay port map (
        clk         => clk,
        resetn      => resetn,
        delay_en    => temp_delay_en,
        delay_ms    => temp_delay_ms,
        delay_fin   => temp_delay_fin
    );

    DC <= temp_dc;
    RES <= temp_res;
    VBAT <= temp_vbat;
    VDD <= temp_vdd;
    FIN <= temp_fin;

    --Delay 100 ms after VbatOn
    temp_delay_ms <= "000001100100" when (next_cmd = DispContrast1) else --100 ms
                    "000000000001"; --1ms

    fsm_proc : process (CLK) begin
        if (rising_edge(CLK)) then
            if (resetn = '0') then
                current_state <= Idle;
                temp_res <= '0';
                temp_dc <= '0';
                temp_vbat <= '1';
                temp_vdd <= '1';
                temp_fin <= '0';
            else
                temp_res <= '1';
                case (current_state) is
                    when Idle =>
                        if (EN = '1') then
                            temp_dc <= '0';
                            current_state <= VddOn;
                        end if;

                    --Initialization Sequence
                    --This should be done everytime the PmodOLED is started
                    when VddOn =>
                        temp_vdd <= '0';
                        current_state <= VddOnWait;
                    when VddOnWait =>
                        next_cmd <= DispOff;
                        current_state <= SetDelay;
                    when DispOff =>
                        temp_spi_data <= "10101110"; --0xAE
                        next_cmd <= ResetOn;
                        current_state <= SendSPI;
                    when ResetOn =>
                        temp_res <= '0';
                        current_state <= ResetHold;
                    when ResetHold =>
                        next_cmd <= ResetOff;
                        current_state <= SetDelay;
                    when ResetOff =>
                        temp_res <= '1';
                        next_cmd <= ChargePump1;
                        current_state <= SetDelay;
                    when ChargePump1 =>
                        temp_spi_data <= "10001101"; --0x8D
                        next_cmd <= ChargePump2;
                        current_state <= SendSPI;
                    when ChargePump2 =>
                        temp_spi_data <= "00010100"; --0x14
                        next_cmd <= PreCharge1;
                        current_state <= SendSPI;
                    when PreCharge1 =>
                        temp_spi_data <= "11011001"; --0xD9
                        next_cmd <= PreCharge2;
                        current_state <= SendSPI;
                    when PreCharge2 =>
                        temp_spi_data <= "11110001"; --0xF1
                        next_cmd <= VbatOn;
                        current_state <= SendSPI;
                    when VbatOn =>
                        temp_vbat <= '0';
                        current_state <= VbatOnWait;
                    when VbatOnWait =>
                        next_cmd <= DispContrast1;
                        current_state <= SetDelay;
                    when DispContrast1=>
                        temp_spi_data <= "10000001"; --0x81
                        next_cmd <= DispContrast2;
                        current_state <= SendSPI;
                    when DispContrast2=>
                        temp_spi_data <= "00001111"; --0x0F
                        next_cmd <= InvertDisp1;
                        current_state <= SendSPI;
                    when InvertDisp1 =>
                        temp_spi_data <= "10100001"; --0xA1
                        next_cmd <= InvertDisp2;
                        current_state <= SendSPI;
                    when InvertDisp2 =>
                        temp_spi_data <= "11001000"; --0xC8
                        next_cmd <= ComConfig1;
                        current_state <= SendSPI;
                    when ComConfig1 =>
                        temp_spi_data <= "11011010"; --0xDA
                        next_cmd <= ComConfig2;
                        current_state <= SendSPI;
                    when ComConfig2 =>
                        temp_spi_data <= "00100000"; --0x20
                        next_cmd <= DispOn;
                        current_state <= SendSPI;
                    when DispOn =>
                        temp_spi_data <= "10101111"; --0xAF
                        next_cmd <= Done;
                        current_state <= SendSPI;
                    --END Initialization sequence

                    --Used for debugging, This command turns the entire screen on regardless of memory
                    when FullDisp =>
                        temp_spi_data <= "10100101"; --0xA5
                        next_cmd <= Done;
                        current_state <= SendSPI;

                    --Done state
                    when Done =>
                        if (EN = '0') then
                            temp_fin <= '0';
                            current_state <= Idle;
                        else
                            temp_fin <= '1';
                        end if;

                    --SPI transitions
                    --1. Set SPI_EN to 1
                    --2. Waits for SpiCtrl to finish
                    --3. Goes to clear state (ClearAndBack)
                    when SendSPI =>
                        temp_spi_en <= '1';
                        current_state <= WaitSPI;
                    when WaitSPI =>
                        if (temp_spi_fin = '1') then
                            current_state <= ClearAndBack;
                        end if;

                    --Delay Transitions
                    --1. Set DELAY_EN to 1
                    --2. Waits for Delay to finish
                    --3. Goes to Clear state (ClearAndBack)
                    when SetDelay =>
                        temp_delay_en <= '1';
                        current_state <= WaitDelay;
                    when WaitDelay =>
                        if (temp_delay_fin = '1') then
                            current_state <= ClearAndBack;
                        end if;

                    --Clear transition
                    --1. Sets both DELAY_EN and SPI_EN to 0
                    --2. Go to after state
                    when ClearAndBack =>
                        temp_spi_en <= '0';
                        temp_delay_en <= '0';
                        current_state <= next_cmd;
                    --END SPI transitions
                    --END Delay Transitions
                    --END Clear transition

                    when others =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process;

end rtl;

