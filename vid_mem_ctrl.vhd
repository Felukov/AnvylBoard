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

        -- event_key_up_s_tvalid   : in std_logic;
        -- event_key_up_s_tready   : out std_logic;
        -- event_key_up_s_tdata    : in std_logic_vector(7 downto 0);

        -- event_upd_val_s_tvalid  : in std_logic;
        -- event_upd_val_s_tready  : out std_logic;
        -- event_upd_val_s_tdata   : in std_logic_vector(32 downto 0);

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
    constant GL_INV             : natural := 25;
    constant GL_SHL             : natural := 26;
    constant GL_SHR             : natural := 27;
    constant GL_EQ              : natural := 28;
    constant GL_BACK            : natural := 29;
    constant GL_NULL            : natural := 30;

    type rgb_ch_t is (R, G, B);
    type rgb_t is array (rgb_ch_t) of std_logic_vector(7 downto 0);

    type glyph_cmd_t is record
        fg                      : rgb_t;
        bg                      : rgb_t;
        glyph                   : std_logic_vector(7 downto 0);
        pos                     : std_logic_vector(7 downto 0);
    end record;

    type calc_layout_t is array (natural range 0 to 12*8-1) of glyph_cmd_t;

    type ctrl_state_t is (INIT, IDLE, KEY_UP, UPD_VAL);

    signal start_cnt            : std_logic_vector(3 downto 0);
    signal state                : ctrl_state_t;

    impure function calc_layout return calc_layout_t is
        variable layout : calc_layout_t;
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
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_INV, 8));
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
                        layout(idx).glyph := std_logic_vector(to_unsigned(GL_INV, 8));
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

begin

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
                state <= INIT;
            else
                case state is
                    when INIT =>
                        if (start_cnt(3) = '1') then

                        end if;

                    when others =>
                        null;

                end case;
            end if;
        end if;
    end process;

end architecture;