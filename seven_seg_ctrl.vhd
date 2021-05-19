library UNISIM;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity seven_seg_ctrl is
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        seg                 : out std_logic_vector(7 downto 0);
        an                  : out std_logic_vector(5 downto 0)
    );
end entity seven_seg_ctrl;

architecture rtl of seven_seg_ctrl is

    type data_t is array (natural range 0 to 5) of std_logic_vector(3 downto 0);


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

    signal init_tvalid                  : std_logic;
    signal pulse1ms_m_tvalid            : std_logic;
    signal pulse_tvalid                 : std_logic;

    signal sel                          : natural range 0 to 5;
    signal data                         : data_t;

    signal seg_next                     : std_logic_vector(7 downto 0);
    signal an_next                      : std_logic_vector(5 downto 0);

begin

    timer_inst : timer port map (
        clk_100             => clk,

        cmd_s_tvalid        => init_tvalid,
        cmd_s_tdata         => x"0001",
        cmd_s_tuser         => '0',

        pulse1ms_m_tvalid   => pulse1ms_m_tvalid,
        pulse_m_tvalid      => pulse_tvalid
    );

    init_process: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                init_tvalid <= '1';
            else
                init_tvalid <= '0';
            end if;
        end if;
    end process;

    sel_counter : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                sel <= 0;
            elsif (pulse_tvalid = '1') then
                if (sel = 5) then
                    sel <= 0;
                else
                    sel <= sel + 1;
                end if;
            end if;
        end if;
    end process;

    data(0) <= x"A";
    data(1) <= x"B";
    data(2) <= x"C";
    data(3) <= x"D";
    data(4) <= x"E";
    data(5) <= x"F";

    with data(sel) select seg_next(6 downto 0) <=
        "1000000" when "0000",   --0
        "1111001" when "0001",   --1
        "0100100" when "0010",   --2
        "0110000" when "0011",   --3
        "0011001" when "0100",   --4
        "0010010" when "0101",   --5
        "0000010" when "0110",   --6
        "1111000" when "0111",   --7
        "0000000" when "1000",   --8
        "0010000" when "1001",   --9
        "0001000" when "1010",   --A
        "0000011" when "1011",   --b
        "1000110" when "1100",   --C
        "0100001" when "1101",   --d
        "0000110" when "1110",   --E
        "0001110" when "1111",   --F
        "0111111" when others;

    seg_next(7) <= '0'; -- dot point of 7-seg display

    an_next <=
        "111110" when sel = 0 else
        "111101" when sel = 1 else
        "111011" when sel = 2 else
        "110111" when sel = 3 else
        "101111" when sel = 4 else
        "011111" when sel = 5 else
        "111111";

    process (clk) begin
        if rising_edge(clk) then
            seg <= not seg_next;
            an <= not an_next;
        end if;
    end process;

end architecture;