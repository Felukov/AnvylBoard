library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;
use ieee.math_real.all;

entity uart_rx is
    generic (
        FREQ        : integer := 100_000_000;
        RATE        : integer := 115_200
    );
    port (
        clk         : in std_logic;
        resetn      : in std_logic;
        rx          : in std_logic;
        rx_m_tvalid : out std_logic;
        rx_m_tdata  : out std_logic_vector(7 downto 0)
    );

end entity uart_rx;

architecture rtl of uart_rx is
    --constant COUNTER_WIDTH : positive := positive(ceil(log2(real(FREQ/RATE))));
    constant COUNTER_MAX : positive := positive(ceil(real(FREQ/RATE)));

    type rx_state_t is (RX_IDLE, RX_START, RX_RECEIVE, RX_STOP);

    signal rx_state     : rx_state_t;
    signal rx_cnt       : natural range 0 to COUNTER_MAX-1;
    signal rx_bit_cnt   : natural range 0 to 7;
    signal rx_tdata     : std_logic_vector(7 downto 0);
    signal rx_tvalid    : std_logic;
begin

    rx_m_tvalid <= rx_tvalid;
    rx_m_tdata <= rx_tdata;

    rx_handling_process: process (clk) begin

        if rising_edge(clk) then
            if resetn = '0' then
                rx_state <= RX_IDLE;
                rx_cnt <= 0;
                rx_bit_cnt <= 0;
                rx_tvalid <= '0';
                rx_tdata <= (others => '0');
            else
                case rx_state is
                    when RX_START =>
                        if rx = '0' and rx_cnt = COUNTER_MAX/2-1 then
                            rx_cnt <= 0;
                        elsif rx = '0' then
                            rx_cnt <= rx_cnt + 1;
                        else
                            rx_cnt <= 0;
                        end if;

                        if rx = '0' and rx_cnt = COUNTER_MAX/2-1 then
                            rx_state <= RX_RECEIVE;
                        elsif (rx = '1') then
                            rx_state <= RX_IDLE;
                        end if;

                        if rx = '0' and rx_cnt = COUNTER_MAX/2-1 then
                            rx_tdata <= (others => '0');
                        end if;

                    when RX_RECEIVE =>
                        if (rx_cnt = COUNTER_MAX-1) then
                            rx_cnt <= 0;
                        else
                            rx_cnt <= rx_cnt + 1;
                        end if;

                        if (rx_cnt = COUNTER_MAX-1) then
                            rx_bit_cnt <= (rx_bit_cnt + 1) mod 8;
                        end if;

                        if (rx_cnt = COUNTER_MAX-1) then
                            rx_tdata <= rx & rx_tdata(7 downto 1);
                        end if;

                        if (rx_cnt = COUNTER_MAX-1 and rx_bit_cnt = 7) then
                            rx_state <= RX_STOP;
                        end if;

                    when RX_STOP =>
                        if (rx_cnt = COUNTER_MAX-1) then
                            rx_cnt <= 0;
                        else
                            rx_cnt <= rx_cnt + 1;
                        end if;

                        if (rx_cnt = COUNTER_MAX-1) then
                            rx_tvalid <= '1';
                        end if;

                        if (rx_cnt = COUNTER_MAX-1) then
                            rx_state <= RX_IDLE;
                        end if;

                    when others =>
                        rx_tvalid <= '0';
                        if (rx = '0') then
                            rx_state <= RX_START;
                        end if;

                end case;
            end if;
        end if;

    end process;

end architecture;