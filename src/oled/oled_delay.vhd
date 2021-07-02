----------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Ryan Kim
--
-- Create Date:    16:48:30 10/10/2011
-- Module Name:    Delay - Behavioral
-- Project Name:   PmodOled Demo
-- Tool versions:  ISE 13.2
-- Description:    Creates a delay of DELAY_MS ms
--
-- Revision: 1.0
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity oled_delay is
    port (
        clk         : in std_logic; --system clk
        resetn      : in std_logic;  --global rst (synchronous)
        delay_en    : in std_logic; --delay block enable
        delay_ms    : in std_logic_vector (11 downto 0); --amount of ms to delay
        delay_fin   : out std_logic --delay finish flag
    );
end oled_delay;

architecture rtl of oled_delay is

    type states is (Idle, Hold, Done);

    signal current_state    : states := idle; --signal for state machine
    signal clk_counter      : std_logic_vector(16 downto 0) := (others => '0'); --counts up on every rising edge of clk
    signal ms_counter       : std_logic_vector (11 downto 0) := (others => '0'); --counts up when clk_counter = 100,000

begin
    --delay_fin goes HIGH when delay is done
    delay_fin <= '1' when (current_state = Done and delay_en = '1') else '0';

    --State machine for Delay block
    fsm_proc : process (clk) begin
        if (rising_edge(clk)) then
            if (resetn = '0') then --When RST is asserted switch to idle (synchronous)
                current_state <= Idle;
            else
                case (current_state) is
                    when Idle =>
                        if (delay_en = '1') then --Start delay on delay_en
                            current_state <= Hold;
                        end if;
                    when Hold =>
                        if (ms_counter = delay_ms) then --stay until DELAY_MS has occured
                            current_state <= Done;
                        end if;
                    when Done =>
                        if(delay_en = '0') then --Wait til delay_en is deasserted to go to IDLE
                            current_state <= Idle;
                        end if;
                    when others =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process;

    --Creates ms_counter that counts at 1KHz
    clk_div_proc : process (clk) begin
        if (rising_edge(clk)) then
            if (current_state = Hold) then
                if (clk_counter = "11000011010100000") then --100,000
                    clk_counter <= (others => '0');
                    ms_counter <= ms_counter + 1; --increments at 1KHz
                else
                    clk_counter <= clk_counter + 1;
                end if;
            else --If not in the hold state reset counters
                clk_counter <= (others => '0');
                ms_counter <= (others => '0');
            end if;
        end if;
    end process;

end rtl;

