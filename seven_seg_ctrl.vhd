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

        data_s_tvalid       : in std_logic;
        data_s_taddr        : in std_logic_vector(2 downto 0);
        data_s_tdata        : in std_logic_vector(3 downto 0);
        data_s_tuser        : in std_logic_vector(3 downto 0);

        seg                 : out std_logic_vector(7 downto 0);
        an                  : out std_logic_vector(5 downto 0)
    );
end entity seven_seg_ctrl;

architecture rtl of seven_seg_ctrl is

    constant SYM_0          : std_logic_vector(3 downto 0) := "0000";
    constant SYM_1          : std_logic_vector(3 downto 0) := "0001";
    constant SYM_2          : std_logic_vector(3 downto 0) := "0010";
    constant SYM_3          : std_logic_vector(3 downto 0) := "0011";
    constant SYM_4          : std_logic_vector(3 downto 0) := "0100";
    constant SYM_5          : std_logic_vector(3 downto 0) := "0101";
    constant SYM_6          : std_logic_vector(3 downto 0) := "0110";
    constant SYM_7          : std_logic_vector(3 downto 0) := "0111";
    constant SYM_8          : std_logic_vector(3 downto 0) := "1000";
    constant SYM_9          : std_logic_vector(3 downto 0) := "1001";
    constant SYM_A          : std_logic_vector(3 downto 0) := "1010";
    constant SYM_b          : std_logic_vector(3 downto 0) := "1011";
    constant SYM_C          : std_logic_vector(3 downto 0) := "1100";
    constant SYM_d          : std_logic_vector(3 downto 0) := "1101";
    constant SYM_E          : std_logic_vector(3 downto 0) := "1110";
    constant SYM_F          : std_logic_vector(3 downto 0) := "1111";

    constant SSEG_DIGIT     : std_logic_vector(3 downto 0) := x"0";
    constant SSEG_NULL      : std_logic_vector(3 downto 0) := x"1";
    constant SSEG_MINUS     : std_logic_vector(3 downto 0) := x"2";

    type data_t is array (natural range 0 to 5) of std_logic_vector(3 downto 0);
    type user_t is array (natural range 0 to 5) of std_logic_vector(3 downto 0);

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
    signal user                         : user_t;

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

    data_writer : process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                data(0) <= x"A";
                data(1) <= x"B";
                data(2) <= x"C";
                data(3) <= x"D";
                data(4) <= x"E";
                data(5) <= x"F";
                user(0) <= SSEG_NULL;
                user(1) <= SSEG_NULL;
                user(2) <= SSEG_NULL;
                user(3) <= SSEG_NULL;
                user(4) <= SSEG_NULL;
                user(5) <= SSEG_NULL;
            else
                if (data_s_tvalid = '1') then
                    data(to_integer(unsigned(data_s_taddr))) <= data_s_tdata;
                    user(to_integer(unsigned(data_s_taddr))) <= data_s_tuser;
                end if;
            end if;
        end if;
    end process;

    with data(sel) select seg_next(6 downto 0) <=
        "1000000" when SYM_0,
        "1111001" when SYM_1,
        "0100100" when SYM_2,
        "0110000" when SYM_3,
        "0011001" when SYM_4,
        "0010010" when SYM_5,
        "0000010" when SYM_6,
        "1111000" when SYM_7,
        "0000000" when SYM_8,
        "0010000" when SYM_9,
        "0001000" when SYM_A,
        "0000011" when SYM_b,
        "1000110" when SYM_C,
        "0100001" when SYM_d,
        "0000110" when SYM_E,
        "0001110" when SYM_F,
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
            if (user(sel) = SSEG_DIGIT) then
                seg <= not seg_next;
            elsif (user(sel) = SSEG_MINUS) then
                seg <= not "10111111";
            else
                seg <= not "11111111";
            end if;
            an <= not an_next;
        end if;
    end process;

end architecture;