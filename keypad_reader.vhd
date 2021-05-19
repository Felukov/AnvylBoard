library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity keypad_reader is
    port (
        clk                             : in std_logic;
        resetn                          : in std_logic;

        keypd_row                       : in std_logic_vector(3 downto 0);
        keypd_col                       : out std_logic_vector(3 downto 0);

        key_m_tvalid                    : out std_logic;
        key_m_tdata                     : out std_logic_vector(3 downto 0)
    );
end entity keypad_reader;

architecture rtl of keypad_reader is

    component timer is
        port (
            clk_100                     : in std_logic;

            cmd_s_tvalid                : in std_logic;
            cmd_s_tdata                 : in std_logic_vector(15 downto 0);
            cmd_s_tuser                 : in std_logic;

            pulse1ms_m_tvalid           : out std_logic;
            pulse_m_tvalid              : out std_logic
        );
    end component;

    signal pulse1ms_tvalid              : std_logic;
    signal guard_interval_tvalid        : std_logic;
    signal active_col                   : std_logic_vector(3 downto 0);
    signal key_tvalid                   : std_logic;
    signal key_tdata                    : std_logic_vector(3 downto 0);
    signal key_guard_fl                 : std_logic;

begin

    guard_timer_inst : timer port map (
        clk_100             => clk,

        cmd_s_tvalid        => key_tvalid,
        cmd_s_tdata         => x"00fa", --0.25 sec
        cmd_s_tuser         => '1',

        pulse1ms_m_tvalid   => pulse1ms_tvalid,
        pulse_m_tvalid      => guard_interval_tvalid
    );

    keypd_col <= active_col;
    key_m_tvalid <= key_tvalid;
    key_m_tdata <= key_tdata;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                active_col <= "0111";
            else
                if (pulse1ms_tvalid = '1') then
                    active_col <= active_col(0) & active_col(3 downto 1);
                end if;
            end if;
        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                key_tvalid <= '0';
                key_guard_fl <= '0';
            else
                if (key_guard_fl = '0' and pulse1ms_tvalid = '1') then
                    case active_col is
                        when "1110" =>
                            case keypd_row is
                                when "1110" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"1";
                                when "1101" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"4";
                                when "1011" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"7";
                                when "0111" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"0";
                                when others =>
                                    key_tvalid <= '0';
                            end case;
                        when "1101" =>
                            case keypd_row is
                                when "1110" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"2";
                                when "1101" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"5";
                                when "1011" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"8";
                                when "0111" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"F";
                                when others =>
                                    key_tvalid <= '0';
                            end case;
                        when "1011" =>
                            case keypd_row is
                                when "1110" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"3";
                                when "1101" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"6";
                                when "1011" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"9";
                                when "0111" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"E";
                                when others =>
                                    key_tvalid <= '0';
                            end case;
                        when "0111" =>
                            case keypd_row is
                                when "1110" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"A";
                                when "1101" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"B";
                                when "1011" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"C";
                                when "0111" =>
                                    key_tvalid <= '1';
                                    key_guard_fl <= '1';
                                    key_tdata <= x"D";
                                when others =>
                                    key_tvalid <= '0';
                            end case;
                        when others =>
                            key_tvalid <= '0';
                    end case;
                elsif (key_guard_fl = '1' and guard_interval_tvalid = '1') then
                    key_guard_fl <= '0';
                    key_tvalid <= '0';
                else
                    key_tvalid <= '0';
                end if;

            end if;
        end if;
    end process;

end architecture;