library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;
use ieee.std_logic_unsigned.all;

entity calc_mult is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        mult_s_tvalid           : in std_logic;
        mult_s_tready           : out std_logic;
        mult_s_tdata_a          : in std_logic_vector(11*4-1 downto 0);
        mult_s_tdata_b          : in std_logic_vector(11*4-1 downto 0);

        mult_m_tvalid           : out std_logic;
        mult_m_tready           : in std_logic;
        mult_m_tdata            : out std_logic_vector(11*4-1 downto 0);
        mult_m_tuser_cb         : out std_logic;
        mult_m_tuser_zf         : out std_logic;
        mult_m_tuser_msn        : out std_logic_vector(3 downto 0)
    );
end entity calc_mult;

architecture rtl of calc_mult is

    component dsp_mul is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            dsp_mul_s_tvalid    : in std_logic;
            dsp_mul_s_tready    : out std_logic;
            dsp_mul_s_tdata_a   : in std_logic_vector(17 downto 0);
            dsp_mul_s_tdata_b   : in std_logic_vector(17 downto 0);

            dsp_mul_m_tvalid    : out std_logic;
            dsp_mul_m_tready    : in std_logic;
            dsp_mul_m_tdata     : out std_logic_vector(35 downto 0)
        );
    end component;

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

    type num_hex_t is array (natural range 0 to 10) of std_logic_vector(3 downto 0);

    signal alu_tvalid           : std_logic;
    signal alu_tready           : std_logic;

    signal alu_loop_tvalid      : std_logic;
    signal alu_loop_a_cnt       : natural range 0 to 10;
    signal alu_loop_b_cnt       : natural range 0 to 10;
    signal alu_loop_a_vec       : num_hex_t;
    signal alu_loop_b_vec       : num_hex_t;

    signal dsp_mul_s_tvalid     : std_logic;
    signal dsp_mul_s_tready     : std_logic;
    signal dsp_mul_s_tdata_a    : std_logic_vector(17 downto 0);
    signal dsp_mul_s_tdata_b    : std_logic_vector(17 downto 0);

    signal dsp_mul_m_tvalid     : std_logic;
    signal dsp_mul_m_tready     : std_logic;
    signal dsp_mul_m_tdata      : std_logic_vector(35 downto 0);

    signal dsp_resetn           : std_logic;

    signal dsp_acc_s_tvalid     : std_logic;
    signal dsp_acc_s_tready     : std_logic;
    signal dsp_acc_s_tdata      : std_logic_vector(47 downto 0);

    signal dsp_acc_m_tvalid     : std_logic;
    signal dsp_acc_m_tready     : std_logic;
    signal dsp_acc_m_tdata      : std_logic_vector(47 downto 0);

    signal alu_res_tvalid       : std_logic;
    signal alu_res_tready       : std_logic;
    signal alu_res_tuser_zf     : std_logic;
    signal alu_res_tuser_msn    : std_logic_vector(3 downto 0);
    signal alu_res_tuser_cb     : std_logic;
    signal dsp_mul_cnt_a        : natural range 0 to 10;
    signal dsp_mul_cnt_b        : natural range 0 to 10;
    signal dsp_acc_cnt_a        : natural range 0 to 10;
    signal dsp_acc_cnt_b        : natural range 0 to 10;

    function slv_to_num_hex(val : std_logic_vector(11*4-1 downto 0)) return num_hex_t is
        variable num : num_hex_t;
    begin
        for i in 0 to 10 loop
            num(i) := val((i+1)*4-1 downto i*4);
        end loop;
        return num;
    end function;


begin

    dsp_mult_inst: dsp_mul port map (
        clk                     => clk,
        resetn                  => resetn,

        dsp_mul_s_tvalid        => dsp_mul_s_tvalid,
        dsp_mul_s_tready        => dsp_mul_s_tready,
        dsp_mul_s_tdata_a       => dsp_mul_s_tdata_a,
        dsp_mul_s_tdata_b       => dsp_mul_s_tdata_b,

        dsp_mul_m_tvalid        => dsp_mul_m_tvalid,
        dsp_mul_m_tready        => dsp_mul_m_tready,
        dsp_mul_m_tdata         => dsp_mul_m_tdata
    );

    dsp_acc_inst: dsp_acc port map (
        clk                     => clk,
        resetn                  => dsp_resetn,

        dsp_acc_s_tvalid        => dsp_acc_s_tvalid,
        dsp_acc_s_tready        => dsp_acc_s_tready,
        dsp_acc_s_tdata         => dsp_acc_s_tdata,

        dsp_acc_m_tvalid        => dsp_acc_m_tvalid,
        dsp_acc_m_tready        => dsp_acc_m_tready,
        dsp_acc_m_tdata         => dsp_acc_m_tdata
    );

    dsp_resetn       <= '0' when resetn = '0' or (alu_tvalid = '1' and alu_tready = '1') else '1';

    alu_tvalid       <= mult_s_tvalid;
    mult_s_tready    <= alu_tready;

    mult_m_tvalid    <= alu_res_tvalid;
    alu_res_tready   <= mult_m_tready;
    mult_m_tdata     <= dsp_acc_m_tdata(43 downto 0);
    mult_m_tuser_cb  <= alu_res_tuser_cb;
    mult_m_tuser_zf  <= alu_res_tuser_zf;
    mult_m_tuser_msn <= alu_res_tuser_msn;

    dsp_mul_m_tready <= '1';
    dsp_acc_m_tready <= '1';

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                alu_tready <= '1';
                alu_loop_tvalid <= '0';
                alu_loop_a_cnt <= 0;
                alu_loop_b_cnt <= 0;
            else

                if alu_tvalid = '1' and alu_tready = '1' then
                    alu_tready <= '0';
                elsif (alu_res_tvalid = '1' and alu_res_tready = '1') then
                    alu_tready <= '1';
                end if;

                if (alu_tvalid = '1' and alu_tready = '1') then
                    alu_loop_tvalid <= '1';
                elsif alu_loop_tvalid = '1' and alu_loop_a_cnt = 10 and alu_loop_b_cnt = 10 then
                    alu_loop_tvalid <= '0';
                end if;

                if (alu_loop_tvalid = '1' and alu_loop_b_cnt = 10) then
                    if (alu_loop_a_cnt = 10) then
                        alu_loop_a_cnt <= 0;
                    else
                        alu_loop_a_cnt <= alu_loop_a_cnt + 1;
                    end if;
                end if;

                if (alu_loop_tvalid = '1') then
                    if (alu_loop_b_cnt = 10) then
                        alu_loop_b_cnt <= 0;
                    else
                        alu_loop_b_cnt <= alu_loop_b_cnt + 1;
                    end if;
                end if;

                if (alu_tvalid = '1' and alu_tready = '1') then
                    alu_loop_a_vec <= slv_to_num_hex(mult_s_tdata_a);
                    alu_loop_b_vec <= slv_to_num_hex(mult_s_tdata_b);
                end if;

            end if;
        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                dsp_mul_s_tvalid <= '0';
            else
                if (alu_loop_tvalid = '1') then
                    dsp_mul_s_tvalid <= '1';
                else
                    dsp_mul_s_tvalid <= '0';
                end if;

            end if;

            if (alu_loop_tvalid = '1') then
                dsp_mul_s_tdata_a <= std_logic_vector(resize(unsigned(alu_loop_a_vec(alu_loop_a_cnt)), 18));
                dsp_mul_s_tdata_b <= std_logic_vector(resize(unsigned(alu_loop_b_vec(alu_loop_b_cnt)), 18));
            end if;

        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                dsp_acc_s_tvalid <= '0';
                dsp_mul_cnt_a <= 0;
                dsp_mul_cnt_b <= 0;
            else

                if (dsp_mul_m_tvalid = '1') then
                    dsp_acc_s_tvalid <= '1';
                else
                    dsp_acc_s_tvalid <= '0';
                end if;

                if (dsp_mul_m_tvalid = '1' and dsp_mul_cnt_b = 10) then
                    if (dsp_mul_cnt_a = 10) then
                        dsp_mul_cnt_a <= 0;
                    else
                        dsp_mul_cnt_a <= dsp_mul_cnt_a + 1;
                    end if;
                end if;

                if (dsp_mul_m_tvalid = '1') then
                    if (dsp_mul_cnt_b = 10) then
                        dsp_mul_cnt_b <= 0;
                    else
                        dsp_mul_cnt_b <= dsp_mul_cnt_b + 1;
                    end if;
                end if;

            end if;

            case dsp_mul_cnt_a is
                when 0 =>
                    dsp_acc_s_tdata <= x"0000000000" & dsp_mul_m_tdata(7 downto 0);
                when 1 =>
                    dsp_acc_s_tdata <= x"000000000" & dsp_mul_m_tdata(7 downto 0) & x"0";
                when 2 =>
                    dsp_acc_s_tdata <= x"00000000" & dsp_mul_m_tdata(7 downto 0) & x"00";
                when 3 =>
                    dsp_acc_s_tdata <= x"0000000" & dsp_mul_m_tdata(7 downto 0) & x"000";
                when 4 =>
                    dsp_acc_s_tdata <= x"000000" & dsp_mul_m_tdata(7 downto 0) & x"0000";
                when 5 =>
                    dsp_acc_s_tdata <= x"00000" & dsp_mul_m_tdata(7 downto 0) & x"00000";
                when 6 =>
                    dsp_acc_s_tdata <= x"0000" & dsp_mul_m_tdata(7 downto 0) & x"000000";
                when 7 =>
                    dsp_acc_s_tdata <= x"000" & dsp_mul_m_tdata(7 downto 0) & x"0000000";
                when 8 =>
                    dsp_acc_s_tdata <= x"00" & dsp_mul_m_tdata(7 downto 0) & x"00000000";
                when 9 =>
                    dsp_acc_s_tdata <= x"0" & dsp_mul_m_tdata(7 downto 0) & x"000000000";
                when 10 =>
                    dsp_acc_s_tdata <= dsp_mul_m_tdata(7 downto 0) & x"0000000000";

                when others =>
                    null;
            end case;

        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                alu_res_tvalid <= '0';
                dsp_acc_cnt_a <= 0;
                dsp_acc_cnt_b <= 0;
            else
                if (dsp_acc_m_tvalid = '1' and dsp_acc_cnt_a = 10 and dsp_acc_cnt_b = 10) then
                    alu_res_tvalid <= '1';
                elsif (alu_res_tready = '1') then
                    alu_res_tvalid <= '0';
                end if;
            end if;

            if (alu_tvalid = '1' and alu_tready = '1') then
                alu_res_tuser_zf <= '1';
            elsif (dsp_mul_s_tvalid = '1' and alu_res_tuser_zf = '1') then
                if (dsp_mul_s_tdata_a(3 downto 0) /= x"0" and dsp_mul_s_tdata_b(3 downto 0) /= x"0") then
                    alu_res_tuser_zf <= '0';
                end if;
            end if;

            if (dsp_acc_m_tvalid = '1' and dsp_acc_cnt_b = 10) then
                if (dsp_acc_cnt_a = 10) then
                    dsp_acc_cnt_a <= 0;
                else
                    dsp_acc_cnt_a <= dsp_acc_cnt_a + 1;
                end if;
            end if;

            if (dsp_acc_m_tvalid = '1') then
                if (dsp_acc_cnt_b = 10) then
                    dsp_acc_cnt_b <= 0;
                else
                    dsp_acc_cnt_b <= dsp_acc_cnt_b + 1;
                end if;
            end if;

            if (alu_tvalid = '1' and alu_tready = '1') then
                alu_res_tuser_msn <= (others => '0');
            else
                case dsp_acc_cnt_a is
                    when 0 =>
                        if (dsp_acc_m_tdata(3 downto 0) /= x"0") then
                            alu_res_tuser_msn <= std_logic_vector(to_unsigned(dsp_acc_cnt_a, 4));
                        end if;
                    when 1 =>
                        if (dsp_acc_m_tdata(7 downto 4) /= x"0") then
                            alu_res_tuser_msn <= std_logic_vector(to_unsigned(dsp_acc_cnt_a, 4));
                        end if;
                    when 2 =>
                        if (dsp_acc_m_tdata(11 downto 8) /= x"0") then
                            alu_res_tuser_msn <= std_logic_vector(to_unsigned(dsp_acc_cnt_a, 4));
                        end if;
                    when 3 =>
                        if (dsp_acc_m_tdata(15 downto 12) /= x"0") then
                            alu_res_tuser_msn <= std_logic_vector(to_unsigned(dsp_acc_cnt_a, 4));
                        end if;
                    when 4 =>
                        if (dsp_acc_m_tdata(19 downto 16) /= x"0") then
                            alu_res_tuser_msn <= std_logic_vector(to_unsigned(dsp_acc_cnt_a, 4));
                        end if;
                    when 5 =>
                        if (dsp_acc_m_tdata(23 downto 20) /= x"0") then
                            alu_res_tuser_msn <= std_logic_vector(to_unsigned(dsp_acc_cnt_a, 4));
                        end if;
                    when 6 =>
                        if (dsp_acc_m_tdata(27 downto 24) /= x"0") then
                            alu_res_tuser_msn <= std_logic_vector(to_unsigned(dsp_acc_cnt_a, 4));
                        end if;
                    when 7 =>
                        if (dsp_acc_m_tdata(31 downto 28) /= x"0") then
                            alu_res_tuser_msn <= std_logic_vector(to_unsigned(dsp_acc_cnt_a, 4));
                        end if;
                    when 8 =>
                        if (dsp_acc_m_tdata(35 downto 32) /= x"0") then
                            alu_res_tuser_msn <= std_logic_vector(to_unsigned(dsp_acc_cnt_a, 4));
                        end if;
                    when 9 =>
                        if (dsp_acc_m_tdata(39 downto 36) /= x"0") then
                            alu_res_tuser_msn <= std_logic_vector(to_unsigned(dsp_acc_cnt_a, 4));
                        end if;
                    when 10 =>
                        if (dsp_acc_m_tdata(43 downto 40) /= x"0") then
                            alu_res_tuser_msn <= std_logic_vector(to_unsigned(dsp_acc_cnt_a, 4));
                        end if;

                    when others =>
                        null;
                end case;
            end if;

            if (dsp_acc_m_tvalid = '1' and dsp_acc_cnt_a = 10 and dsp_acc_cnt_b = 10) then
                if dsp_acc_m_tdata(47 downto 44) /= x"0000" then
                    alu_res_tuser_cb <= '1';
                else
                    alu_res_tuser_cb <= '0';
                end if;
            end if;

        end if;
    end process;


end architecture;
