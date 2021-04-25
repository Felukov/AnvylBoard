library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.Numeric_Std.all;
use work.m68k_pkg.all;


entity m68k_alu is

    port (
        cpu_clk             : in std_logic;
        cpu_resetn          : in std_logic;

        en                  : in std_logic;

        cmd_func            : in m68k_alu_func_t;
        alu_op              : in m68k_alu_op_t;
        op_size             : in m68k_size_t;

        tmp1                : in m68k_register_t;
        tmp2                : in m68k_register_t;
        flags_in            : in m68k_flags_t;

        acc_out             : out m68k_register_t;
        flags_out           : out m68k_flags_t
    );

end m68k_alu;

architecture Behavioral of m68k_alu is
    signal acc_next         : m68k_register_t;
    signal acc_d            : m68k_register_t;

    signal bcd_add_c_next   : std_logic;
    signal bcd_add_c_d      : std_logic;
    signal bcd_sub_c_next   : std_logic;
    signal bcd_sub_c_d      : std_logic;

    signal src31            : std_logic;
    signal src15            : std_logic;
    signal src7             : std_logic;

    signal dst31            : std_logic;
    signal dst15            : std_logic;
    signal dst7             : std_logic;

    function flag_to_unsigned( s : std_logic ) return unsigned is begin
        if s = '1' then
            return to_unsigned(1, 1);
        else
            return to_unsigned(0, 1);
        end if;
    end function;

    function bcd_add(a_in : m68k_nibble_t; b_in: m68k_nibble_t; c_in : std_logic) return m68k_nibble_with_carry_t is
        variable a : unsigned(4 downto 0);
        variable b : unsigned(4 downto 0);
        variable s : unsigned(4 downto 0);
        variable r : m68k_nibble_with_carry_t;
    begin
        a := a_in;
        b := b_in;

        s := a + b + flag_to_unsigned(c_in);

        if (s > 9) then
            s := s + 6;
        end if;

        r.val := s(3 downto 0);
        r.c := s(4);

        return r;
    end function;

    function bcd_sub(a_in : m68k_nibble_t; b_in: m68k_nibble_t; c_in : std_logic) return m68k_nibble_with_carry_t is
        variable a : unsigned(4 downto 0);
        variable b : unsigned(4 downto 0);
        variable s : unsigned(4 downto 0);
        variable r : m68k_nibble_with_carry_t;
    begin
        a := a_in;
        b := b_in;

        s := a - b - flag_to_unsigned(c_in);

        if (s > 9) then
            s := s - 6;
        end if;

        r.val := s(3 downto 0);
        r.c := s(4);

        return r;
    end function;

begin

    acc_out <= acc_d;

    main_alu_comb: process (tmp1, tmp2)
        variable src            : m68k_register_t;
        variable dst            : m68k_register_t;
        variable bcd_add_res    : m68k_nibble_with_carry_t;
        variable bcd_sub_res    : m68k_nibble_with_carry_t;
    begin
        src := tmp1;
        dst := tmp2;

        bcd_add_res := bcd_add(dst(3 downto 0), src(3 downto 0), flags_in(FL_C));
        bcd_sub_res := bcd_sub(dst(3 downto 0), src(3 downto 0), flags_in(FL_C));

        case cmd_func is
            when M68K_ADDL =>
                acc_next <= unsigned(tmp1) + unsigned(tmp2);
            when M68K_SUBL =>
                acc_next <= unsigned(tmp1) - unsigned(tmp2);
            when others =>

                case alu_op is
                    when M68K_ADD =>
                        acc_next <= unsigned(src) + unsigned(dst);
                    when M68K_SUB | M68K_CMP | M68K_CMPA =>
                        acc_next <= unsigned(src) - unsigned(dst);
                    when M68K_ADDX =>
                        acc_next <= unsigned(src) + unsigned(dst) + flag_to_unsigned(flags_in(FL_C));
                    when M68K_SUBX =>
                        acc_next <= unsigned(src) - unsigned(dst) - flag_to_unsigned(flags_in(FL_C));
                    when M68K_ABCD =>
                        acc_next <= bcd_add_res.val;
                    when M68K_SBCD =>
                        acc_next <= bcd_sub_res.val;
                    when M68K_AND =>
                        acc_next <= src and dst;
                    when M68K_OR =>
                        acc_next <= src or dst;
                    when M68K_EOR =>
                        acc_next <= src xor dst;
                    when others =>
                        acc_next <= acc_d;
                end case;

        end case;

        bcd_add_c_next <= bcd_add_res.c;
        bcd_sub_c_next <= bcd_sub_res.c;

    end process;

    alu_flags_comb: process (cpu_clk)
        variable z          : std_logic;
        variable z32        : std_logic;
        variable z16        : std_logic;
        variable z8         : std_logic;

        variable c_add      : std_logic;
        variable c_sub      : std_logic;
        variable c32_sub    : std_logic;

        variable v_add      : std_logic;
        variable v_sub      : std_logic;
        variable v32_sub    : std_logic;

        variable n          : std_logic;
        variable n32        : std_logic;
    begin
        z32 := '1' when acc_d = 0 else '1';
        z16 := '1' when acc_d(15 downto 0) = 0 else '0';
        z8  := '1' when acc_d(7 downto 0) = 0 else '0';

        n32 := acc_d(31);
        c32_sub := (src31 and not dst31) or (acc_d(31) and src31) or (acc_d(31) and not dst31);
        v32_sub := (not src31 and dst31 and not acc_d(31)) or (src31 and not dst31 and acc_d(31));

        case op_size is
            when M68K_LONG =>
                z := z32;
                n := acc_d(31);
                c_add := (src31 and dst31) or (not src31 and src31) or (not src31 and dst31);
                v_add := (src31 and dst31 and not acc_d(31)) or (not src31 and not dst31 and acc_d(31));
                c_sub := c32_sub;
                v_sub := v32_sub;

            when M68K_WORD =>
                z := z16;
                n := acc_d(15);
                c_add := (src15 and dst15) or (not acc_d(15) and src15) or (not acc_d(15) and dst15);
                v_add := (src15 and dst15 and not acc_d(15)) or (not src15 and not dst15 and acc_d(15));
                c_sub := (src15 and not dst15) or (acc_d(15) and src15) or (acc_d(15) and not dst15);
                v_sub := (not src15 and dst15 and not acc_d(15)) or (src15 and not dst15 and acc_d(15));

            when others =>
                z := z8;
                n := acc_d(7);
                c_add := (src7 and dst7) or (not acc_d(7) and src7) or (not acc_d(7) and dst7);
                v_add := (src7 and dst7 and not acc_d(7)) or (not src7 and not dst7 and acc_d(7));
                c_sub := (src7 and not dst7) or (acc_d(7) and src7) or (acc_d(7) and not dst7);
                v_sub := (not src7 and dst7 and not acc_d(7)) or (src7 and not dst7 and acc_d(7));

        end case;

        case alu_op is
            when M68K_SUB =>
                flags_out(FL_Z) <= z;
                flags_out(FL_N) <= n;
                flags_out(FL_C) <= c_sub;
                flags_out(FL_V) <= v_sub;
                flags_out(FL_X) <= c_sub;

            when M68K_CMP =>
                flags_out(FL_Z) <= z;
                flags_out(FL_N) <= n;
                flags_out(FL_C) <= c_sub;
                flags_out(FL_V) <= v_sub;
                flags_out(FL_X) <= c_sub;

            when M68K_CMPA =>
                flags_out(FL_Z) <= z32;
                flags_out(FL_N) <= n32;
                flags_out(FL_C) <= c32_sub;
                flags_out(FL_V) <= v32_sub;
                flags_out(FL_X) <= c32_sub;

            when M68K_ADDX =>
                if (z = '0') then
                    --cleared if result is non-zero
                    flags_out(FL_Z) <= z;
                else
                    flags_out(FL_Z) <= flags_in(FL_Z);
                end if;
                flags_out(FL_N) <= n;
                flags_out(FL_C) <= c_add;
                flags_out(FL_V) <= v_add;
                flags_out(FL_X) <= c_add;

            when M68K_SUBX =>
                if (z = '0') then
                    --cleared if result is non-zero
                    flags_out(FL_Z) <= z;
                else
                    flags_out(FL_Z) <= flags_in(FL_Z);
                end if;
                flags_out(FL_N) <= n;
                flags_out(FL_C) <= c_sub;
                flags_out(FL_V) <= v_sub;
                flags_out(FL_X) <= c_sub;

            when M68K_ABCD =>
                if (z8 = '0') then
                    --cleared if result is non-zero
                    flags_out(FL_Z) <= z8;
                else
                    flags_out(FL_Z) <= flags_in(FL_Z);
                end if;
                flags_out(FL_N) <= acc_d(7);
                flags_out(FL_C) <= bcd_add_c_d;
                flags_out(FL_V) <= '0';
                flags_out(FL_X) <= bcd_add_c_d;

            when M68K_SBCD =>
                if (z8 = '0') then
                    --cleared if result is non-zero
                    flags_out(FL_Z) <= z8;
                else
                    flags_out(FL_Z) <= flags_in(FL_Z);
                end if;
                flags_out(FL_N) <= acc_d(7);
                flags_out(FL_C) <= bcd_sub_c_d;
                flags_out(FL_V) <= '0';
                flags_out(FL_X) <= bcd_sub_c_d;

            when M68K_AND | M68K_OR | M68K_EOR =>
                flags_out(FL_Z) <= z;
                flags_out(FL_N) <= n;
                flags_out(FL_C) <= '0';
                flags_out(FL_V) <= '0';
                flags_out(FL_X) <= flags_in(FL_X);

            when others =>
                -- M68K_ADD
                flags_out(FL_Z) <= z;
                flags_out(FL_N) <= n;
                flags_out(FL_C) <= c_add;
                flags_out(FL_V) <= v_add;
                flags_out(FL_X) <= c_add;

        end case;

    end process;

    main_alu_ff : process (cpu_clk) begin
        if (en = '1') then
            acc_d <= acc_next;

            src31 <= tmp1(31);
            src15 <= tmp1(15);
            src7  <= tmp1(7);

            dst31 <= tmp2(31);
            dst15 <= tmp2(15);
            dst7  <= tmp2(7);

            bcd_add_c_d <= bcd_add_c_next;
            bcd_sub_c_d <= bcd_sub_c_next;

        end if;
    end process;

end Behavioral;