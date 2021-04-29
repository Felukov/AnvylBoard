library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity vid_mem_gen is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        wr_m_tvalid             : out std_logic;
        wr_m_tready             : in std_logic;
        wr_m_tlast              : out std_logic;
        wr_m_tdata              : out std_logic_vector(127 downto 0);
        wr_m_taddr              : out std_logic_vector(25 downto 0)
    );

end entity;

architecture rtl of vid_mem_gen is

    constant VID_START_ADDR     : integer := 0;
    constant MAX_H              : integer := 480;
    constant MAX_V              : integer := 272;

    type rgb_ch_t is (R, G, B);
    type rgb_t is array (rgb_ch_t) of std_logic_vector(7 downto 0);

    type rgb_vector_t is array(4 downto 0) of rgb_t;

    signal x                    : integer range 0 to MAX_H-1;
    signal y                    : integer range 0 to MAX_V-1;
    signal addr                 : integer;

    signal req_tvalid           : std_logic;
    signal req_tready           : std_logic;

    signal pixel_tvalid         : std_logic;
    signal pixel_tready         : std_logic;
    signal pixel_tlast          : std_logic;
    signal pixel_tdata          : rgb_t;

    signal ddr_data_tvalid      : std_logic;
    signal ddr_data_tready      : std_logic;
    signal ddr_data_tlast       : std_logic;
    signal ddr_data_tdata       : rgb_vector_t;
    signal pixel_idx            : integer range 0 to 4;

    signal start_cnt            : std_logic_vector(3 downto 0);

    signal wr_tvalid            : std_logic;
    signal wr_tready            : std_logic;
    signal wr_tlast             : std_logic;
    signal wr_tdata             : rgb_vector_t;
    signal wr_taddr             : integer range 0 to 2**26-1;
    signal wr_fifo_cnt          : integer range 0 to 63;

    function to_slv(rgb_vec : rgb_vector_t) return std_logic_vector is
        variable slv : std_logic_vector(127 downto 0);
        variable rgb : rgb_t;
        variable idx : natural;
    begin
        idx := 0;
        for i in 4 downto 0 loop
            rgb := rgb_vec(i);
            for ch in rgb_ch_t'left to rgb_ch_t'right loop
                slv(idx + 7 downto idx) := rgb(ch);
                idx := idx + 8;
            end loop;
        end loop;
        slv(127 downto 120) := x"00";
        return slv;
    end function;

begin

    wr_m_tvalid     <= wr_tvalid;
    wr_tready       <= wr_m_tready;
    wr_m_tlast      <= wr_tlast;
    wr_m_tdata      <= to_slv(wr_tdata);
    wr_m_taddr      <= std_logic_vector(to_unsigned(wr_taddr, 26));

    ddr_data_tready <= '1' when (wr_tready = '1') else '0';
    pixel_tready    <= '1' when ddr_data_tvalid = '0' or (ddr_data_tvalid = '1' and ddr_data_tready = '1') else '0';
    req_tready      <= '1' when req_tvalid = '1' and pixel_tready = '1' else '0';

    start_cnt_process: process (clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                start_cnt <= "0001";
            else
                start_cnt <= start_cnt(2 downto 0) & '0';
            end if;
        end if;
    end process;

    forming_pixel_values: process (clk)
    begin
        if rising_edge(clk) then
            if (resetn = '0') then
                req_tvalid <= '0';
                pixel_tvalid <= '0';
                pixel_tlast <= '0';
                x <= 0;
                y <= 0;
            else

                if (start_cnt(3) = '1') then
                    req_tvalid <= '1';
                elsif (req_tvalid = '1' and req_tready = '1' and x = MAX_H-1 and y = MAX_V-1) then
                    req_tvalid <= '0';
                end if;

                if req_tvalid = '1' and req_tready = '1' and x = MAX_H-1 and y = MAX_V-1 then
                    pixel_tlast <= '1';
                elsif req_tready = '1' then
                    pixel_tlast <= '0';
                end if;

                if (req_tvalid = '1' and req_tready = '1') then
                    pixel_tvalid <= '1';
                elsif (pixel_tready = '1') then
                    pixel_tvalid <= '0';
                end if;

                if (req_tvalid = '1' and req_tready = '1') then
                    if (x = MAX_H-1) then
                        x <= 0;
                    else
                        x <= x + 1;
                    end if;
                end if;

                if (req_tvalid = '1' and req_tready = '1') then
                    if (x = MAX_H-1) then
                        if (y = MAX_V-1) then
                            y <= 0;
                        else
                            y <= y + 1;
                        end if;
                    end if;
                end if;

            end if;

            if (req_tvalid = '1' and req_tready = '1') then
                if (x = 0 or y = 0 or x = MAX_H-1 or y = MAX_V-1) then
                    pixel_tdata(R) <= std_logic_vector(to_unsigned(x, 8));
                    --pixel_tdata(R) <= x"FF";
                    pixel_tdata(G) <= x"FF";
                    pixel_tdata(B) <= x"FF";
                else
                    --pixel_tdata(R) <= x"00";
                    pixel_tdata(R) <= std_logic_vector(to_unsigned(x, 8));
                    pixel_tdata(G) <= x"00";
                    pixel_tdata(B) <= x"AA";
                end if;
            end if;

        end if;
    end process;

    packing_data_for_ddr_process : process (clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                pixel_idx <= 0;
                ddr_data_tvalid <= '0';
                ddr_data_tlast <= '0';
            else

                if (pixel_tvalid = '1' and pixel_tready = '1') then
                    if (pixel_idx = 4) then
                        pixel_idx <= 0;
                    else
                        pixel_idx <= pixel_idx + 1;
                    end if;
                end if;

                if (pixel_tvalid = '1' and pixel_tready = '1') then
                    ddr_data_tlast <= pixel_tlast;
                end if;

                if (pixel_tvalid = '1' and pixel_tready = '1' and pixel_idx = 4) then
                    ddr_data_tvalid <= '1';
                elsif ddr_data_tready = '1' then
                    ddr_data_tvalid <= '0';
                end if;
            end if;

            if (pixel_tvalid = '1' and pixel_tready = '1') then
                ddr_data_tdata(pixel_idx) <= pixel_tdata;
            end if;

        end if;
    end process;

    writing_data_to_ddr_fifo: process (clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                wr_tvalid <= '0';
                wr_fifo_cnt <= 0;
                wr_taddr <= 0;
                wr_tlast <= '0';
            else
                if (ddr_data_tvalid = '1' and ddr_data_tready = '1') then
                    wr_tvalid <= '1';
                elsif wr_tready = '1' then
                    wr_tvalid <= '0';
                end if;

                if (ddr_data_tvalid = '1' and ddr_data_tready = '1') then
                    if (wr_fifo_cnt = 63) then
                        wr_tlast <= '1';
                    else
                        wr_tlast <= ddr_data_tlast;
                    end if;
                end if;

                if (ddr_data_tvalid = '1' and ddr_data_tready = '1') then
                    if (wr_fifo_cnt = 63) then
                        wr_fifo_cnt <= 0;
                    else
                        wr_fifo_cnt <= wr_fifo_cnt + 1;
                    end if;
                end if;

                if (wr_tvalid = '1' and wr_tready = '1' and wr_tlast = '1') then
                    wr_taddr <= wr_taddr + 64;
                end if;
            end if;

            if ddr_data_tvalid = '1' and ddr_data_tready = '1' then
                wr_tdata <= ddr_data_tdata;
            end if;

        end if;
    end process;

end architecture;
