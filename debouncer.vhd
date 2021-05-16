library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;
use ieee.std_logic_unsigned.all;

entity debouncer is
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        pulse1ms_s_tvalid   : in std_logic;
        data_s_tvalid       : in std_logic;
        data_m_tvalid       : out std_logic;
        posedge_m_tvalid    : out std_logic;
        negedge_m_tvalid    : out std_logic
    );
end entity debouncer;

architecture rtl of debouncer is

    signal validator : std_logic_vector(2 downto 0);
    signal data_tvalid : std_logic;
    signal data_prev_tvalid : std_logic;

begin

    data_m_tvalid <= data_tvalid;

    process (clk) begin
        if rising_edge(clk) then
            if (resetn = '0') then
                validator <= "000";
                data_tvalid <= '0';
                data_prev_tvalid <= '0';
                posedge_m_tvalid <= '0';
                negedge_m_tvalid <= '0';
            else
                if pulse1ms_s_tvalid = '1' then
                    validator <= validator(1 downto 0) & data_s_tvalid;
                end if;

                if validator = "111" then
                    data_tvalid <= '1';
                else
                    data_tvalid <= '0';
                end if;

                data_prev_tvalid <= data_tvalid;

                if (data_prev_tvalid = '0' and data_tvalid = '1') then
                    posedge_m_tvalid <= '1';
                else
                    posedge_m_tvalid <= '0';
                end if;

                if (data_prev_tvalid = '1' and data_tvalid = '0') then
                    negedge_m_tvalid <= '1';
                else
                    negedge_m_tvalid <= '0';
                end if;

            end if;
        end if;
    end process;

end architecture;