----------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Ryan Kim
--
-- Create Date:    15:14:14 10/10/2011
-- Module Name:    oled_spi_ctrl - rtl
-- Project Name:   PmodOled Demo
-- Tool versions:  ISE 13.2
-- Description:    Spi block that sends SPI data formatted SCLK active low with
--                    SDO changing on the falling edge
--
-- Revision: 1.0 - SPI completed
-- Revision 0.01 - File Created
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_ARITH.ALL;
use IEEE.std_logic_UNSIGNED.ALL;

entity oled_spi_ctrl is
    Port (
        clk         : in std_logic; --System CLK (100MHz)
        resetn      : in std_logic; --Global resetn (Synchronous)

        spi_en      : in std_logic;     --SPI block enable pin
        spi_data    : in std_logic_vector (7 downto 0); --Byte to be sent
        spi_fin     : out std_logic;    --SPI finish flag

        CS          : out std_logic; --Chip Select
        SDO         : out std_logic; --SPI data out
        SCLK        : out std_logic --SPI clock
    );
end oled_spi_ctrl;

architecture rtl of oled_spi_ctrl is

    type states is (Idle, Send, Hold1, Hold2, Hold3, Hold4, Done);

    signal current_state : states := Idle; --Signal for state machine

    signal shift_register   : std_logic_vector(7 downto 0); --Shift register to shift out spi_data saved when spi_en was set
    signal shift_counter    : std_logic_vector(3 downto 0); --Keeps track how many bits were sent
    signal clk_divided      : std_logic := '1'; --Used as SCLK
    signal counter          : std_logic_vector(4 downto 0) := (others => '0'); --Count clocks to be used to divide CLK
    signal temp_sdo         : std_logic := '1'; --Tied to SDO

    signal falling          : std_logic := '0'; --signal indicating that the clk has just fell

begin
    clk_divided <= not counter(4); --SCLK = CLK / 32

    SCLK <= clk_divided;
    SDO <= temp_sdo;
    CS <= '1' when (current_state = Idle and spi_en = '0') else '0';
    spi_fin <= '1' when (current_state = Done) else '0';

    fsm_proc : process (clk) begin
        if (rising_edge(clk)) then
            if (resetn = '0') then --Synchronous resetn
                current_state <= Idle;
            else
                case (current_state) is
                    when Idle => --Wait for spi_en to go high
                        if (spi_en = '1') then
                            current_state <= Send;
                        end if;
                    when Send => --Start sending bits, transition out when all bits are sent and SCLK is high
                        if (shift_counter = "1000" and falling = '0') then
                            current_state <= Hold1;
                        end if;
                    when Hold1 => --Hold CS low for a bit
                        current_state <= Hold2;
                    when Hold2 => --Hold CS low for a bit
                        current_state <= Hold3;
                    when Hold3 => --Hold CS low for a bit
                        current_state <= Hold4;
                    when Hold4 => --Hold CS low for a bit
                        current_state <= Done;
                    when Done => --Finish SPI transimission wait for spi_en to go low
                        if (spi_en = '0') then
                            current_state <= Idle;
                        end if;
                    when others =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process;

    clk_div_proc : process (clk) begin
        if(rising_edge(clk)) then
            if (current_state = Send) then --start clock counter when in send state
                counter <= counter + 1;
            else --reset clock counter when not in send state
                counter <= (others => '0');
            end if;
        end if;
    end process;

    --sends SPI data formatted SCLK active low with SDO changing on the falling edge
    spi_send_byte_proc : process (CLK) begin
        if(rising_edge(clk)) then
            if (current_state = Idle) then
                shift_counter <= (others => '0');
                shift_register <= spi_data; --keeps placing spi_data into shift_register so that when state goes to send it has the latest spi_data
                temp_sdo <= '1';
            elsif (current_state = Send) then

                if (clk_divided = '0' and falling = '0') then --if on the falling edge of Clk_divided
                    falling <= '1'; --Indicate that it is passed the falling edge
                elsif (clk_divided = '1') then --on SCLK high reset the falling flag
                        falling <= '0';
                end if;

                if (clk_divided = '0' and falling = '0') then --if on the falling edge of Clk_divided
                    temp_sdo <= shift_register(7); --send out the MSB
                    shift_register <= shift_register(6 downto 0) & '0'; --Shift through spi_data
                    shift_counter <= shift_counter + 1; --Keep track of what bit it is on
                end if;
            end if;
        end if;
    end process;

end rtl;

