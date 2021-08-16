library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity dsp_div_u_tb is
end entity dsp_div_u_tb;

architecture rtl of dsp_div_u_tb is
    constant CLK_PERIOD         : time := 10 ns;
    constant MAX_WIDTH          : natural := 48;
    constant TEST_CNT           : natural := 100;

    type test_rec_t is record
        n                       : std_logic_vector(47 downto 0);
        d                       : std_logic_vector(47 downto 0);
        q                       : std_logic_vector(47 downto 0);
        r                       : std_logic_vector(47 downto 0);
        di                      : integer;
        do                      : integer;
    end record;

    type test_list_t is array (0 to TEST_CNT) of test_rec_t;

    signal clk              : std_logic;
    signal resetn           : std_logic;

    component dsp_div_u is
        generic (
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

    signal div_s_tvalid2    : std_logic;

    signal div_m_tvalid     : std_logic;
    signal div_m_tready     : std_logic;
    signal div_m_tdata      : std_logic_vector(2*MAX_WIDTH-1 downto 0);
    signal div_m_tuser      : std_logic_vector(2*MAX_WIDTH-1 downto 0);

    signal tests            : test_list_t;
    signal div_m_hs_cnt     : integer := 0;

    function to_string ( a: std_logic_vector) return string is
        variable b : string (1 to a'length) := (others => NUL);
        variable stri : integer := 1;
        begin
            for i in a'range loop
                b(stri) := std_logic'image(a((i)))(2);
            stri := stri+1;
            end loop;
        return b;
    end function;

begin
    div_s_tvalid2 <= '1' when div_s_tvalid = '1' and div_s_tready = '1' else '0';
    uut: dsp_div_u generic map (
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

    uut_1: axis_div_u generic map (
        MAX_WIDTH       => MAX_WIDTH,
        USER_WIDTH      => 2*MAX_WIDTH
    ) port map (
        clk             => clk,
        resetn          => resetn,
        div_s_tvalid    => div_s_tvalid2,
        div_s_tready    => open,
        div_s_tdata     => div_s_tdata,
        div_s_tuser     => div_s_tuser,
        div_m_tvalid    => open,
        div_m_tready    => '1',
        div_m_tdata     => open,
        div_m_tuser     => open
    );

    -- continuous clock
    process begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    resetn <= '0', '1' after 10*CLK_PERIOD;

    process
        procedure generate_tests is
            type data_n_t is array(0 to 10) of std_logic_vector(47 downto 0);
            type data_d_t is array(0 to 7) of std_logic_vector(47 downto 0);

            type delay_i_t is array(0 to 7) of integer;
            type delay_o_t is array(0 to 7) of integer;

            variable t      : test_list_t;
            variable n      : data_n_t;
            variable d      : data_d_t;
            variable n_cnt  : integer := 0;
            variable d_cnt  : integer := 0;
            variable di     : delay_i_t;
            variable do     : delay_o_t;
        begin
            n(0) := x"00100000000F";
            n(1) := x"000000000000";
            n(2) := x"000000000111";
            n(3) := x"000000001111";
            n(4) := x"00000000000A";
            n(5) := x"00100000000B";
            n(6) := x"00100000000C";
            n(7) := x"00100000000D";
            n(8) := x"00100000000E";
            n(9) := x"00000000FFFF";
            n(10) := x"0FF0000000FF";

            d(0) := x"111111111111";
            d(1) := x"000000000000";
            d(2) := x"000000000001";
            d(3) := x"001000000002";
            d(4) := x"101000000003";
            d(5) := x"101000000004";
            d(6) := x"101000000031";
            d(7) := x"101000000332";

            di(0) := 0;
            di(1) := 1;
            di(2) := 2;
            di(3) := 0;
            di(4) := 0;
            di(5) := 100;
            di(6) := 0;
            di(7) := 0;

            do(0) := 0;
            do(1) := 100;
            do(2) := 7;
            do(3) := 0;
            do(4) := 0;
            do(5) := 1;
            do(6) := 0;
            do(7) := 1;

            for i in 0 to TEST_CNT loop
                t(i).n := n(n_cnt mod data_n_t'length);
                t(i).d := d(d_cnt mod data_d_t'length);

                n_cnt := n_cnt + 1;
                d_cnt := d_cnt + 1;

                if (t(i).d /= x"000000000000") then
                    t(i).q := std_logic_vector(unsigned(t(i).n) / unsigned(t(i).d));
                    t(i).r := std_logic_vector(unsigned(t(i).n) mod unsigned(t(i).d));
                else
                    t(i).q := x"000000000000";
                    t(i).r := x"000000000000";
                end if;

                t(i).di := di(i mod 8);
                t(i).do := do(i mod 8);
            end loop;

            tests <= t;
        end procedure;

    begin
        generate_tests;

        wait until resetn = '1';
        wait for CLK_PERIOD;
        wait until rising_edge(clk);

        -- init
        div_s_tvalid <= '0';
        wait until rising_edge(clk);

        -- loop
        for i in 0 to TEST_CNT loop

            if tests(i).di > 0 then
                div_s_tvalid <= '0';
                for i in 0 to tests(i).di loop
                    wait until rising_edge(clk);
                end loop;
            end if;

            div_s_tvalid <= '1';
            div_s_tdata(95 downto 48) <= tests(i).n;
            div_s_tdata(47 downto 0) <= tests(i).d;
            div_s_tuser(95 downto 48) <= tests(i).n;
            div_s_tuser(47 downto 0) <= tests(i).d;

            wait until rising_edge(clk) and div_s_tready = '1';

        end loop;

        div_s_tvalid <= '0';

    end process;

    process begin
        wait until resetn = '1';
        div_m_tready <= '1';
        wait until rising_edge(clk);

        loop
            wait until rising_edge(clk) and div_m_tvalid = '1' and div_m_tready = '1';

            if (tests(div_m_hs_cnt).d /= x"000000000000" and div_m_tdata(95 downto 48) /= tests(div_m_hs_cnt).q) then
                report "Test " & integer'image(div_m_hs_cnt) & " failed " &
                    "div_m_tdata(q) = " & to_string(div_m_tdata(95 downto 48)) & " " &
                    "expected = " & to_string(tests(div_m_hs_cnt).q) severity error;
            elsif (tests(div_m_hs_cnt).d /= x"000000000000" and div_m_tdata(47 downto 0) /= tests(div_m_hs_cnt).r) then
                report "Test " & integer'image(div_m_hs_cnt) & " failed " &
                    "div_m_tdata(r) = " & to_string(div_m_tdata(47 downto 0)) & " " &
                    "expected = " & to_string(tests(div_m_hs_cnt).r) severity error;
            elsif (tests(div_m_hs_cnt).d /= x"000000000000" and div_m_tuser(47 downto 0) /= tests(div_m_hs_cnt).d) then
                report "Test " & integer'image(div_m_hs_cnt) & " failed " &
                    "div_m_tdata(d) = " & to_string(div_m_tuser(47 downto 0)) & " " &
                    "expected = " & to_string(tests(div_m_hs_cnt).d) severity error;
            else
                report "Test " & integer'image(div_m_hs_cnt) & " is ok " severity note;
            end if;

            if (tests(div_m_hs_cnt).do > 0) then
                div_m_tready <= '0';
                for i in 0 to tests(div_m_hs_cnt).do loop
                    wait until rising_edge(clk);
                end loop;
                div_m_tready <= '1';
            end if;

            div_m_hs_cnt <= div_m_hs_cnt + 1;

        end loop;
    end process;

end architecture;
