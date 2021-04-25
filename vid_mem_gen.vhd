library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity vid_mem_gen is
    port (
        clk                   : in std_logic;
        resetn                : in std_logic;
        --DDR interface
        cmd_en                : out std_logic;
        cmd_instr             : out std_logic_vector(2 downto 0);
        cmd_bl                : out std_logic_vector(5 downto 0);
        cmd_byte_addr         : out std_logic_vector(29 downto 0);
        cmd_empty             : in  std_logic;
        cmd_full              : in  std_logic;
        -- -- WR interface
        wr_en                 : out std_logic;
        wr_mask               : out std_logic_vector(16 - 1 downto 0);
        wr_data               : out std_logic_vector(128 - 1 downto 0);
        wr_full               : in  std_logic;
        wr_empty              : in  std_logic;
        wr_count              : in  std_logic_vector(6 downto 0);
        wr_underrun           : in  std_logic;
        wr_error              : in  std_logic;
        -- -- RD interface
        rd_en                 : out std_logic
        -- rd_data               : in  std_logic_vector(128 - 1 downto 0);
        -- rd_full               : in  std_logic;
        -- rd_empty              : in  std_logic;
        -- rd_count              : in  std_logic_vector(6 downto 0);
        -- rd_overflow           : in  std_logic;
        -- rd_error              : in  std_logic
    );

end entity;

architecture rtl of vid_mem_gen is

    constant VID_START_ADDR     : integer := 0;
    constant MAX_H              : integer := 480;
    constant MAX_V              : integer := 272;

    type rgb_ch_t is (R, G, B);
    type rgb_t is array (rgb_ch_t) of std_logic_vector(7 downto 0);

    type rgb_vector_t is array(4 downto 0) of rgb_t;

    signal pixel_addr           : integer;
    signal addr                 : integer;

    signal req_tvalid           : std_logic;
    signal req_tready           : std_logic;

    signal pixel_tvalid         : std_logic;
    signal pixel_tready         : std_logic;
    signal pixel_tlast          : std_logic;
    signal pixel_tdata          : rgb_t;

    signal ddr_data_tvalid      : std_logic;
    signal ddr_data_tready      : std_logic;
    signal ddr_data_tdata       : rgb_vector_t;
    signal pixel_idx            : integer range 0 to 4;

    signal start_cnt            : std_logic_vector(3 downto 0);

    signal wr_tvalid            : std_logic;
    signal wr_tready            : std_logic;
    signal wr_tdata             : rgb_vector_t;
    signal wr_fifo_cnt          : integer range 0 to 63;

    signal cmd_tvalid           : std_logic;
    signal cmd_tready           : std_logic;
    signal cmd_addr             : integer range 0 to 67108863; --0..2^26-1

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

    cmd_en <= cmd_tvalid;
    cmd_tready <= '1' when cmd_full = '0' else '0';
    cmd_instr <= "000";
    cmd_bl <= "111111";
    cmd_byte_addr <= std_logic_vector(to_unsigned(cmd_addr, 26)) & x"0";

    rd_en <= '0';

    wr_en <= wr_tvalid;
    wr_tready <= '1' when wr_full = '0' else '0';
    wr_data <= to_slv(wr_tdata);
    wr_mask <= x"0000";

    ddr_data_tready <= '1' when (wr_tready = '1') else '0';
    pixel_tready <= '1' when ddr_data_tvalid = '0' or (ddr_data_tvalid = '1' and ddr_data_tready = '1') else '0';
    req_tready <= '1' when req_tvalid = '1' and pixel_tready = '1' else '0';

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

                pixel_addr <= 0;
                pixel_tvalid <= '0';
                pixel_tlast <= '0';
            else

                if (start_cnt(3) = '1') then
                    req_tvalid <= '1';
                elsif (req_tvalid = '1' and req_tready = '1' and pixel_addr = MAX_H*MAX_V-1) then
                    req_tvalid <= '0';
                end if;

                if req_tvalid = '1' and req_tready = '1' and pixel_addr = MAX_H*MAX_V-1 then
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
                    pixel_addr <= pixel_addr + 1;
                end if;

            end if;

            if (req_tvalid = '1' and req_tready = '1') then
                pixel_tdata(R) <= x"00";
                pixel_tdata(G) <= x"FF";
                pixel_tdata(B) <= x"AA";
            end if;

        end if;
    end process;

    packing_data_for_ddr_process : process (clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                pixel_idx <= 0;
                ddr_data_tvalid <= '0';
            else

                if (pixel_tvalid = '1' and pixel_tready = '1') then
                    if (pixel_idx = 4) then
                        pixel_idx <= 0;
                    else
                        pixel_idx <= pixel_idx + 1;
                    end if;
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
            else
                if (ddr_data_tvalid = '1' and ddr_data_tready = '1') then
                    wr_tvalid <= '1';
                elsif wr_tready = '1' then
                    wr_tvalid <= '0';
                end if;

                if (ddr_data_tvalid = '1' and ddr_data_tready = '1') then
                    if (wr_fifo_cnt = 63) then
                        wr_fifo_cnt <= 0;
                    else
                        wr_fifo_cnt <= wr_fifo_cnt + 1;
                    end if;
                end if;
            end if;

            if ddr_data_tvalid = '1' and ddr_data_tready = '1' then
                wr_tdata <= ddr_data_tdata;
            end if;

        end if;
    end process;

    writing_data_to_cmd: process (clk)
    begin
        if rising_edge(clk) then
            if resetn = '0' then
                cmd_tvalid <= '0';
                cmd_addr <= 0;
            else
                if (ddr_data_tvalid = '1' and ddr_data_tready = '1' and wr_fifo_cnt = 63) then
                    cmd_tvalid <= '1';
                elsif (cmd_tready = '1') then
                    cmd_tvalid <= '0';
                end if;

                if cmd_tvalid = '1' and cmd_tready = '1' then
                    cmd_addr <= cmd_addr + 1;
                end if;
            end if;
        end if;
    end process;

end architecture;
