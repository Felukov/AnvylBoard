library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;
use ieee.std_logic_unsigned.all;

entity vid_mem_gen is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        event_s_tvalid          : in std_logic;
        event_s_tready          : out std_logic;
        event_s_tlast           : in std_logic;

        event_m_tvalid          : out std_logic;

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
    constant FIFO_LEN           : integer := 64;
    constant GLYPHS_CNT         : natural := 12*8;

    constant GL_0               : natural := 0;
    constant GL_1               : natural := 1;
    constant GL_2               : natural := 2;
    constant GL_3               : natural := 3;
    constant GL_4               : natural := 4;
    constant GL_5               : natural := 5;
    constant GL_6               : natural := 6;
    constant GL_7               : natural := 7;
    constant GL_8               : natural := 8;
    constant GL_9               : natural := 9;
    constant GL_A               : natural := 10;
    constant GL_B               : natural := 11;
    constant GL_C               : natural := 12;
    constant GL_D               : natural := 13;
    constant GL_E               : natural := 14;
    constant GL_F               : natural := 15;

    constant GL_ADD             : natural := 16;
    constant GL_SUB             : natural := 17;
    constant GL_MUL             : natural := 18;
    constant GL_DIV             : natural := 19;
    constant GL_AND             : natural := 20;
    constant GL_OR              : natural := 21;
    constant GL_XOR             : natural := 22;
    constant GL_NOT             : natural := 23;
    constant GL_NEG             : natural := 24;
    constant GL_SHL             : natural := 25;
    constant GL_SHR             : natural := 26;
    constant GL_EQ              : natural := 27;
    constant GL_BACK            : natural := 28;
    constant GL_NULL            : natural := 29;

    type rgb_ch_t is (R, G, B);
    type rgb_t is array (rgb_ch_t) of std_logic_vector(7 downto 0);

    type rgb_vector_t is array(4 downto 0) of rgb_t;

    type glyph_t is record
        fg                      : rgb_t;
        bg                      : rgb_t;
        glyph                   : std_logic_vector(4 downto 0);
    end record;

    type colors_t is record
        fg                      : rgb_t;
        bg                      : rgb_t;
    end record;

    type rom_t is array (natural range 0 to GLYPHS_CNT-1) of glyph_t;

    component vid_mem_glyph is
        port (
            clk                 : in std_logic;
            glyph_addr          : in std_logic_vector(9 downto 0);
            glyph_line          : out std_logic_vector(39 downto 0)
        );
    end component;

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

    impure function get_calc_layout return rom_t is
        variable layout : rom_t;
        variable idx : natural;
    begin
        idx := 0;
        for row in 0 to 7 loop
            for col in 0 to 11 loop
                layout(idx).glyph := std_logic_vector(to_unsigned(GL_NULL, 5));
                layout(idx).fg(R) := x"00";
                layout(idx).fg(G) := x"00";
                layout(idx).fg(B) := x"00";
                layout(idx).bg(R) := x"00";
                layout(idx).bg(G) := x"00";
                layout(idx).bg(B) := x"00";

                if (row = 1) then
                    if (col = 11) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_0, 5));
                    else
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_NULL, 5));
                    end if;
                    layout(idx).fg(R) := x"00";
                    layout(idx).fg(G) := x"FF";
                    layout(idx).fg(B) := x"00";
                    layout(idx).bg(R) := x"80";
                    layout(idx).bg(G) := x"80";
                    layout(idx).bg(B) := x"80";
                elsif (row = 3) then
                    if (col = 2) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_SHL, 5));
                    elsif (col = 3) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_AND, 5));
                    elsif (col = 4) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_ADD, 5));
                    elsif (col = 6) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_1, 5));
                    elsif (col = 7) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_2, 5));
                    elsif (col = 8) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_3, 5));
                    elsif (col = 9) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_A, 5));
                    elsif (col = 11) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_BACK, 5));
                    end if;

                    if (col=2 or col=3 or col=4 or col=11) then
                        layout(idx).fg(R) := x"FF";
                        layout(idx).fg(G) := x"FF";
                        layout(idx).fg(B) := x"FF";
                        layout(idx).bg(R) := x"FF";
                        layout(idx).bg(G) := x"99";
                        layout(idx).bg(B) := x"33";
                    elsif (col=6 or col=7 or col=8 or col=9) then
                        layout(idx).fg(R) := x"00";
                        layout(idx).fg(G) := x"FF";
                        layout(idx).fg(B) := x"00";
                        layout(idx).bg(R) := x"00";
                        layout(idx).bg(G) := x"00";
                        layout(idx).bg(B) := x"00";
                    end if;

                elsif (row = 4) then
                    if (col = 2) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_SHR, 5));
                    elsif (col = 3) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_OR, 5));
                    elsif (col = 4) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_SUB, 5));
                    elsif (col = 6) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_4, 5));
                    elsif (col = 7) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_5, 5));
                    elsif (col = 8) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_6, 5));
                    elsif (col = 9) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_B, 5));
                    elsif (col = 11) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_EQ, 5));
                    end if;

                    if (col=2 or col=3 or col=4 or col=11) then
                        layout(idx).fg(R) := x"FF";
                        layout(idx).fg(G) := x"FF";
                        layout(idx).fg(B) := x"FF";
                        layout(idx).bg(R) := x"FF";
                        layout(idx).bg(G) := x"99";
                        layout(idx).bg(B) := x"33";
                    elsif (col=6 or col=7 or col=8 or col=9) then
                        layout(idx).fg(R) := x"00";
                        layout(idx).fg(G) := x"FF";
                        layout(idx).fg(B) := x"00";
                        layout(idx).bg(R) := x"00";
                        layout(idx).bg(G) := x"00";
                        layout(idx).bg(B) := x"00";
                    end if;

                elsif (row = 5) then
                    if (col = 2) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_NEG, 5));
                    elsif (col = 3) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_XOR, 5));
                    elsif (col = 4) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_MUL, 5));
                    elsif (col = 6) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_7, 5));
                    elsif (col = 7) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_8, 5));
                    elsif (col = 8) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_9, 5));
                    elsif (col = 9) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_C, 5));
                    end if;

                    if (col=2 or col=3 or col=4) then
                        layout(idx).fg(R) := x"FF";
                        layout(idx).fg(G) := x"FF";
                        layout(idx).fg(B) := x"FF";
                        layout(idx).bg(R) := x"FF";
                        layout(idx).bg(G) := x"99";
                        layout(idx).bg(B) := x"33";
                    elsif (col=6 or col=7 or col=8 or col=9) then
                        layout(idx).fg(R) := x"00";
                        layout(idx).fg(G) := x"FF";
                        layout(idx).fg(B) := x"00";
                        layout(idx).bg(R) := x"00";
                        layout(idx).bg(G) := x"00";
                        layout(idx).bg(B) := x"00";
                    end if;

                elsif (row = 6) then
                    if (col = 2) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_NOT, 5));
                    elsif (col = 3) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_XOR, 5));
                    elsif (col = 4) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_DIV, 5));
                    elsif (col = 6) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_0, 5));
                    elsif (col = 7) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_F, 5));
                    elsif (col = 8) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_E, 5));
                    elsif (col = 9) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_D, 5));
                    end if;

                    if (col=2 or col=3 or col=4) then
                        layout(idx).fg(R) := x"FF";
                        layout(idx).fg(G) := x"FF";
                        layout(idx).fg(B) := x"FF";
                        layout(idx).bg(R) := x"FF";
                        layout(idx).bg(G) := x"99";
                        layout(idx).bg(B) := x"33";
                    elsif (col=6 or col=7 or col=8 or col=9) then
                        layout(idx).fg(R) := x"00";
                        layout(idx).fg(G) := x"FF";
                        layout(idx).fg(B) := x"00";
                        layout(idx).bg(R) := x"00";
                        layout(idx).bg(G) := x"00";
                        layout(idx).bg(B) := x"00";
                    end if;

                end if;

                idx := idx + 1;
            end loop;
        end loop;

        return layout;
    end function;

    signal x                    : integer range 0 to MAX_H-1;
    signal y                    : integer range 0 to MAX_V-1;

    signal event_tvalid         : std_logic;
    signal event_tready         : std_logic;
    signal event_tlast          : std_logic;

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
    signal wr_reset_addr        : std_logic;

    signal glyph_addr           : std_logic_vector(9 downto 0);
    signal glyph_line           : std_logic_vector(39 downto 0);
    signal glyph_line_buf       : std_logic_vector(39 downto 0);
    signal glyph_dot_col_rev    : natural range 0 to 39;
    signal glyph_dot_row        : natural range 0 to 33;
    signal glyph_idx            : natural range 0 to GLYPHS_CNT-1;
    signal glyph_col            : natural range 0 to 11;
    signal glyph_col_offset     : natural range 0 to GLYPHS_CNT-1;
    signal glyph_row            : natural range 0 to 7;

    signal glyph_q              : glyph_t;
    signal glyph_buf            : glyph_t;

    signal addr_base            : natural range 0 to GLYPHS_CNT*34-1;
    signal addr                 : natural range 0 to GLYPHS_CNT*34-1;

    signal colors1              : colors_t;
    signal colors2              : colors_t;
    signal colors3              : colors_t;

    signal layout_ram           : rom_t := get_calc_layout;

    signal upd_req_tvalid       : std_logic;

    signal glyph_upd            : glyph_t;

begin

    vid_mem_glyph_inst : vid_mem_glyph port map (
        clk         => clk,
        glyph_addr  => glyph_addr,
        glyph_line  => glyph_line
    );

    event_tvalid    <= event_s_tvalid;
    event_s_tready  <= event_tready;
    event_tlast     <= event_s_tlast;

    event_m_tvalid  <= '1' when event_tready = '0' and ddr_data_tvalid = '1' and ddr_data_tready = '1' and ddr_data_tlast = '1' else '0';

    wr_m_tvalid     <= wr_tvalid;
    wr_tready       <= wr_m_tready;
    wr_m_tlast      <= wr_tlast;
    wr_m_tdata      <= to_slv(wr_tdata);
    wr_m_taddr      <= std_logic_vector(to_unsigned(wr_taddr, 26));

    glyph_addr      <= std_logic_vector(to_unsigned(addr, 10));

    ddr_data_tready <= '1' when wr_tvalid = '0' or (wr_tvalid = '1' and wr_tready = '1') else '0';
    pixel_tready    <= '1' when ddr_data_tvalid = '0' or (ddr_data_tvalid = '1' and ddr_data_tready = '1') else '0';
    req_tready      <= '1' when pixel_tvalid = '0' or (pixel_tvalid = '1' and pixel_tready = '1') else '0';

    start_cnt_process: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                start_cnt <= "0001";
            else
                start_cnt <= start_cnt(2 downto 0) & '0';
            end if;
        end if;
    end process;

    glyph_upd.glyph <= std_logic_vector(to_unsigned(GL_OR, 5));
    glyph_upd.fg(R) <= x"00";
    glyph_upd.fg(G) <= x"FF";
    glyph_upd.fg(B) <= x"00";
    glyph_upd.bg(R) <= x"80";
    glyph_upd.bg(G) <= x"80";
    glyph_upd.bg(B) <= x"80";

    upd_layout: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                upd_req_tvalid <= '0';
                event_tready <= '1';
            else
                if (event_tvalid = '1' and event_tready = '1' and event_tlast = '1') then
                    upd_req_tvalid <= '1';
                else
                    upd_req_tvalid <= '0';
                end if;

                if (event_tvalid = '1' and event_tready = '1' and event_tlast = '1') then
                    event_tready <= '0';
                elsif (event_tready = '0' and ddr_data_tvalid = '1' and ddr_data_tready = '1' and ddr_data_tlast = '1') then
                    event_tready <= '1';
                end if;

                if (event_tvalid = '1' and event_tready = '1') then
                    layout_ram(0) <= glyph_upd;
                end if;
            end if;
        end if;
    end process;

    forming_pixel_values: process (clk) begin
        if rising_edge(clk) then
            if (resetn = '0') then
                req_tvalid <= '0';
                pixel_tvalid <= '0';
                pixel_tlast <= '0';
                x <= 0;
                y <= 0;
                addr <= 0;
                addr_base <= 0;
                glyph_dot_row <= 0;
                glyph_dot_col_rev <= 39;
                glyph_col <= 0;
                glyph_col_offset <= 0;
                glyph_idx <= 0;
            else
                if (start_cnt(3) = '1' or upd_req_tvalid = '1') then
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

                if req_tvalid = '1' and req_tready = '1' and x = 478 then
                    if (glyph_dot_row = 33) then
                        glyph_dot_row <= 0;
                    else
                        glyph_dot_row <= glyph_dot_row + 1;
                    end if;
                end if;

                if req_tvalid = '1' and req_tready = '1' then
                    if (glyph_dot_col_rev = 7 and glyph_col = 11 and glyph_dot_row = 33) then
                        if (glyph_col_offset = GLYPHS_CNT-12) then
                            glyph_col_offset <= 0;
                        else
                            glyph_col_offset <= glyph_col_offset + 12;
                        end if;
                    end if;
                end if;

                if req_tvalid = '1' and req_tready = '1' then
                    if (glyph_dot_col_rev = 7) then
                        if (glyph_col = 11) then
                            glyph_col <= 0;
                        else
                            glyph_col <= glyph_col + 1;
                        end if;
                    end if;
                end if;

                if (req_tvalid = '1' and req_tready = '1') then
                    if (glyph_dot_col_rev = 0) then
                        glyph_dot_col_rev <= 39;
                    else
                        glyph_dot_col_rev <= glyph_dot_col_rev - 1;
                    end if;
                end if;

                if req_tvalid = '1' and req_tready = '1' then
                    glyph_idx <= glyph_col + glyph_col_offset;
                end if;
            end if;


            if (req_tvalid = '1' and req_tready = '1') then
                --0
                glyph_q <= layout_ram(glyph_idx);
                --1
                glyph_buf <= glyph_q;
                --2
                addr_base <= conv_integer(glyph_buf.glyph & "00000") + conv_integer(glyph_buf.glyph & "0");
                colors1.fg <= glyph_buf.fg;
                colors1.bg <= glyph_buf.bg;
                --3
                addr <= addr_base + glyph_dot_row;
                colors2 <= colors1;
                --4
                glyph_line_buf <= glyph_line;
                colors3 <= colors2;
                --5
                if (x = 0 or y = 0) then
                    pixel_tdata(R) <= x"00";
                    pixel_tdata(G) <= x"FF";
                    pixel_tdata(B) <= x"00";
                elsif (x = MAX_H-1 or y = MAX_V-1) then
                    pixel_tdata(R) <= x"00";
                    pixel_tdata(G) <= x"FF";
                    pixel_tdata(B) <= x"00";
                elsif glyph_line_buf(glyph_dot_col_rev) = '1' then
                    pixel_tdata <= colors3.fg;
                else
                    pixel_tdata <= colors3.bg;
                end if;
            end if;

        end if;
    end process;

    packing_data_for_ddr_process : process (clk) begin
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

    writing_data_to_ddr_fifo: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                wr_tvalid <= '0';
                wr_fifo_cnt <= 0;
                wr_taddr <= 0;
                wr_tlast <= '0';
                wr_reset_addr <= '0';
            else
                if (ddr_data_tvalid = '1' and ddr_data_tready = '1') then
                    wr_tvalid <= '1';
                elsif wr_tready = '1' then
                    wr_tvalid <= '0';
                end if;

                if (ddr_data_tvalid = '1' and ddr_data_tready = '1') then
                    if (wr_fifo_cnt = FIFO_LEN-1) then
                        wr_tlast <= '1';
                    else
                        wr_tlast <= ddr_data_tlast;
                    end if;
                end if;

                if (ddr_data_tvalid = '1' and ddr_data_tready = '1') then
                    wr_reset_addr <= ddr_data_tlast;
                end if;

                if (ddr_data_tvalid = '1' and ddr_data_tready = '1') then
                    if (wr_fifo_cnt = FIFO_LEN-1) then
                        wr_fifo_cnt <= 0;
                    else
                        wr_fifo_cnt <= wr_fifo_cnt + 1;
                    end if;
                end if;

                if (wr_tvalid = '1' and wr_tready = '1' and wr_tlast = '1') then
                    if (wr_reset_addr = '1') then
                        wr_taddr <= 0;
                    else
                        wr_taddr <= wr_taddr + FIFO_LEN;
                    end if;
                end if;
            end if;

            if ddr_data_tvalid = '1' and ddr_data_tready = '1' then
                wr_tdata <= ddr_data_tdata;
            end if;

        end if;
    end process;

end architecture;
