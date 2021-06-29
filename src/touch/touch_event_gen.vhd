library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;
use ieee.math_real.all;

entity touch_event_gen is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        touch_s_tvalid          : in std_logic;
        touch_s_tdata           : in std_logic_vector(11 downto 0);
        touch_s_tuser           : in std_logic_vector(1 downto 0);

        event_m_tvalid          : out std_logic;
        event_m_tdata           : out std_logic_vector(7 downto 0)
    );
end entity touch_event_gen;

architecture rtl of touch_event_gen is

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

    constant SIZE_PER_SYMBOL_X  : positive := positive(round(real(3996.0/12)));
    constant SIZE_PER_SYMBOL_Y  : positive := positive(round(real(4096.0/8)));
    constant SAMPLE_X           : std_logic_vector(1 downto 0) := "00";
    constant SAMPLE_Y           : std_logic_vector(1 downto 0) := "01";
    constant SAMPLE_Z           : std_logic_vector(1 downto 0) := "10";

    component axis_div_u is
        generic (
            MAX_WIDTH           : natural := 16;
            USER_WIDTH          : natural := 16
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            div_s_tvalid        : in std_logic;
            div_s_tready        : out std_logic;
            div_s_tdata         : in std_logic_vector(2*MAX_WIDTH-1 downto 0);
            div_s_tuser         : in std_logic_vector(USER_WIDTH-1 downto 0);

            div_m_tvalid        : out std_logic;
            div_m_tready        : in std_logic;
            div_m_tdata         : out std_logic_vector(2*MAX_WIDTH-1 downto 0);
            div_m_tuser         : out std_logic_vector(USER_WIDTH-1 downto 0)
        );
    end component;

    component timer is
        port (
            clk_100             : in std_logic;

            cmd_s_tvalid        : in std_logic;
            cmd_s_tdata         : in std_logic_vector(15 downto 0);
            cmd_s_tuser         : in std_logic;

            pulse1ms_m_tvalid   : out std_logic;
            pulse_m_tvalid      : out std_logic
        );
    end component;

    signal div_tvalid           : std_logic;
    signal div_tdata            : std_logic_vector(23 downto 0);
    signal div_tuser            : std_logic_vector(1 downto 0);

    signal div_res_tvalid       : std_logic;
    signal div_res_tdata        : std_logic_vector(23 downto 0);
    signal div_res_tuser        : std_logic_vector(1 downto 0);

    signal x_pos                : std_logic_vector(3 downto 0);
    signal y_pos                : std_logic_vector(3 downto 0);

    signal col                  : natural range 0 to 11;
    signal row                  : natural range 0 to 7;
    signal glyph                : natural range 0 to 29;

    signal event_tvalid         : std_logic;
    signal event_cnt            : natural range 0 to 15;
    signal event_glyph          : natural range 0 to 29;

    signal timer_cmd_tvalid     : std_logic;
    signal pulse_tvalid         : std_logic;

    signal event_mask           : std_logic;

begin

    col <= to_integer(unsigned(x_pos));
    row <= to_integer(unsigned(y_pos));

    axis_div_u_inst : axis_div_u generic map (
        MAX_WIDTH       => 12,
        USER_WIDTH      => 2
    ) port map (
        clk             => clk,
        resetn          => resetn,
        div_s_tvalid    => div_tvalid,
        div_s_tready    => open,
        div_s_tdata     => div_tdata,
        div_s_tuser     => div_tuser,
        div_m_tvalid    => div_res_tvalid,
        div_m_tready    => '1',
        div_m_tdata     => div_res_tdata,
        div_m_tuser     => div_res_tuser
    );

    guard_timer_inst : timer port map (
        clk_100             => clk,

        cmd_s_tvalid        => timer_cmd_tvalid,
        cmd_s_tdata         => x"00fa", --0.25 sec
        cmd_s_tuser         => '1',

        pulse1ms_m_tvalid   => open,
        pulse_m_tvalid      => pulse_tvalid
    );

    process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                div_tvalid <= '0';
            else
                div_tvalid <= touch_s_tvalid;
            end if;

            if (touch_s_tvalid = '1' and touch_s_tuser = SAMPLE_Z) then
                if (touch_s_tdata(11 downto 8) /= x"0") then
                    div_tdata(23 downto 12) <= x"FFF";
                else
                    div_tdata(23 downto 12) <= x"000";
                end if;
                div_tdata(11 downto 0) <= x"001";
            elsif (touch_s_tvalid = '1' and touch_s_tuser = SAMPLE_Y) then
                div_tdata(23 downto 12) <= touch_s_tdata;
                div_tdata(11 downto 0) <= std_logic_vector(to_unsigned(SIZE_PER_SYMBOL_Y, 12));
            elsif (touch_s_tvalid = '1') then
                div_tdata(23 downto 12) <= touch_s_tdata;
                div_tdata(11 downto 0) <= std_logic_vector(to_unsigned(SIZE_PER_SYMBOL_X, 12));
            end if;

            if (touch_s_tvalid = '1') then
                div_tuser <= touch_s_tuser;
            end if;

        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                event_tvalid <= '0';
            else
                if (div_res_tvalid = '1' and div_res_tuser = SAMPLE_Z and div_res_tdata(23 downto 12) = x"FFF") then
                    event_tvalid <= '1';
                else
                    event_tvalid <= '0';
                end if;
            end if;

            if (div_res_tvalid = '1' and div_res_tuser = SAMPLE_X) then
                x_pos <= div_res_tdata(15 downto 12);
            end if;

            if (div_res_tvalid = '1' and div_res_tuser = SAMPLE_Y) then
                y_pos <= div_res_tdata(15 downto 12);
            end if;

            case row is
                when 3 =>
                    case col is
                        when 2 => glyph <= GL_SHL;
                        when 3 => glyph <= GL_AND;
                        when 4 => glyph <= GL_ADD;
                        when 6 => glyph <= GL_1;
                        when 7 => glyph <= GL_2;
                        when 8 => glyph <= GL_3;
                        when 9 => glyph <= GL_A;
                        when 11 => glyph <= GL_BACK;
                        when others => glyph <= GL_NULL;
                    end case;
                when 4 =>
                    case col is
                        when 2 => glyph <= GL_SHR;
                        when 3 => glyph <= GL_OR;
                        when 4 => glyph <= GL_SUB;
                        when 6 => glyph <= GL_4;
                        when 7 => glyph <= GL_5;
                        when 8 => glyph <= GL_6;
                        when 9 => glyph <= GL_B;
                        when 11 => glyph <= GL_EQ;
                        when others => glyph <= GL_NULL;
                    end case;
                when 5 =>
                    case col is
                        when 2 => glyph <= GL_NEG;
                        when 3 => glyph <= GL_XOR;
                        when 4 => glyph <= GL_MUL;
                        when 6 => glyph <= GL_7;
                        when 7 => glyph <= GL_8;
                        when 8 => glyph <= GL_9;
                        when 9 => glyph <= GL_C;
                        when others => glyph <= GL_NULL;
                    end case;
                when 6 =>
                    case col is
                        when 2 => glyph <= GL_NOT;
                        when 3 => glyph <= GL_XOR;
                        when 4 => glyph <= GL_DIV;
                        when 6 => glyph <= GL_0;
                        when 7 => glyph <= GL_F;
                        when 8 => glyph <= GL_E;
                        when 9 => glyph <= GL_D;
                        when others => glyph <= GL_NULL;
                    end case;
                when others => glyph <= GL_NULL;
            end case;

        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                event_m_tvalid <= '0';
                event_cnt <= 0;
                event_mask <= '0';
            else

                if (event_tvalid = '1' and event_mask = '0') then
                    if event_cnt = 0 or (event_cnt > 0 and event_glyph = glyph) then
                        event_cnt <= (event_cnt + 1) mod 16;
                    else
                        event_cnt <= 0;
                    end if;
                end if;

                if (event_tvalid = '1' and event_cnt = 15 and event_mask = '0') then
                    event_m_tvalid <= '1';
                    timer_cmd_tvalid <= '1';
                else
                    event_m_tvalid <= '0';
                    timer_cmd_tvalid <= '0';
                end if;

                if (event_tvalid = '1' and event_mask = '0' and event_cnt = 15) then
                    event_mask <= '1';
                elsif(pulse_tvalid = '1') then
                    event_mask <= '0';
                end if;

            end if;

            if (event_tvalid = '1' and event_mask = '0' and event_cnt = 0) then
                event_glyph <= glyph;
            end if;

            if (event_tvalid = '1' and event_mask = '0' and event_cnt = 15) then
                event_m_tdata <= std_logic_vector(to_unsigned(event_glyph, 8));
            end if;

        end if;
    end process;

end architecture;
