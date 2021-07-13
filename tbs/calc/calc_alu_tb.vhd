library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calc_alu_tb is
end entity calc_alu_tb;

architecture rtl of calc_alu_tb is
    constant CLK_PERIOD         : time := 10 ns;

    constant ALU_ADD            : std_logic_vector(2 downto 0) := "000";
    constant ALU_SUB            : std_logic_vector(2 downto 0) := "001";
    constant ALU_AND            : std_logic_vector(2 downto 0) := "010";
    constant ALU_OR             : std_logic_vector(2 downto 0) := "011";
    constant ALU_XOR            : std_logic_vector(2 downto 0) := "100";
    constant ALU_INV            : std_logic_vector(2 downto 0) := "101";
    constant ALU_MUL            : std_logic_vector(2 downto 0) := "110";

    type test_t is record
        a                       : std_logic_vector(11*4-1 downto 0);
        a_sign                  : std_logic;
        b                       : std_logic_vector(11*4-1 downto 0);
        b_sign                  : std_logic;
        op                      : std_logic_vector(2 downto 0);
        c                       : std_logic_vector(11*4-1 downto 0);
        c_sign                  : std_logic;
    end record;

    type a_list_t is array(0 to 2) of integer;
    type b_list_t is array(0 to 2) of integer;
    type op_list_t is array(0 to 6) of std_logic_vector(2 downto 0);

    type test_list_t is array (0 to 100) of test_t;

    signal clk                  : std_logic;
    signal resetn               : std_logic;

    component calc_alu is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            alu_s_tvalid        : in std_logic;
            alu_s_tready        : out std_logic;
            alu_s_tdata_a       : in std_logic_vector(11*4-1 downto 0);
            alu_s_tdata_a_sign  : in std_logic;
            alu_s_tdata_b       : in std_logic_vector(11*4-1 downto 0);
            alu_s_tdata_b_sign  : in std_logic;
            alu_s_tdata_op      : in std_logic_vector(2 downto 0);

            alu_m_tvalid        : out std_logic;
            alu_m_tready        : in std_logic;
            alu_m_tdata         : out std_logic_vector(11*4-1 downto 0);
            alu_m_tdata_sign    : out std_logic;
            alu_m_tuser_cb      : out std_logic

        );
    end component;

    signal alu_s_tvalid         : std_logic;
    signal alu_s_tready         : std_logic;
    signal alu_s_tdata_a        : std_logic_vector(11*4-1 downto 0);
    signal alu_s_tdata_a_sign   : std_logic;
    signal alu_s_tdata_b        : std_logic_vector(11*4-1 downto 0);
    signal alu_s_tdata_b_sign   : std_logic;
    signal alu_s_tdata_op       : std_logic_vector(2 downto 0);

    signal alu_m_tvalid         : std_logic;
    signal alu_m_tready         : std_logic;
    signal alu_m_tdata          : std_logic_vector(11*4-1 downto 0);
    signal alu_m_tdata_expected : std_logic_vector(11*4-1 downto 0);
    signal alu_m_tuser_cb       : std_logic;
    signal alu_m_tdata_sign     : std_logic;

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

    uut: calc_alu port map (
        clk                     => clk,
        resetn                  => resetn,

        alu_s_tvalid            => alu_s_tvalid,
        alu_s_tready            => alu_s_tready,
        alu_s_tdata_a           => alu_s_tdata_a,
        alu_s_tdata_a_sign      => alu_s_tdata_a_sign,
        alu_s_tdata_b           => alu_s_tdata_b,
        alu_s_tdata_b_sign      => alu_s_tdata_b_sign,
        alu_s_tdata_op          => alu_s_tdata_op,

        alu_m_tvalid            => alu_m_tvalid,
        alu_m_tready            => alu_m_tready,
        alu_m_tdata             => alu_m_tdata,
        alu_m_tdata_sign        => alu_m_tdata_sign,
        alu_m_tuser_cb          => alu_m_tuser_cb
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
        variable tests_last_idx : integer := 0;

        procedure init_tests is
            variable a_variants     : a_list_t;
            variable b_variants     : b_list_t;
            variable op_variants    : op_list_t;
            variable c              : integer;
        begin
            tests_last_idx := 0;
            a_variants(0) := 0;
            a_variants(1) := 32;
            a_variants(2) := -1;

            b_variants(0) := -1;
            b_variants(1) := 0;
            b_variants(2) := 1;

            op_variants(0) := ALU_MUL;
            op_variants(1) := ALU_ADD;
            op_variants(2) := ALU_AND;
            op_variants(3) := ALU_OR;
            op_variants(4) := ALU_XOR;
            op_variants(5) := ALU_INV;
            op_variants(6) := ALU_SUB;

            for op_idx in op_variants'range loop
                for a_idx in a_variants'range loop
                    for b_idx in b_variants'range loop

                        if (a_variants(a_idx) < 0) then
                            tests(tests_last_idx).a <= std_logic_vector(to_signed(-1 * a_variants(a_idx), 11*4));
                            tests(tests_last_idx).a_sign <= '1';
                        else
                            tests(tests_last_idx).a <= std_logic_vector(to_signed(a_variants(a_idx), 11*4));
                            tests(tests_last_idx).a_sign <= '0';
                        end if;

                        if (b_variants(b_idx) < 0) then
                            tests(tests_last_idx).b <= std_logic_vector(to_signed(-1 * b_variants(b_idx), 11*4));
                            tests(tests_last_idx).b_sign <= '1';
                        else
                            tests(tests_last_idx).b <= std_logic_vector(to_signed(b_variants(b_idx), 11*4));
                            tests(tests_last_idx).b_sign <= '0';
                        end if;
                        tests(tests_last_idx).op <= op_variants(op_idx);

                        case op_variants(op_idx) is
                            when ALU_ADD =>
                                c := a_variants(a_idx) + b_variants(b_idx);
                                if (c < 0) then
                                    tests(tests_last_idx).c <= std_logic_vector(to_signed(-1 * c, 11*4));
                                    tests(tests_last_idx).c_sign <= '1';
                                else
                                    tests(tests_last_idx).c <= std_logic_vector(to_signed(c, 11*4));
                                    tests(tests_last_idx).c_sign <= '0';
                                end if;

                            when ALU_SUB =>
                                c := a_variants(a_idx) - b_variants(b_idx);
                                if (c < 0) then
                                    tests(tests_last_idx).c <= std_logic_vector(to_signed(-1 * c, 11*4));
                                    tests(tests_last_idx).c_sign <= '1';
                                else
                                    tests(tests_last_idx).c <= std_logic_vector(to_signed(c, 11*4));
                                    tests(tests_last_idx).c_sign <= '0';
                                end if;

                            when ALU_MUL =>
                                c := a_variants(a_idx) * b_variants(b_idx);
                                if (c < 0) then
                                    tests(tests_last_idx).c <= std_logic_vector(to_signed(-1 * c, 11*4));
                                    tests(tests_last_idx).c_sign <= '1';
                                else
                                    tests(tests_last_idx).c <= std_logic_vector(to_signed(c, 11*4));
                                    tests(tests_last_idx).c_sign <= '0';
                                end if;

                            when ALU_AND =>
                                tests(tests_last_idx).c <= std_logic_vector(to_signed(a_variants(a_idx), 11*4)) and std_logic_vector(to_signed(b_variants(b_idx), 11*4));
                                tests(tests_last_idx).c_sign <= '0';

                            when ALU_OR =>
                                tests(tests_last_idx).c <= std_logic_vector(to_signed(a_variants(a_idx), 11*4)) or std_logic_vector(to_signed(b_variants(b_idx), 11*4));
                                tests(tests_last_idx).c_sign <= '0';

                            when ALU_XOR =>
                                tests(tests_last_idx).c <= std_logic_vector(to_signed(a_variants(a_idx), 11*4)) xor std_logic_vector(to_signed(b_variants(b_idx), 11*4));
                                tests(tests_last_idx).c_sign <= '0';

                            when ALU_INV =>
                                tests(tests_last_idx).c <= not std_logic_vector(to_signed(a_variants(a_idx), 11*4));
                                tests(tests_last_idx).c_sign <= '0';


                            when others =>
                                null;
                        end case;

                        tests_last_idx := tests_last_idx + 1;

                    end loop;
                end loop;
            end loop;

        end procedure;

    begin

        init_tests;

        wait until resetn = '1';
        alu_s_tvalid <= '0';
        wait for CLK_PERIOD;
        wait until rising_edge(clk);

        for test_idx in 0 to tests_last_idx-1 loop
            alu_s_tvalid <= '1';

            alu_s_tdata_a <= tests(test_idx).a;
            alu_s_tdata_a_sign <= tests(test_idx).a_sign;
            alu_s_tdata_b <= tests(test_idx).b;
            alu_s_tdata_b_sign <= tests(test_idx).b_sign;
            alu_s_tdata_op <= tests(test_idx).op;

            wait until rising_edge(clk) and alu_s_tready = '1';
        end loop;

        alu_s_tvalid <= '0';
        wait;

    end process;

    -- handling results
    process begin
        alu_m_tready <= '0';

        wait until resetn = '1';
        wait for CLK_PERIOD;
        wait until rising_edge(clk);

        loop
            alu_m_tdata_expected <= tests(alu_m_hs_cnt).c;
            alu_m_tready <= '1';
            wait until rising_edge(clk) and alu_m_tvalid = '1' and alu_m_tready = '1';

            if (alu_m_tdata /= tests(alu_m_hs_cnt).c) then
                report "Test " & integer'image(alu_m_hs_cnt) & " failed (alu_m_tdata)" severity error;
            elsif (alu_m_tdata_sign /= tests(alu_m_hs_cnt).c_sign) then
                report "Test " & integer'image(alu_m_hs_cnt) & " failed (alu_m_tdata_sign)" severity error;
            else
                report "Test " & integer'image(alu_m_hs_cnt) & " is ok " severity note;
            end if;

            alu_m_hs_cnt <= alu_m_hs_cnt + 1;

            alu_m_tready <= '0';
            wait until rising_edge(clk);

            alu_m_tready <= '1';
        end loop;
    end process;

end architecture;
