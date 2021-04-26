library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity tft_ddr2_reader is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        next_frame_s_tvalid     : in std_logic;
        next_frame_s_tready     : out std_logic;

        --rd cmd channel
        rd_m_tvalid             : out std_logic;
        rd_m_tready             : in std_logic;
        rd_m_tlast              : out std_logic;
        rd_m_taddr              : out std_logic_vector(25 downto 0)

    );
end entity tft_ddr2_reader;

architecture rtl of tft_ddr2_reader is

    signal rd_cmd_tvalid        : std_logic;
    signal rd_cmd_tready        : std_logic;
    signal rd_cmd_busy          : std_logic;

    signal next_frame_tvalid    : std_logic;
    signal next_frame_tready    : std_logic;

begin

    next_frame_tvalid <= next_frame_s_tvalid;
    next_frame_s_tready <= next_frame_tready;

    next_frame_tready <= '1' when (
        (rd_cmd_tvalid = '0' or (rd_cmd_tvalid = '1' and rd_cmd_tready ='1')) and
        (rd_cmd_busy = '0')
    ) else '0';

    rd_m_tvalid <= rd_cmd_tvalid;
    rd_cmd_tready <= rd_m_tready;
    rd_m_tlast <= rd_cmd_tvalid;
    rd_m_taddr <= (others => '0');

    forming_rd_cmd_signals_process: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                rd_cmd_busy <= '0';
                rd_cmd_tvalid <= '0';
            else

                if (next_frame_tvalid = '1' and next_frame_tready = '1') then
                    rd_cmd_tvalid <= '1';
                elsif (rd_cmd_tready = '1') then
                    rd_cmd_tvalid <= '0';
                end if;

                if (next_frame_tvalid = '1' and rd_cmd_tready = '1') then
                    rd_cmd_busy <= '0';
                end if;

            end if;
        end if;
    end process;



end architecture;