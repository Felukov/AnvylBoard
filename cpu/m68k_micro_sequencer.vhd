library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity m68k_micro_sequencer is

    port (
        cpu_clk             : in std_logic;
        cpu_resetn          : in std_logic;
        cpu_new_addr_tvalid : in std_logic;
        cpu_new_addr_tdata  : in std_logic;

        cpu_cmd_tvalid      : out std_logic;
        cpu_cmd_tdata       : out std_logic_vector(15 downto 0)
    );

end m68k_micro_sequencer;

architecture Behavioral of m68k_micro_sequencer is

    signal counter : integer(3 downto 0);
    
begin

    counter_process : process (cpu_clk)
    begin
        if (cpu_resetn = '1') then
            counter <= 0;
        elsif (cpu_new_addr_tvalid = '1') then            
            counter <= 4;
        else
            counter <= (counter + 1) mod 7;
        end if;
        
    end process;

    jump_process: process (cpu_clk) begin
        
    end process;

end Behavioral;
