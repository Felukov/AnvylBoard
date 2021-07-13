library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.env.stop;

entity dsp_acc_tb is
end entity dsp_acc_tb;

architecture rtl of dsp_acc_tb is
    constant CLK_PERIOD         : time := 10 ns;
    constant TEST_CNT           : natural := 100;

    type test_rec_t is record
        a                       : std_logic_vector(47 downto 0);
        p                       : std_logic_vector(47 downto 0);
        di                      : integer;
        do                      : integer;
    end record;

    type test_list_t is array (0 to TEST_CNT) of test_rec_t;

    component dsp_acc is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            dsp_acc_s_tvalid    : in std_logic;
            dsp_acc_s_tready    : out std_logic;
            dsp_acc_s_tdata     : in std_logic_vector(47 downto 0);

            dsp_acc_m_tvalid    : out std_logic;
            dsp_acc_m_tready    : in std_logic;
            dsp_acc_m_tdata     : out std_logic_vector(47 downto 0)
        );
    end component;

    signal clk                  : std_logic;
    signal resetn               : std_logic;

    signal dsp_acc_s_tvalid     : std_logic := '0';
    signal dsp_acc_s_tready     : std_logic;
    signal dsp_acc_s_tdata      : std_logic_vector(47 downto 0);

    signal dsp_acc_m_tvalid     : std_logic;
    signal dsp_acc_m_tready     : std_logic := '1';
    signal dsp_acc_m_tdata      : std_logic_vector(47 downto 0);

    signal dsp_acc_m_hs_cnt     : integer := 0;

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


    uut: dsp_acc port map (
        clk                     => clk,
        resetn                  => resetn,

        dsp_acc_s_tvalid        => dsp_acc_s_tvalid,
        dsp_acc_s_tready        => dsp_acc_s_tready,
        dsp_acc_s_tdata         => dsp_acc_s_tdata,

        dsp_acc_m_tvalid        => dsp_acc_m_tvalid,
        dsp_acc_m_tready        => dsp_acc_m_tready,
        dsp_acc_m_tdata         => dsp_acc_m_tdata
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
            type a_t is array(0 to 2) of std_logic_vector(47 downto 0);
            type delay_i_t is array(0 to 7) of integer;
            type delay_o_t is array(0 to 7) of integer;

            variable t   : test_list_t;
            variable a   : a_t;
            variable di  : delay_i_t;
            variable do  : delay_o_t;
        begin
            a(0) := x"000000000000";
            a(1) := x"000000000001";
            a(2) := x"001000000000";

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

            t(0).a := a(0);
            t(0).p := a(0);

            for i in 1 to TEST_CNT loop
                t(i).a := a(i mod 3);
                t(i).p := std_logic_vector(unsigned(t(i-1).p) + unsigned(a(i mod 3)));
                t(i).di := di(i mod 8);
                t(i).do := do(i mod 8);
            end loop;

            tests <= t;
        end procedure;

    begin
        generate_tests;

        wait until resetn = '1';

        -- init
        dsp_acc_s_tvalid <= '0';
        wait until rising_edge(clk);

        -- loop
        for i in 0 to TEST_CNT loop

            if tests(i).di > 0 then
                dsp_acc_s_tvalid <= '0';
                for i in 0 to tests(i).di loop
                    wait until rising_edge(clk);
                end loop;
            end if;
            dsp_acc_s_tvalid <= '1';
            dsp_acc_s_tdata <= tests(i).a;

            wait until rising_edge(clk) and dsp_acc_s_tready = '1';

        end loop;

        dsp_acc_s_tvalid <= '0';

    end process;

    -- handling results
    process begin
        wait until resetn = '1';

        dsp_acc_m_tready <= '1';
        wait until rising_edge(clk);

        loop

            wait until rising_edge(clk) and dsp_acc_m_tvalid = '1' and dsp_acc_m_tready = '1';

            if (dsp_acc_m_tdata /= tests(dsp_acc_m_hs_cnt).p) then
                report "Test " & integer'image(dsp_acc_m_hs_cnt) & " failed " &
                    "dsp_acc_m_tdata = " & to_string(dsp_acc_m_tdata) & " " &
                    "expected = " & to_string(tests(dsp_acc_m_hs_cnt).p) severity error;
            else
                report "Test " & integer'image(dsp_acc_m_hs_cnt) & " is ok " severity note;
            end if;

            if (tests(dsp_acc_m_hs_cnt).do > 0) then
                dsp_acc_m_tready <= '0';
                for i in 0 to tests(dsp_acc_m_hs_cnt).do loop
                    wait until rising_edge(clk);
                end loop;
                dsp_acc_m_tready <= '1';
            end if;

            dsp_acc_m_hs_cnt <= dsp_acc_m_hs_cnt + 1;

        end loop;

    end process;

end architecture;
