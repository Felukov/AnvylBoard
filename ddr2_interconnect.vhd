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
        rd_s_taddr              : in std_logic_vector(25 downto 0);
        --wr channel
        wr_s_tvalid             : in std_logic;
        wr_s_tready             : out std_logic;
        wr_s_tlast              : in std_logic;
        wr_s_tdata              : in std_logic_vector(127 downto 0);
        wr_s_taddr              : in std_logic_vector(25 downto 0);
        --read back channel
        rd_m_tvalid             : out std_logic;
        rd_m_tready             : in std_logic;
        rd_m_tdata              : out std_logic_vector(127 downto 0);
        --DDR interface
        cmd_en                  : out std_logic;
        cmd_instr               : out std_logic_vector(2 downto 0);
        cmd_bl                  : out std_logic_vector(5 downto 0);
        cmd_byte_addr           : out std_logic_vector(29 downto 0);
        cmd_empty               : in std_logic;
        cmd_full                : in std_logic;
        -- WR interface
        wr_en                   : out std_logic;
        wr_mask                 : out std_logic_vector(16 - 1 downto 0);
        wr_data                 : out std_logic_vector(128 - 1 downto 0);
        wr_full                 : in std_logic;
        wr_empty                : in std_logic;
        wr_count                : in std_logic_vector(6 downto 0);
        wr_underrun             : in std_logic;
        wr_error                : in std_logic;
        -- RD interface
        rd_en                   : out std_logic;
        rd_data                 : in std_logic_vector(128 - 1 downto 0);
        rd_full                 : in std_logic;
        rd_empty                : in std_logic;
        rd_count                : in std_logic_vector(6 downto 0);
        rd_overflow             : in std_logic;
        rd_error                : in std_logic
    );
end entity;

architecture rtl of ddr2_interconnect is

    type ch_t is (RD_CH, WR_CH);
    type cmd_t is (RD_CMD, WR_CMD);

    signal ch : ch_t;

    signal ddr_s_tvalid : std_logic;
    signal ddr_s_tready : std_logic;
    signal ddr_s_tlast  : std_logic;
    signal ddr_s_tdata  : std_logic_vector(127 downto 0);
    signal ddr_s_tcmd   : cmd_t;
    signal ddr_s_taddr  : std_logic_vector(25 downto 0);

    signal cmd_tvalid   : std_logic;
    signal cmd_tready   : std_logic;
    signal cmd_addr     : std_logic_vector(25 downto 0);

    signal wr_tvalid    : std_logic;
    signal wr_tready    : std_logic;
    signal wr_tfirst    : std_logic;

    signal rd_tvalid    : std_logic;
    signal rd_tready    : std_logic;
    signal rd_tfirst    : std_logic;
begin
    cmd_en          <= cmd_tvalid;
    cmd_bl          <= "111111";
    cmd_tready      <= '1' when cmd_full = '0' else '0';
    cmd_byte_addr   <= cmd_addr & x"0";

    wr_en           <= '1' when ddr_s_tvalid = '1' and ddr_s_tcmd = WR_CMD else '0';
    ddr_s_tready    <= '1' when wr_full = '0' else '0';
    wr_data         <= ddr_s_tdata;
    wr_mask         <= x"0000";

    rd_en           <= rd_m_tready;
    rd_m_tvalid     <= '1' when rd_empty = '0' else '0';
    rd_m_tdata      <= rd_data;

    rd_tvalid       <= '1' when rd_s_tvalid = '1' and ch = RD_CH else '0';
    rd_tready       <= '1' when ch = RD_CH and (ddr_s_tvalid ='0' or (ddr_s_tvalid = '1' and ddr_s_tready = '1')) else '0';

    wr_tvalid       <= '1' when wr_s_tvalid = '1' and ch = WR_CH else '0';
    wr_tready       <= '1' when ch = WR_CH and (ddr_s_tvalid ='0' or (ddr_s_tvalid = '1' and ddr_s_tready = '1')) else '0';

    rd_s_tready     <= rd_tready;
    wr_s_tready     <= wr_tready;

    ch_monitor : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                ch <= RD_CH;
                wr_tfirst <= '1';
                rd_tfirst <= '1';
            else

                if rd_tvalid = '1' and rd_tready = '1' then
                    if (rd_s_tlast = '1') then
                        rd_tfirst <= '1';
                    else
                        rd_tfirst <= '0';
                    end if;
                end if;

                if wr_tvalid = '1' and wr_tready = '1' then
                    if (wr_s_tlast = '1') then
                        wr_tfirst <= '1';
                    else
                        wr_tfirst <= '0';
                    end if;
                end if;

                if (rd_tvalid = '1' and rd_tready = '1' and rd_s_tlast = '1' and ch = RD_CH) then
                    ch  <= WR_CH;
                elsif (wr_tvalid = '1' and wr_tready = '1' and wr_s_tlast = '1' and ch = WR_CH) then
                    ch <= RD_CH;
                elsif (rd_tfirst = '1' and wr_tfirst = '1') then
                    if (ch = RD_CH and rd_tvalid = '0') then
                        ch <= WR_CH;
                    elsif (ch = WR_CH and wr_tvalid = '0') then
                        ch <= RD_CH;
                    end if;
                end if;

            end if;
        end if;
    end process;

    latch_data_process: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                ddr_s_tvalid <= '0';
                ddr_s_tcmd <= WR_CMD;
                ddr_s_tlast <= '0';
            else

                if rd_tvalid = '1' and rd_tready = '1' and ch = RD_CH then
                    ddr_s_tvalid <= '1';
                elsif wr_tvalid = '1' and wr_tready = '1' and ch = WR_CH then
                    ddr_s_tvalid <= '1';
                elsif ddr_s_tready = '1' then
                    ddr_s_tvalid <= '0';
                end if;

                if rd_tvalid = '1' and rd_tready = '1' and ch = RD_CH then
                    ddr_s_tcmd <= RD_CMD;
                    ddr_s_tlast <= rd_s_tlast;
                elsif wr_tvalid = '1' and wr_tready = '1' and ch = WR_CH then
                    ddr_s_tcmd <= WR_CMD;
                    ddr_s_tlast <= wr_s_tlast;
                end if;

            end if;

            if rd_tvalid = '1' and rd_tready = '1' and ch = RD_CH then
                ddr_s_taddr <= rd_s_taddr;
            elsif wr_tvalid = '1' and wr_tready = '1' and ch = WR_CH then
                ddr_s_taddr <= wr_s_taddr;
            end if;

            if wr_tvalid = '1' and wr_tready = '1' and ch = WR_CH then
                ddr_s_tdata <= wr_s_tdata;
            end if;

        end if;
    end process;

    writing_data_to_cmd: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                cmd_tvalid <= '0';
                cmd_addr <= (others => '0') ;
                cmd_instr <= "000";
            else

                if ddr_s_tvalid = '1' and ddr_s_tready = '1' and ddr_s_tlast = '1' then
                    cmd_tvalid <= '1';
                elsif (cmd_tready = '1') then
                    cmd_tvalid <= '0';
                end if;

                if ddr_s_tvalid = '1' and ddr_s_tready = '1' and ddr_s_tlast = '1' then
                    if (ddr_s_tcmd = WR_CMD) then
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
