library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.env.stop;

entity dsp_addsub_tb is
end entity dsp_addsub_tb;

architecture rtl of dsp_addsub_tb is
    constant CLK_PERIOD         : time := 10 ns;
    constant TEST_CNT           : natural := 100;

    type test_rec_t is record
        a                       : std_logic_vector(47 downto 0);
        b                       : std_logic_vector(47 downto 0);
        op                      : std_logic;
        p                       : std_logic_vector(47 downto 0);
        di                      : integer;
        do                      : integer;
    end record;

    type test_list_t is array (0 to TEST_CNT) of test_rec_t;

    component dsp_addsub is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            addsub_s_tvalid    : in std_logic;
            addsub_s_tready    : out std_logic;
            addsub_s_tdata_a   : in std_logic_vector(47 downto 0);
            addsub_s_tdata_b   : in std_logic_vector(47 downto 0);
            addsub_s_tdata_op  : in std_logic;

            addsub_m_tvalid    : out std_logic;
            addsub_m_tready    : in std_logic;
            addsub_m_tdata     : out std_logic_vector(47 downto 0)
        );
    end component;

    signal clk                  : std_logic;
    signal resetn               : std_logic;

    signal addsub_s_tvalid      : std_logic := '0';
    signal addsub_s_tready      : std_logic;
    signal addsub_s_tdata_a     : std_logic_vector(47 downto 0);
    signal addsub_s_tdata_b     : std_logic_vector(47 downto 0);
    signal addsub_s_tdata_op    : std_logic;

    signal addsub_m_tvalid      : std_logic;
    signal addsub_m_tready      : std_logic := '1';
    signal addsub_m_tdata       : std_logic_vector(47 downto 0);

    signal addsub_m_hs_cnt      : integer := 0;

    signal tests                : test_list_t;

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


    uut: dsp_addsub port map (
        clk                    => clk,
        resetn                 => resetn,

        addsub_s_tvalid        => addsub_s_tvalid,
        addsub_s_tready        => addsub_s_tready,
        addsub_s_tdata_a       => addsub_s_tdata_a,
        addsub_s_tdata_b       => addsub_s_tdata_b,
        addsub_s_tdata_op      => addsub_s_tdata_op,

        addsub_m_tvalid        => addsub_m_tvalid,
        addsub_m_tready        => addsub_m_tready,
        addsub_m_tdata         => addsub_m_tdata
    );

    -- continuous clock
    process begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    resetn <= '0', '1' after 10*CLK_PERIOD;

    -- stimuli
    process
        procedure generate_tests is
            type data_a_t is array(0 to 2) of std_logic_vector(47 downto 0);
            type data_b_t is array(0 to 5) of std_logic_vector(47 downto 0);
            type data_op_t is array(0 to 1) of std_logic;

            type delay_i_t is array(0 to 7) of integer;
            type delay_o_t is array(0 to 7) of integer;

            variable t      : test_list_t;
            variable a      : data_a_t;
            variable b      : data_b_t;
            variable op     : data_op_t;
            variable a_cnt  : integer := 0;
            variable b_cnt  : integer := 0;
            variable op_cnt : integer := 0;
            variable di     : delay_i_t;
            variable do     : delay_o_t;
        begin
            a(0) := x"000000000000";
            a(1) := x"000000000001";
            a(2) := x"001000000000";

            b(0) := x"000000000000";
            b(1) := x"000000000001";
            b(2) := x"001000000000";
            b(3) := x"111111111111";
            b(4) := x"101000000000";

            op(0) := '0';
            op(1) := '1';

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
                t(i).a := a(a_cnt mod 3);
                t(i).b := b(b_cnt mod 5);
                t(i).op := op(op_cnt mod 2);

                a_cnt := a_cnt + 1;
                b_cnt := b_cnt + 1;
                op_cnt := op_cnt + 1;

                if (t(i).op = '1') then
                    t(i).p := std_logic_vector(unsigned(t(i).a) - unsigned(t(i).b));
                else
                    t(i).p := std_logic_vector(unsigned(t(i).a) + unsigned(t(i).b));
                end if;

                t(i).di := di(i mod 8);
                t(i).do := do(i mod 8);
            end loop;

            tests <= t;
        end procedure;

    begin
        generate_tests;

        wait until resetn = '1';

        -- init
        addsub_s_tvalid <= '0';
        wait until rising_edge(clk);

        -- loop
        for i in 0 to TEST_CNT loop

            if tests(i).di > 0 then
                addsub_s_tvalid <= '0';
                for i in 0 to tests(i).di loop
                    wait until rising_edge(clk);
                end loop;
            end if;
            addsub_s_tvalid <= '1';
            addsub_s_tdata_a <= tests(i).a;
            addsub_s_tdata_b <= tests(i).b;
            addsub_s_tdata_op <= tests(i).op;

            wait until rising_edge(clk) and addsub_s_tready = '1';

        end loop;

        addsub_s_tvalid <= '0';

    end process;

    -- handling results
    process begin
        wait until resetn = '1';

        addsub_m_tready <= '1';
        wait until rising_edge(clk);

        loop

            wait until rising_edge(clk) and addsub_m_tvalid = '1' and addsub_m_tready = '1';

            if (addsub_m_tdata /= tests(addsub_m_hs_cnt).p) then
                report "Test " & integer'image(addsub_m_hs_cnt) & " failed " &
                    "addsub_m_tdata = " & to_string(addsub_m_tdata) & " " &
                    "expected = " & to_string(tests(addsub_m_hs_cnt).p) severity error;
            else
                report "Test " & integer'image(addsub_m_hs_cnt) & " is ok " severity note;
            end if;

            if (tests(addsub_m_hs_cnt).do > 0) then
                addsub_m_tready <= '0';
                for i in 0 to tests(addsub_m_hs_cnt).do loop
                    wait until rising_edge(clk);
                end loop;
                addsub_m_tready <= '1';
            end if;

            addsub_m_hs_cnt <= addsub_m_hs_cnt + 1;

        end loop;

    end process;

end architecture;
