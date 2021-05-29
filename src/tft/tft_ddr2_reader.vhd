library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;
use ieee.std_logic_unsigned.all;

entity tft_ddr2_reader is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;
        -- control requests
        next_frame_s_tvalid     : in std_logic;
        next_frame_s_tready     : out std_logic;
        next_frame_s_tdata      : in std_logic_vector(8 downto 0);
        --rd cmd channel
        rd_cmd_m_tvalid         : out std_logic;
        rd_cmd_m_tready         : in std_logic;
        rd_cmd_m_tlast          : out std_logic;
        rd_cmd_m_taddr          : out std_logic_vector(25 downto 0);
        --rd data channel from ddr
        rd_data_s_tvalid        : in std_logic;
        rd_data_s_tready        : out std_logic;
        rd_data_s_tdata         : in std_logic_vector(127 downto 0);
        --rd data channel to tft
        rd_data_m_tvalid        : out std_logic;
        rd_data_m_tready        : in std_logic;
        rd_data_m_tdata         : out std_logic_vector(23 downto 0)

    );
end entity tft_ddr2_reader;

architecture rtl of tft_ddr2_reader is
    type fifo_vector_t is array(4 downto 0) of std_logic_vector(23 downto 0);

    component tft_fifo is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;
            fifo_s_tvalid       : in std_logic;
            fifo_s_tready       : out std_logic;
            fifo_s_tdata        : in std_logic_vector(127 downto 0);
            fifo_m_tvalid       : out std_logic;
            fifo_m_tready       : in std_logic;
            fifo_m_tdata        : out std_logic_vector(127 downto 0)
        );
    end component;

    signal rd_cmd_tvalid        : std_logic;
    signal rd_cmd_tready        : std_logic;
    signal rd_cmd_cnt           : integer range 0 to 1;
    signal rd_cmd_taddr         : integer range 0 to 2**26-1;
    signal next_frame_tvalid    : std_logic;
    signal next_frame_tready    : std_logic;

    signal fifo_tvalid          : std_logic;
    signal fifo_tready          : std_logic;
    signal fifo_tdata           : std_logic_vector(127 downto 0);
    signal fifo_cnt             : natural range 0 to 127;

    signal filter_tvalid        : std_logic;
    signal filter_tready        : std_logic;
    signal filter_tdata         : std_logic_vector(127 downto 0);

    signal rd_data_tvalid       : std_logic;
    signal rd_data_tready       : std_logic;
    signal rd_data_tdata        : std_logic_vector(127 downto 0);
    signal rd_data_idx          : integer range 0 to 4;
begin

    tft_fifo_inst : tft_fifo port map (
        clk            => clk,
        resetn         => resetn,
        fifo_s_tvalid  => rd_data_s_tvalid,
        fifo_s_tready  => rd_data_s_tready,
        fifo_s_tdata   => rd_data_s_tdata,
        fifo_m_tvalid  => fifo_tvalid,
        fifo_m_tready  => fifo_tready,
        fifo_m_tdata   => fifo_tdata
    );

    next_frame_tvalid <= next_frame_s_tvalid;
    next_frame_s_tready <= next_frame_tready;

    next_frame_tready <= '1' when rd_cmd_tvalid = '0' or (rd_cmd_tvalid = '1' and rd_cmd_tready ='1' and rd_cmd_cnt = 1) else '0';

    rd_cmd_m_tvalid <= rd_cmd_tvalid;
    rd_cmd_tready <= rd_cmd_m_tready;
    rd_cmd_m_tlast <= rd_cmd_tvalid;
    rd_cmd_m_taddr <= std_logic_vector(to_unsigned(rd_cmd_taddr, 26));

    rd_data_m_tvalid <= rd_data_tvalid;
    rd_data_tready <= rd_data_m_tready;

    fifo_tready <= '1' when filter_tvalid = '0' or (filter_tvalid = '1' and filter_tready = '1') else '0';
    filter_tready <= '1' when rd_data_tvalid = '0' or (rd_data_tvalid = '1' and rd_data_tready = '1' and rd_data_idx = 4) else '0';

    rd_data_m_tdata_output: process (rd_data_idx, rd_data_tdata) begin
        case rd_data_idx is
            when 1 => rd_data_m_tdata <= rd_data_tdata(95 downto 72);
            when 2 => rd_data_m_tdata <= rd_data_tdata(71 downto 48);
            when 3 => rd_data_m_tdata <= rd_data_tdata(47 downto 24);
            when 4 => rd_data_m_tdata <= rd_data_tdata(23 downto 0);
            when others => rd_data_m_tdata <= rd_data_tdata(119 downto 96);
        end case;
    end process;

    forming_rd_cmd_signals_process: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                rd_cmd_tvalid <= '0';
                rd_cmd_cnt <= 0;
            else
                if (next_frame_tvalid = '1' and next_frame_tready = '1') then
                    rd_cmd_tvalid <= '1';
                elsif (rd_cmd_tready = '1' and rd_cmd_cnt = 1) then
                    rd_cmd_tvalid <= '0';
                end if;

                if (next_frame_tvalid = '1' and next_frame_tready = '1') then
                    rd_cmd_cnt <= 0;
                elsif (rd_cmd_tvalid = '1' and rd_cmd_tready = '1') then
                    rd_cmd_cnt <= (rd_cmd_cnt + 1) mod 2;
                end if;
            end if;

            if (next_frame_tvalid = '1' and next_frame_tready = '1') then
                -- addr = 96 * y => addr = y*2^6 + y*2^5 => addr = y << 6 + y << 5
                rd_cmd_taddr <= conv_integer(next_frame_s_tdata & "000000") + conv_integer(next_frame_s_tdata & "00000");
            elsif (rd_cmd_tvalid = '1' and rd_cmd_tready = '1') then
                rd_cmd_taddr <= rd_cmd_taddr + 64;
            end if;

        end if;
    end process;

    filter_data_process : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                filter_tvalid <= '0';
                fifo_cnt <= 0;
            else
                if fifo_tvalid = '1' and fifo_tready = '1' then
                    fifo_cnt <= (fifo_cnt + 1) mod 128;
                end if;

                if fifo_tvalid = '1' and fifo_tready = '1' then
                    if (fifo_cnt <= 95 ) then
                        filter_tvalid <= '1';
                    else
                        filter_tvalid <= '0';
                    end if;
                elsif filter_tready = '1' then
                    filter_tvalid <= '0';
                end if;

            end if;

            if fifo_tvalid = '1' and fifo_tready = '1' then
               filter_tdata <= fifo_tdata;
            end if;

        end if;
    end process;

    forming_output_signals_process: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                rd_data_tvalid <= '0';
                rd_data_idx <= 0;
            else
                if filter_tvalid = '1' and filter_tready = '1' then
                    rd_data_tvalid <= '1';
                elsif (rd_data_tready = '1' and rd_data_idx = 4) then
                    rd_data_tvalid <= '0';
                end if;

                if rd_data_tvalid = '1' and rd_data_tready = '1' then
                    if (rd_data_idx = 4) then
                        rd_data_idx <= 0;
                    else
                        rd_data_idx <= rd_data_idx + 1;
                    end if;
                end if;
            end if;

            if filter_tvalid = '1' and filter_tready = '1' then
                rd_data_tdata <= filter_tdata;
            end if;

        end if;
    end process;

end architecture;
