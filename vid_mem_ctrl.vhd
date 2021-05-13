library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;
use ieee.math_real.all;

entity vid_mem_ctrl is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        event_s_tvalid          : in std_logic;
        event_s_tready          : out std_logic;
        event_s_tcmd            : in std_logic;
        event_s_tdata           : in std_logic_vector(31 downto 0);
        event_s_terror          : in std_logic;

        ctrl_m_tvalid           : out std_logic;
        ctrl_m_tready           : in std_logic;
        ctrl_m_tdata            : out std_logic_vector(63 downto 0);
        ctrl_m_tlast            : out std_logic

    );
end entity vid_mem_ctrl;

architecture rtl of vid_mem_ctrl is

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
    constant GL_SHL             : natural := 26;
    constant GL_SHR             : natural := 27;
    constant GL_EQ              : natural := 28;
    constant GL_BACK            : natural := 29;
    constant GL_NULL            : natural := 30;

    constant GLYPHS_CNT         : natural := 12*8;
    constant CMD_KEY_UP         : std_logic := '0';
    constant CMD_UPD_VAL        : std_logic := '1';

    constant DELAY_MAX          : natural := 25_000_000;

    type rgb_ch_t is (R, G, B);
    type rgb_t is array (rgb_ch_t) of std_logic_vector(7 downto 0);

    type glyph_cmd_t is record
        fg                      : rgb_t;
        bg                      : rgb_t;
        glyph                   : std_logic_vector(7 downto 0);
        pos                     : std_logic_vector(7 downto 0);
    end record;

    type rom_t is array (natural range 0 to GLYPHS_CNT-1) of glyph_cmd_t;

    signal start_cnt            : std_logic_vector(3 downto 0);

    signal init_cmd_tvalid      : std_logic;
    signal init_cmd_tready      : std_logic;
    signal init_cmd_taddr       : natural range 0 to GLYPHS_CNT-1;
    signal init_cmd_tlast       : std_logic;

    signal init_data_tvalid     : std_logic;
    signal init_data_tready     : std_logic;
    signal init_data_tdata      : std_logic_vector(63 downto 0);
    signal init_data_tlast      : std_logic;
    signal init_data_struct     : glyph_cmd_t;

    signal init_done            : std_logic;

    signal event_s_tready_comb  : std_logic;

    signal event_tvalid         : std_logic;
    signal event_tready         : std_logic;
    signal event_tdata          : std_logic_vector(63 downto 0);
    signal event_tlast          : std_logic;
    signal event_cmd            : std_logic;
    signal event_error          : std_logic;
    signal event_data           : std_logic_vector(31 downto 0);
    signal event_counter        : natural range 0 to GLYPHS_CNT-1;

    signal delay_tvalid         : std_logic;
    signal delay_tready         : std_logic;
    signal delay_tdata          : std_logic_vector(63 downto 0);
    signal delay_tlast          : std_logic;
    signal delay_counter        : natural range 0 to DELAY_MAX;

    signal ctrl_tvalid          : std_logic;
    signal ctrl_tready          : std_logic;
    signal ctrl_tdata           : std_logic_vector(63 downto 0);
    signal ctrl_tlast           : std_logic;

    impure function get_calc_layout return rom_t is
        variable layout : rom_t;
        variable idx : natural;
    begin
        idx := 0;
        for row in 0 to 7 loop
            for col in 0 to 11 loop
                layout(idx).glyph := std_logic_vector(to_unsigned(GL_NULL, 8));
                layout(idx).pos := std_logic_vector(to_unsigned(idx, 8));
                layout(idx).fg(R) := x"00";
                layout(idx).fg(G) := x"00";
                layout(idx).fg(B) := x"00";
                layout(idx).bg(R) := x"00";
                layout(idx).bg(G) := x"00";
                layout(idx).bg(B) := x"00";

                if (row = 1) then
                    if (col = 11) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_0, 8));
                    else
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_NULL, 8));
                    end if;
                    layout(idx).fg(R) := x"00";
                    layout(idx).fg(G) := x"FF";
                    layout(idx).fg(B) := x"00";
                    layout(idx).bg(R) := x"00";
                    layout(idx).bg(G) := x"00";
                    layout(idx).bg(B) := x"00";
                elsif (row = 3) then
                    if (col = 2) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_SHL, 8));
                    elsif (col = 3) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_AND, 8));
                    elsif (col = 4) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_ADD, 8));
                    elsif (col = 6) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_1, 8));
                    elsif (col = 7) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_2, 8));
                    elsif (col = 8) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_3, 8));
                    elsif (col = 9) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_A, 8));
                    elsif (col = 11) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_BACK, 8));
                    end if;

                    if (col=2 or col=3 or col=4 or col=11) then
                        layout(idx).fg(R) := x"FF";
                        layout(idx).fg(G) := x"00";
                        layout(idx).fg(B) := x"00";
                        layout(idx).bg(R) := x"00";
                        layout(idx).bg(G) := x"00";
                        layout(idx).bg(B) := x"00";
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
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_SHR, 8));
                    elsif (col = 3) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_OR, 8));
                    elsif (col = 4) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_SUB, 8));
                    elsif (col = 6) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_4, 8));
                    elsif (col = 7) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_5, 8));
                    elsif (col = 8) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_6, 8));
                    elsif (col = 9) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_B, 8));
                    elsif (col = 11) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_EQ, 8));
                    end if;

                    if (col=2 or col=3 or col=4 or col=11) then
                        layout(idx).fg(R) := x"FF";
                        layout(idx).fg(G) := x"00";
                        layout(idx).fg(B) := x"00";
                        layout(idx).bg(R) := x"00";
                        layout(idx).bg(G) := x"00";
                        layout(idx).bg(B) := x"00";
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
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_NEG, 8));
                    elsif (col = 3) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_XOR, 8));
                    elsif (col = 4) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_MUL, 8));
                    elsif (col = 6) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_7, 8));
                    elsif (col = 7) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_8, 8));
                    elsif (col = 8) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_9, 8));
                    elsif (col = 9) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_C, 8));
                    end if;

                    if (col=2 or col=3 or col=4) then
                        layout(idx).fg(R) := x"FF";
                        layout(idx).fg(G) := x"00";
                        layout(idx).fg(B) := x"00";
                        layout(idx).bg(R) := x"00";
                        layout(idx).bg(G) := x"00";
                        layout(idx).bg(B) := x"00";
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
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_NOT, 8));
                    elsif (col = 3) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_XOR, 8));
                    elsif (col = 4) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_MUL, 8));
                    elsif (col = 6) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_0, 8));
                    elsif (col = 7) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_F, 8));
                    elsif (col = 8) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_E, 8));
                    elsif (col = 9) then
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_D, 8));
                    end if;

                    if (col=2 or col=3 or col=4) then
                        layout(idx).fg(R) := x"FF";
                        layout(idx).fg(G) := x"00";
                        layout(idx).fg(B) := x"00";
                        layout(idx).bg(R) := x"00";
                        layout(idx).bg(G) := x"00";
                        layout(idx).bg(B) := x"00";
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

    signal layout_rom           : rom_t := get_calc_layout;

begin

    event_s_tready_comb<= '1' when event_tvalid = '0' or (event_tvalid = '1' and event_tready = '1' and event_tlast = '1');
    event_s_tready <= event_s_tready_comb;

    init_cmd_tready <= '1' when init_data_tvalid = '0' or (init_data_tvalid = '1' and init_data_tready = '1') else '0';
    init_data_tready <= '1' when ctrl_tvalid = '0' or (ctrl_tvalid = '1' and ctrl_tready = '1') else '0';
    event_tready <= '1' when init_done = '1' and (ctrl_tvalid = '0' or (ctrl_tvalid = '1' and ctrl_tready = '1')) else '0';
    delay_tready <= '1' when (ctrl_tvalid = '0' or (ctrl_tvalid = '1' and ctrl_tready = '1')) else '0';

    ctrl_m_tvalid <= ctrl_tvalid;
    ctrl_tready <= ctrl_m_tready;
    ctrl_m_tlast <= ctrl_tlast;
    ctrl_m_tdata <= ctrl_tdata;

    start_cnt_process: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                start_cnt <= "0001";
            else
                start_cnt <= start_cnt(2 downto 0) & '0';
            end if;
        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                init_cmd_tvalid <= '0';
                init_cmd_tlast <= '0';
                init_cmd_taddr <= 0;
                init_done <= '0';
            else

                if start_cnt(3) = '1' then
                    init_cmd_tvalid <= '1';
                elsif (init_cmd_tvalid = '1' and init_cmd_tready = '1' and init_cmd_taddr = GLYPHS_CNT-1) then
                    init_cmd_tvalid <= '0';
                end if;

                if (init_cmd_tvalid = '1' and init_cmd_tready = '1' and init_cmd_taddr = GLYPHS_CNT-2) then
                    init_cmd_tlast <= '1';
                else
                    init_cmd_tlast <= '0';
                end if;

                if (init_cmd_tvalid = '1' and init_cmd_tready = '1' and init_cmd_taddr = GLYPHS_CNT-1) then
                    init_done <= '1';
                end if;

                if (init_cmd_tvalid = '1' and init_cmd_tready = '1') then
                    if (init_cmd_taddr = GLYPHS_CNT-1) then
                        init_cmd_taddr <= 0;
                    else
                        init_cmd_taddr <= init_cmd_taddr + 1;
                    end if;
                end if;

            end if;
        end if;
    end process;

    init_data_tdata(63 downto 56) <= init_data_struct.fg(R);
    init_data_tdata(55 downto 48) <= init_data_struct.fg(G);
    init_data_tdata(47 downto 40) <= init_data_struct.fg(B);
    init_data_tdata(39 downto 32) <= init_data_struct.bg(R);
    init_data_tdata(31 downto 24) <= init_data_struct.bg(G);
    init_data_tdata(23 downto 16) <= init_data_struct.bg(B);
    init_data_tdata(15 downto 8) <= init_data_struct.glyph;
    init_data_tdata(7 downto 0) <= init_data_struct.pos;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                init_data_tvalid <= '0';
                init_data_tlast <= '0';
            else

                if (init_cmd_tvalid = '1' and init_cmd_tready = '1') then
                    init_data_tvalid <= '1';
                elsif (init_data_tready = '1') then
                    init_data_tvalid <= '0';
                end if;

                if (init_cmd_tvalid = '1' and init_cmd_tready = '1') then
                    init_data_tlast <= init_cmd_tlast;
                end if;

            end if;

            if (init_cmd_tvalid = '1' and init_cmd_tready = '1') then
                init_data_struct <= layout_rom(init_cmd_taddr);
            end if;

        end if;

    end process;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                event_tvalid <= '0';
                event_tlast <= '0';
                event_counter <= 12;
            else
                if event_s_tvalid = '1' and event_s_tready_comb = '1' then
                    event_cmd <= event_s_tcmd;
                    event_error <= event_s_terror;
                    event_data <= event_s_tdata;
                end if;

                if event_s_tvalid = '1' and event_s_tready_comb = '1' then
                    event_tvalid <= '1';
                elsif (event_tvalid = '1' and event_tready = '1' and event_tlast = '1') then
                    event_tvalid <= '0';
                end if;

                if (event_tvalid = '1' and event_tready = '1') then
                    if (event_cmd = CMD_UPD_VAL and event_counter = 23) then
                        event_tlast <= '1';
                    elsif (event_cmd = CMD_KEY_UP) then
                        event_tlast <= '1';
                    else
                        event_tlast <= '0';
                    end if;
                else
                    event_tlast <= '0';
                end if;

                if (event_tvalid = '1' and event_tready = '1' and event_cmd = CMD_UPD_VAL) then
                    if (event_counter = 23) then
                        event_counter <= 12;
                    else
                        event_counter <= event_counter + 1;
                    end if;
                end if;

            end if;

            if (event_tvalid = '1' and event_tready = '1') then
                --init_data_tdata(7 downto 0) :=
            end if;

        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                delay_counter <= 0;
            else

                if (event_s_tvalid = '1' and event_s_tready_comb = '1') then
                    delay_counter <= 1;
                elsif (delay_counter = DELAY_MAX) then
                    delay_counter <= 0;
                elsif (delay_counter > 0) then
                    delay_counter <= delay_counter + 1;
                end if;

            end if;

        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                ctrl_tvalid <= '0';
                ctrl_tlast <= '0';
            else

                if (init_data_tvalid = '1' and init_data_tready = '1') then
                    ctrl_tvalid <= '1';
                elsif (event_tvalid = '1' and event_tready = '1') then
                    ctrl_tvalid <= '1';
                elsif (ctrl_tready = '1') then
                    ctrl_tvalid <= '0';
                end if;

                if (init_data_tvalid = '1' and init_data_tready = '1') then
                    ctrl_tlast <= init_data_tlast;
                elsif (event_tvalid = '1' and event_tready = '1') then
                    ctrl_tlast <= event_tlast;
                end if;

            end if;

            if (init_data_tvalid = '1' and init_data_tready = '1') then
                ctrl_tdata <= init_data_tdata;
            elsif (event_tvalid = '1' and event_tready = '1') then
                ctrl_tdata <= event_tdata;
            end if;

        end if;
    end process;

end architecture;