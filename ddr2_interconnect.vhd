library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity ddr2_interconnect is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;
        --rd channel
        rd_s_tvalid             : in std_logic;
        rd_s_tready             : out std_logic;
        rd_s_tlast              : in std_logic;
        rs_s_taddr              : in std_logic_vector(25 downto 0);
        --wr channel
        wr_s_tvalid             : in std_logic;
        wr_s_tready             : out std_logic;
        wr_s_tlast              : in std_logic;
        wr_s_tdata              : in std_logic_vector(127 downto 0);
        wr_s_taddr              : in std_logic_vector(25 downto 0);
        --read back channel
        rd_m_tvalid             : out std_logic;
        rd_m_tready             : in std_logic;
        rd_m_tlast              : out std_logic;
        rd_m_tdata              : out std_logic_vector(25 downto 0);
        --DDR interface
        cmd_en                  : out std_logic;
        cmd_instr               : out std_logic_vector(2 downto 0);
        cmd_bl                  : out std_logic_vector(5 downto 0);
        cmd_byte_addr           : out std_logic_vector(29 downto 0);
        cmd_empty               : in  std_logic;
        cmd_full                : in  std_logic;
        -- -- WR interface
        wr_en                   : out std_logic;
        wr_mask                 : out std_logic_vector(16 - 1 downto 0);
        wr_data                 : out std_logic_vector(128 - 1 downto 0);
        wr_full                 : in  std_logic;
        wr_empty                : in  std_logic;
        wr_count                : in  std_logic_vector(6 downto 0);
        wr_underrun             : in  std_logic;
        wr_error                : in  std_logic;
        -- -- RD interface
        rd_en                   : out std_logic
        -- rd_data               : in  std_logic_vector(128 - 1 downto 0);
        -- rd_full               : in  std_logic;
        -- rd_empty              : in  std_logic;
        -- rd_count              : in  std_logic_vector(6 downto 0);
        -- rd_overflow           : in  std_logic;
        -- rd_error              : in  std_logic
    );
end entity;

architecture rtl of ddr2_interconnect is

    type ch_t is (RD_CH, WR_CH);

    signal ch : ch_t;

    signal ddr_s_tvalid : std_logic;
    signal ddr_s_tready : std_logic;
    signal ddr_s_tlast  : std_logic;
    signal ddr_s_tdata  : std_logic_vector(127 downto 0);
    signal ddr_s_tcmd   : std_logic;
    signal ddr_s_taddr  : std_logic_vector(25 downto 0);

    signal wr_fifo_cnt  : integer range 0 to 63;

    signal cmd_tvalid   : std_logic;
    signal cmd_tready   : std_logic;
    signal cmd_addr     : integer range 0 to 67108863; --0..2^26-1

begin
    cmd_en          <= cmd_tvalid;
    cmd_bl          <= "111111";
    cmd_tready      <= '1' when cmd_full = '0' else '0';
    cmd_byte_addr   <= std_logic_vector(to_unsigned(cmd_addr, 26)) & x"0";

    wr_en           <= '1' when ddr_s_tvalid = '1' and ddr_s_tcmd = '0' else '1';
    ddr_s_tready    <= '1' when wr_full = '0' else '0';
    wr_data         <= to_slv(ddr_s_tdata);
    wr_mask         <= x"0000";

    rd_en           <= '0';

    rd_s_tready     <= '1' when ddr_s_tvalid ='0' or (ddr_s_tvalid = '1' and ddr_s_tready = '1' and ch = RD_CH) else '0';
    wr_s_tready     <= '1' when ddr_s_tvalid ='0' or (ddr_s_tvalid = '1' and ddr_s_tready = '1' and ch = WR_CH) else '0';

    ch_monitor : process (clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                ch <= RD_CH;
            else
                if (rd_s_tvalid = '1' and rd_s_tready = '1' and rd_s_tlast = '1' and ch = RD_CH) then
                    ch  <= WR_CH;
                elsif (wr_s_tvalid = '1' and wr_s_tready = '1' and wr_s_tlast = '1' and ch = WR_CH) then
                    ch <= RD_CH;
                end if;
            end if;
        end if;
    end process;

    latch_data_process: process (clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                ddr_s_tvalid <= '0';
                ddr_s_tcmd <= '0';
                ddr_s_tlast <= '0';
                wr_fifo_cnt <= 0;
            else
                if rd_s_tvalid = '1' and rd_s_tready = '1' and ch = RD_CH then
                    ddr_s_tvalid <= '1';
                elsif wr_s_tvalid = '1' and wr_s_tready = '1' = and ch = WR_CH then
                    ddr_s_tvalid <= '1';
                elsif ddr_s_tready = '1' then
                    ddr_s_tvalid <= '0';
                end if;

                if rd_s_tvalid = '1' and rd_s_tready = '1' and ch = RD_CH then
                    ddr_s_tcmd <= '0';
                    ddr_s_tlast <= rd_s_tlast;
                elsif wr_s_tvalid = '1' and wr_s_tready = '1' and ch = WR_CH then
                    ddr_s_tcmd <= '1';
                    if (wr_fifo_cnt = 63) then
                        ddr_s_tlast <= '1';
                    else
                        ddr_s_tlast <= wr_s_tlast;
                    end if;
                end if;

                if (wr_s_tvalid = '1' and wr_s_tready = '1' and ch = WR_CH) then
                    if (wr_fifo_cnt = 63) then
                        wr_fifo_cnt <= 0;
                    else
                        wr_fifo_cnt <= wr_fifo_cnt + 1;
                    end if;
                end if;

            end if;

            if wr_s_tvalid = '1' and wr_s_tready = '1' = and ch = WR_CH then
                ddr_s_tdata <= wr_s_tdata;
            end if;

        end if;
    end process;

    writing_data_to_cmd: process (clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                cmd_tvalid <= '0';
                cmd_addr <= 0;
                cmd_instr <= "000";
            else

                if ddr_s_tvalid = '1' and ddr_s_tready = '1' and ddr_s_tlast = '1' then
                    cmd_tvalid <= '1';
                elsif (cmd_tready = '1') then
                    cmd_tvalid <= '0';
                end if;

                if ddr_s_tvalid = '1' and ddr_s_tready = '1' and ddr_s_tlast = '1' then
                    if (ddr_s_tcmd = '0') then
                        cmd_instr <= "000";
                    else
                        cmd_instr <= "001";
                    end if;
                    cmd_addr <= ddr_s_taddr;
                end if;

            end if;
        end if;
    end process;

end architecture;
