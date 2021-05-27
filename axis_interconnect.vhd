library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;
use ieee.std_logic_unsigned.all;

entity axis_interconnect is
    generic (
        CH_QTY              : integer := 4;
        DATA_WIDTH          : integer := 32;
        USER_WIDTH          : integer := 32
    );
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        ch_in_s_tvalid      : in std_logic_vector(CH_QTY-1 downto 0);
        ch_in_s_tready      : out std_logic_vector(CH_QTY-1 downto 0);
        ch_in_s_tlast       : in std_logic_vector(CH_QTY-1 downto 0);
        ch_in_s_tdata       : in std_logic_vector(CH_QTY*DATA_WIDTH-1 downto 0);
        ch_in_s_tuser       : in std_logic_vector(CH_QTY*USER_WIDTH-1 downto 0);

        ch_out_m_tvalid     : out std_logic;
        ch_out_m_tready     : in std_logic;
        ch_out_m_tlast      : out std_logic;
        ch_out_m_tdata      : out std_logic_vector(DATA_WIDTH-1 downto 0);
        ch_out_m_tuser      : out std_logic_vector(USER_WIDTH-1 downto 0)
    );
end entity axis_interconnect;

architecture rtl of axis_interconnect is

    signal ch_in_tvalid     : std_logic_vector(CH_QTY-1 downto 0);
    signal ch_in_tready     : std_logic;
    signal ch_in_tlast      : std_logic_vector(CH_QTY-1 downto 0);
    signal ch_in_tdata      : std_logic_vector(CH_QTY*DATA_WIDTH-1 downto 0);
    signal ch_in_tuser      : std_logic_vector(CH_QTY*USER_WIDTH-1 downto 0);
    signal ch_in_locked     : std_logic;

    signal ch_out_tvalid    : std_logic;
    signal ch_out_tready    : std_logic;
    signal ch_out_tlast     : std_logic;
    signal ch_out_tdata     : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal ch_out_tuser     : std_logic_vector(USER_WIDTH-1 downto 0);

    signal active_ch        : natural range 0 to CH_QTY-1;

begin

    ch_in_tvalid <= ch_in_s_tvalid;
    gen_ch_in_s_tready: for i in 0 to CH_QTY-1 generate
        ch_in_s_tready(i) <= '1' when ch_in_tvalid(i) = '1' and ch_in_tready = '1' and i = active_ch else '0';
    end generate gen_ch_in_s_tready;
    ch_in_tlast <= ch_in_s_tlast;
    ch_in_tdata <= ch_in_s_tdata;
    ch_in_tuser <= ch_in_s_tuser;

    ch_out_m_tvalid <= ch_out_tvalid;
    ch_out_tready <= ch_out_m_tready;
    ch_out_m_tlast <= ch_out_tlast;
    ch_out_m_tdata <= ch_out_tdata;
    ch_out_m_tuser <= ch_out_tuser;

    ch_in_tready <= '1' when ch_out_tvalid = '0' or (ch_out_tvalid = '1' and ch_out_tready = '1') else '0';

    channel_select_process: process (clk) begin

        if rising_edge(clk) then
            if resetn = '0' then
                ch_in_locked <= '0';
                active_ch <= 0;
            else

                if ch_in_locked = '0' or (ch_in_tvalid(active_ch) = '1' and ch_in_tready = '1' and ch_in_tlast(active_ch) = '1') then
                    if (active_ch = CH_QTY-1) then
                        active_ch <= 0;
                    else
                        active_ch <= active_ch + 1;
                    end if;
                end if;

                if ch_in_tvalid(active_ch) = '1' and ch_in_tready = '1' then
                    if ch_in_tlast(active_ch) = '0' then
                        ch_in_locked <= '1';
                    else
                        ch_in_locked <= '0';
                    end if;
                end if;

            end if;
        end if;

    end process;

    latching_output_process: process (clk) begin

        if rising_edge(clk) then
            if resetn = '0' then
                ch_out_tvalid <= '0';
                ch_out_tlast <= '0';
            else
                if (ch_in_tvalid(active_ch) = '1' and ch_in_tready = '1') then
                    ch_out_tvalid <= '1';
                elsif (ch_out_tready = '1') then
                    ch_out_tvalid <= '0';
                end if;
                if (ch_in_tvalid(active_ch) = '1' and ch_in_tready = '1') then
                    ch_out_tlast <= ch_in_tlast(active_ch);
                end if;
            end if;

            if (ch_in_tvalid(active_ch) = '1' and ch_in_tready = '1') then
                for i in 0 to CH_QTY-1 loop
                    if i = active_ch then
                        ch_out_tdata <= ch_in_tdata((i+1)*DATA_WIDTH-1 downto i*DATA_WIDTH);
                        ch_out_tuser <= ch_in_tuser((i+1)*USER_WIDTH-1 downto i*USER_WIDTH);
                    end if;
                end loop;
            end if;

        end if;

    end process;

end architecture;