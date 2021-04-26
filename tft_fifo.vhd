library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity tft_fifo is
    port (
        clk             : in std_logic;
        resetn          : in std_logic;

        fifo_s_tvalid   : in std_logic;
        fifo_s_tready   : out std_logic;
        fifo_s_tdata    : in std_logic_vector(127 downto 0);
        fifo_s_tlast    : in std_logic;

        fifo_m_tvalid   : out std_logic;
        fifo_m_tready   : in std_logic;
        fifo_m_tdata    : out std_logic_vector(127 downto 0);
        fifo_m_tlast    : out std_logic
    );
end entity tft_fifo;

architecture rtl of tft_fifo is

    type ram_t is array (255 downto 0) of std_logic_vector(128 downto 0);

    signal wr_addr          : integer range 0 to 95;
    signal wr_addr_next     : integer range 0 to 95;
    signal rd_addr          : integer range 0 to 95;
    signal rd_addr_next     : integer range 0 to 95;
    signal fifo_ram         : ram_t;
    signal q_tdata          : std_logic_vector(128 downto 0);

    signal fifo_tvalid      : std_logic;
    signal fifo_tready      : std_logic;
    signal fifo_tlast       : std_logic;

    signal fifo_is_empty    : boolean;
    signal fifo_is_full     : boolean;

begin

    fifo_m_tvalid   <= fifo_tvalid;
    fifo_tready     <= fifo_m_tready;

    wr_addr_next    <= wr_addr + 1;
    rd_addr_next    <= rd_addr + 1;

    fifo_is_empty   <= wr_addr = rd_addr;
    fifo_is_full    <= wr_addr_next = rd_addr;

    q_tdata         <= fifo_ram(to_integer(unsigned(rd_addr)));

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                wr_addr <= 0;
                rd_addr <= 0;
            else
                if fifo_s_tvalid = '1' and not fifo_is_full then
                    wr_addr <= wr_addr_next;
                end if;
            end if;

            if fifo_s_tvalid = '1' and not fifo_is_full then
                fifo_ram(to_integer(unsigned(wr_addr))) <= fifo_s_tlast & fifo_s_tdata;
            end if;

        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                fifo_tvalid <= '0';
            else
                if fifo_tvalid = '0' or (fifo_tvalid = '1' and fifo_tready = '1') then
                    if not fifo_is_empty then
                        fifo_tvalid <= '1';
                    else
                        fifo_tvalid <= '0';
                    end if;
                elsif (fifo_tready = '1') then
                    fifo_tvalid <= '0';
                end if;
            end if;

            if fifo_tvalid = '0' or (fifo_tvalid = '1' and fifo_tready = '1') then
                fifo_m_tdata <= q_tdata(127 downto 0);
                fifo_m_tlast <= q_tdata(128);
            end if;

        end if;
    end process;

end architecture;