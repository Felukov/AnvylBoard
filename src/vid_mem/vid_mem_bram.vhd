library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;
use ieee.std_logic_unsigned.all;

entity vid_mem_bram is
    port (
        clk     : in std_logic;
        addra   : in std_logic_vector(6 downto 0);
        dina    : in std_logic_vector(55 downto 0);
        wea     : in std_logic;

        addrb   : in std_logic_vector(6 downto 0);
        enb     : in std_logic;
        regceb  : in std_logic;
        doutb   : out std_logic_vector(55 downto 0)
    );
end entity vid_mem_bram;

architecture rtl of vid_mem_bram is
    type ram_t is array (127 downto 0) of std_logic_vector (15 downto 0);
    signal ram : ram_t;
    signal dout : std_logic_vector(55 downto 0);
begin

    process (clk) begin
        if rising_edge(clk) then
            if wea = '1' then
                ram(conv_integer(addra)) <= dina;
            end if;
        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if (enb = '1') then
                dout <= ram(conv_integer(addrb));
            end if;
        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if (regceb = '1') then
                doutb <= dout;
            end if;
        end if;
    end process;

end architecture;