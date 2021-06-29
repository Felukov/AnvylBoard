library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis_reg_tb is
end entity axis_reg_tb;

architecture rtl of axis_reg_tb is
    constant CLK_PERIOD         : time := 10 ns;


    type test_t is record
        val                     : std_logic_vector(31 downto 0);
        delay                   : natural;
    end record;

    type delay_list_t is array(0 to 19) of natural;

    type test_list_t is array (0 to 100) of test_t;

    signal clk                  : std_logic;
    signal resetn               : std_logic;

    component axis_reg is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            in_s_tvalid         : in std_logic;
            in_s_tready         : out std_logic;
            in_s_tdata          : in std_logic_vector(31 downto 0);

            out_m_tvalid        : out std_logic;
            out_m_tready        : in std_logic;
            out_m_tdata         : out std_logic_vector(31 downto 0)
        );
    end component;

    signal in_s_tvalid          : std_logic;
    signal in_s_tready          : std_logic;
    signal in_s_tdata           : std_logic_vector(31 downto 0);

    signal out_m_tvalid         : std_logic;
    signal out_m_tready         : std_logic;
    signal out_m_tdata          : std_logic_vector(31 downto 0);

    signal alu_m_hs_cnt         : integer := 0;

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

    uut: axis_reg port map (
        clk                     => clk,
        resetn                  => resetn,

        in_s_tvalid             => in_s_tvalid,
        in_s_tready             => in_s_tready,
        in_s_tdata              => in_s_tdata,

        out_m_tvalid            => out_m_tvalid,
        out_m_tready            => out_m_tready,
        out_m_tdata             => out_m_tdata
    );

    -- continuous clock
    process begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    resetn <= '0', '1' after 10 * CLK_PERIOD;

    -- stimuli
    process

        procedure init_tests is
            variable delays         : delay_list_t;
            variable val            : integer;
        begin
            delays(0) := 0;
            delays(1) := 0;
            delays(2) := 1;
            delays(3) := 1;
            delays(4) := 0;
            delays(5) := 0;
            delays(6) := 2;
            delays(7) := 10;
            delays(8) := 0;
            delays(9) := 3;

            for tests_last_idx in tests'range loop

                tests(tests_last_idx).val <= std_logic_vector(to_unsigned(tests_last_idx, 32));
                tests(tests_last_idx).delay <= delays(tests_last_idx mod 10);

            end loop;

        end procedure;

    begin

        init_tests;

        wait until resetn = '1';
        in_s_tvalid <= '0';
        wait for CLK_PERIOD;
        wait until rising_edge(clk);

        for test_idx in tests'range loop

            if tests(test_idx).delay > 0 then
                for i in 0 to tests(test_idx).delay-1 loop
                    in_s_tvalid <= '0';
                    wait until rising_edge(clk);
                end loop;
            end if;
            in_s_tvalid <= '1';

            in_s_tdata <= tests(test_idx).val;

            wait until rising_edge(clk) and in_s_tready = '1';
        end loop;

        in_s_tvalid <= '0';
        wait;

    end process;

    -- handling results
    process begin
        out_m_tready <= '0';

        wait until resetn = '1';
        wait for CLK_PERIOD;
        wait until rising_edge(clk);

        while alu_m_hs_cnt < 100 loop
            if tests(alu_m_hs_cnt).delay > 0 then
                for i in 0 to tests(alu_m_hs_cnt).delay*2 loop
                    out_m_tready <= '0';
                    wait until rising_edge(clk);
                end loop;
            end if;
            out_m_tready <= '1';

            wait until rising_edge(clk);
            if (out_m_tvalid = '1' and out_m_tready = '1') then

                if (out_m_tdata /= tests(alu_m_hs_cnt).val) then
                    report "Test " & integer'image(alu_m_hs_cnt) & " failed (out_m_tdata)" severity error;
                else
                    report "Test " & integer'image(alu_m_hs_cnt) & " is ok " severity note;
                end if;

                alu_m_hs_cnt <= alu_m_hs_cnt + 1;
            end if;
        end loop;
        wait;
    end process;

end architecture;
