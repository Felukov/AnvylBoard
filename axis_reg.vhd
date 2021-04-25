----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    18:52:59 04/04/2021
-- Design Name:
-- Module Name:    axis_reg - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axis_reg is
    generic (
        TDATA_WIDTH         : natural := 32
    );
    port (
        clk                 : in  std_logic;
        rst                 : in  std_logic;
        axis_s_tvalid       : in  std_logic;
        axis_s_tready       : out  std_logic;
        axis_s_tdata        : in  std_logic_vector (TDATA_WIDTH-1 downto 0);
        axis_m_tvalid       : out  std_logic;
        axis_m_tready       : in  std_logic;
        axis_m_tdata        : out  std_logic_vector (TDATA_WIDTH-1 downto 0)
    );
end axis_reg;

architecture Behavioral of axis_reg is

    signal tmp_in_tvalid    : std_logic;
    signal tmp_in_tdata     : std_logic_vector(TDATA_WIDTH-1 downto 0);
    signal buf_tvalid       : std_logic;

begin

    axis_s_tready <= '1' when tmp_in_tvalid = '0' else '1';

    tmp_buffer_process : process(clk) begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                tmp_in_tvalid <= '0';
            else
                if (buf_tvalid = '0' or (buf_tvalid = '1' and axis_m_tready = '1')) then
                    if (tmp_in_tvalid = '0') then
                        tmp_in_tvalid <= axis_s_tvalid;
                    else
                        tmp_in_tvalid <= '0';
                    end if;
                end if;
            end if;
        end if;

        if (tmp_in_tvalid = '0' and (buf_tvalid = '0' or (buf_tvalid = '1' and axis_m_tready = '1'))) then
            tmp_in_tdata <= axis_s_tdata;
        end if;

    end process;

    output_process : process(clk) begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                buf_tvalid <= '0';
            else
                if (buf_tvalid = '0' or (buf_tvalid = '1' and axis_m_tready = '1')) then
                    if (tmp_in_tvalid = '1' or axis_s_tvalid = '1') then
                        buf_tvalid <= '1';
                    else
                        buf_tvalid <= '0';
                    end if;
                elsif (axis_m_tready = '1') then
                    buf_tvalid <= '0';
                end if;
            end if;
        end if;

        if (buf_tvalid = '0' or (buf_tvalid = '1' and axis_m_tready = '1')) then
            if (tmp_in_tvalid = '1') then
                axis_m_tdata <= tmp_in_tdata;
            elsif (axis_s_tvalid = '1') then
                axis_m_tdata <= axis_s_tdata;
            end if;
        end if;
    end process;

    axis_m_tvalid <= buf_tvalid;

end Behavioral;
