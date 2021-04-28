library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use UNISIM.VComponents.all;

entity tft_fifo is
    port (
        clk             : in std_logic;
        resetn          : in std_logic;

        fifo_s_tvalid   : in std_logic;
        fifo_s_tready   : out std_logic;
        fifo_s_tdata    : in std_logic_vector(127 downto 0);

        fifo_m_tvalid   : out std_logic;
        fifo_m_tready   : in std_logic;
        fifo_m_tdata    : out std_logic_vector(127 downto 0)
    );
end entity tft_fifo;

architecture rtl of tft_fifo is
    constant FIFO_MAX_ADDR       : natural := 255;
    type ram_t is array (FIFO_MAX_ADDR downto 0) of std_logic_vector(127 downto 0);

    signal wr_addr          : integer range 0 to FIFO_MAX_ADDR;
    signal wr_addr_next     : integer range 0 to FIFO_MAX_ADDR;
    signal rd_addr          : integer range 0 to FIFO_MAX_ADDR;
    signal rd_addr_next     : integer range 0 to FIFO_MAX_ADDR;
    signal fifo_ram         : ram_t;
    signal q_tdata          : std_logic_vector(127 downto 0);

    signal in_tvalid        : std_logic;
    signal in_tready        : std_logic;

    signal out_tvalid       : std_logic;
    signal out_tready       : std_logic;
    signal out_tdata        : std_logic_vector(127 downto 0);

    signal fifo_is_empty    : boolean;
    signal fifo_is_full     : boolean;

begin

    fifo_s_tready   <= '0' when fifo_is_full else '1';

    fifo_m_tvalid   <= out_tvalid;
    fifo_m_tdata    <= out_tdata;
    out_tready      <= fifo_m_tready;

    in_tready       <= '1' when out_tvalid = '0' or (out_tvalid = '1' and out_tready = '1') else '0';

    wr_addr_next    <= (wr_addr + 1) mod (FIFO_MAX_ADDR+1);
    rd_addr_next    <= (rd_addr + 1) mod (FIFO_MAX_ADDR+1);

    fifo_is_empty   <= wr_addr = rd_addr;
    fifo_is_full    <= wr_addr_next = rd_addr;

    q_tdata         <= fifo_ram(rd_addr);

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                wr_addr <= 0;
                in_tvalid <= '0';
            else

                if fifo_s_tvalid = '1' and not fifo_is_full then
                    wr_addr <= wr_addr_next;
                end if;

                if not fifo_is_empty then
                    in_tvalid <= '1';
                elsif in_tready = '1' then
                    in_tvalid <= '0';
                end if;

            end if;

            if fifo_s_tvalid = '1' and not fifo_is_full then
                fifo_ram(wr_addr) <= fifo_s_tdata;
            end if;

        end if;
    end process;


    process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                rd_addr <= 0;
                out_tvalid <= '0';
            else

                if in_tvalid = '1' and in_tready = '1' and not fifo_is_empty then
                    rd_addr <= rd_addr_next;
                end if;

                if in_tvalid = '1' and in_tready = '1' and not fifo_is_empty then
                    out_tvalid <= '1';
                elsif out_tready = '1' then
                    out_tvalid <= '0';
                end if;

            end if;

            --if in_tvalid = '1' and in_tready = '1' and not fifo_is_empty then
            if in_tready = '1' then
                out_tdata <= q_tdata;
            end if;

        end if;
    end process;

end architecture;