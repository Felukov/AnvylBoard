library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity axis_div_u_tb is
end entity axis_div_u_tb;

architecture rtl of axis_div_u_tb is
    constant CLK_PERIOD     : time := 10 ns;
    constant MAX_WIDTH      : natural := 16;

    constant SIZE_PER_SYMBOL_X  : positive := positive(round(real((4096.0)/12)));


    signal clk              : std_logic;
    signal resetn           : std_logic;

    component axis_div_u is
        generic (
            MAX_WIDTH       : natural := 16;
            USER_WIDTH      : natural := 32
        );
        port (
            clk             : in std_logic;
            resetn          : in std_logic;
            div_s_tvalid    : in std_logic;
            div_s_tready    : out std_logic;
            div_s_tdata     : in std_logic_vector(2*MAX_WIDTH-1 downto 0);
            div_s_tuser     : in std_logic_vector(2*MAX_WIDTH-1 downto 0);

            div_m_tvalid    : out std_logic;
            div_m_tready    : in std_logic;
            div_m_tdata     : out std_logic_vector(2*MAX_WIDTH-1 downto 0);
            div_m_tuser     : out std_logic_vector(2*MAX_WIDTH-1 downto 0)
        );
    end component;

    signal div_s_tvalid     : std_logic;
    signal div_s_tready     : std_logic;
    signal div_s_tdata      : std_logic_vector(2*MAX_WIDTH-1 downto 0);
    signal div_s_tuser      : std_logic_vector(2*MAX_WIDTH-1 downto 0);

    signal div_m_tvalid     : std_logic;
    signal div_m_tready     : std_logic;
    signal div_m_tdata      : std_logic_vector(2*MAX_WIDTH-1 downto 0);
    signal div_m_tuser      : std_logic_vector(2*MAX_WIDTH-1 downto 0);

    signal check_n          : integer;
    signal check_d          : integer;
    signal check_q          : integer;
    signal check_r          : integer;

begin

    uut: axis_div_u generic map (
        MAX_WIDTH       => MAX_WIDTH,
        USER_WIDTH      => 2*MAX_WIDTH
    ) port map (
        clk             => clk,
        resetn          => resetn,
        div_s_tvalid    => div_s_tvalid,
        div_s_tready    => div_s_tready,
        div_s_tdata     => div_s_tdata,
        div_s_tuser     => div_s_tuser,
        div_m_tvalid    => div_m_tvalid,
        div_m_tready    => div_m_tready,
        div_m_tdata     => div_m_tdata,
        div_m_tuser     => div_m_tuser
    );

    -- continuous clock
    process begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    resetn <= '0', '1' after 10*CLK_PERIOD;

    process begin
        wait until resetn = '1';
        wait for CLK_PERIOD;
        wait until rising_edge(clk);

        div_s_tvalid <= '1';
        div_s_tdata(2*MAX_WIDTH-1 downto MAX_WIDTH) <= x"FA00"; -- 4000 * 16
        div_s_tdata(MAX_WIDTH-1 downto 0) <= std_logic_vector(to_unsigned(SIZE_PER_SYMBOL_X, MAX_WIDTH));

        div_s_tuser(2*MAX_WIDTH-1 downto MAX_WIDTH) <= x"FA00";
        div_s_tuser(MAX_WIDTH-1 downto 0) <= std_logic_vector(to_unsigned(SIZE_PER_SYMBOL_X, MAX_WIDTH));
        wait until rising_edge(clk) and div_s_tready = '1';

        div_s_tvalid <= '1';
        div_s_tdata(2*MAX_WIDTH-1 downto MAX_WIDTH) <= x"FFFF";
        div_s_tdata(MAX_WIDTH-1 downto 0) <= x"0001";

        div_s_tuser(2*MAX_WIDTH-1 downto MAX_WIDTH) <= x"FFFF";
        div_s_tuser(MAX_WIDTH-1 downto 0) <= x"0001";
        wait until rising_edge(clk) and div_s_tready = '1';


        for i in 0 to 100 loop
            div_s_tvalid <= '1';
            div_s_tdata(2*MAX_WIDTH-1 downto MAX_WIDTH) <= std_logic_vector(to_unsigned(1000, MAX_WIDTH));
            div_s_tdata(MAX_WIDTH-1 downto 0) <= std_logic_vector(to_unsigned(i, MAX_WIDTH));
            div_s_tuser(2*MAX_WIDTH-1 downto MAX_WIDTH) <= std_logic_vector(to_unsigned(1000, MAX_WIDTH));
            div_s_tuser(MAX_WIDTH-1 downto 0) <= std_logic_vector(to_unsigned(i, MAX_WIDTH));
            wait until rising_edge(clk) and div_s_tready = '1';
        end loop;
        div_s_tvalid <= '0';

    end process;

    check_n <= to_integer(unsigned(div_m_tuser(2*MAX_WIDTH-1 downto MAX_WIDTH)));
    check_d <= to_integer(unsigned(div_m_tuser(MAX_WIDTH-1 downto 0)));
    check_q <= to_integer(unsigned(div_m_tdata(2*MAX_WIDTH-1 downto MAX_WIDTH)));
    check_r <= to_integer(unsigned(div_m_tdata(MAX_WIDTH-1 downto 0)));

    process begin
        div_m_tready <= '0';

        wait until resetn = '1';
        wait for CLK_PERIOD;
        wait until rising_edge(clk);

        loop
            div_m_tready <= '1';
            wait until rising_edge(clk) and div_m_tvalid = '1' and div_m_tready = '1';

            if check_d = 0 or check_n / check_d = check_q then
                report "test ok";
            else
                report "test failed. i = " & integer'image(check_d);
            end if;

            div_m_tready <= '0';
            wait until rising_edge(clk);

            div_m_tready <= '1';
        end loop;
    end process;

end architecture;
