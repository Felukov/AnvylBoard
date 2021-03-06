library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;
use ieee.std_logic_unsigned.all;

entity calc_alu is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        alu_s_tvalid            : in std_logic;
        alu_s_tready            : out std_logic;
        alu_s_tdata_a           : in std_logic_vector(11*4-1 downto 0);
        alu_s_tdata_a_sign      : in std_logic;
        alu_s_tdata_b           : in std_logic_vector(11*4-1 downto 0);
        alu_s_tdata_b_sign      : in std_logic;
        alu_s_tdata_op          : in std_logic_vector(3 downto 0);

        alu_m_tvalid            : out std_logic;
        alu_m_tready            : in std_logic;
        alu_m_tdata             : out std_logic_vector(11*4-1 downto 0);
        alu_m_tdata_sign        : out std_logic;
        alu_m_tuser_cb          : out std_logic;
        alu_m_tuser_zf          : out std_logic;
        alu_m_tuser_msn         : out std_logic_vector(3 downto 0)          -- most significant nibble

    );
end entity calc_alu;

architecture rtl of calc_alu is
    type state_t is (ST_IDLE, ST_CORRECT_A, ST_CORRECT_B, ST_CALC, ST_CORRECT_RES, ST_DONE);

    constant ALU_ADD            : std_logic_vector(3 downto 0) := "0000";
    constant ALU_SUB            : std_logic_vector(3 downto 0) := "0001";
    constant ALU_AND            : std_logic_vector(3 downto 0) := "0010";
    constant ALU_OR             : std_logic_vector(3 downto 0) := "0011";
    constant ALU_XOR            : std_logic_vector(3 downto 0) := "0100";
    constant ALU_INV            : std_logic_vector(3 downto 0) := "0101";
    constant ALU_MUL            : std_logic_vector(3 downto 0) := "0110";
    constant ALU_SHL            : std_logic_vector(3 downto 0) := "1000";
    constant ALU_SHR            : std_logic_vector(3 downto 0) := "1001";
    constant ALU_DIV            : std_logic_vector(3 downto 0) := "1100";
    constant ALU_MOD            : std_logic_vector(3 downto 0) := "1101";
    constant ALU_NOT            : std_logic_vector(3 downto 0) := "1110";

    component calc_base_alu is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            alu_s_tvalid        : in std_logic;
            alu_s_tready        : out std_logic;
            alu_s_tdata_a       : in std_logic_vector(11*4-1 downto 0);
            alu_s_tdata_b       : in std_logic_vector(11*4-1 downto 0);
            alu_s_tdata_op      : in std_logic_vector(2 downto 0);

            alu_m_tvalid        : out std_logic;
            alu_m_tready        : in std_logic;
            alu_m_tdata         : out std_logic_vector(11*4-1 downto 0);
            alu_m_tuser_cb      : out std_logic;                            -- carry bit
            alu_m_tuser_zf      : out std_logic;                            -- zero flag
            alu_m_tuser_msn     : out std_logic_vector(3 downto 0)          -- most significant nibble
        );
    end component;

    component calc_mult is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            mult_s_tvalid       : in std_logic;
            mult_s_tready       : out std_logic;
            mult_s_tdata_a      : in std_logic_vector(11*4-1 downto 0);
            mult_s_tdata_b      : in std_logic_vector(11*4-1 downto 0);

            mult_m_tvalid       : out std_logic;
            mult_m_tready       : in std_logic;
            mult_m_tdata        : out std_logic_vector(11*4-1 downto 0);
            mult_m_tuser_cb     : out std_logic;
            mult_m_tuser_zf     : out std_logic;
            mult_m_tuser_msn    : out std_logic_vector(3 downto 0)
        );
    end component;

    component calc_shift is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            shift_s_tvalid      : in std_logic;
            shift_s_tready      : out std_logic;
            shift_s_tdata_val   : in std_logic_vector(11*4-1 downto 0);
            shift_s_tdata_op    : in std_logic;

            shift_m_tvalid      : out std_logic;
            shift_m_tready      : in std_logic;
            shift_m_tdata       : out std_logic_vector(11*4-1 downto 0);
            shift_m_tuser_cb    : out std_logic;
            shift_m_tuser_zf    : out std_logic;
            shift_m_tuser_msn   : out std_logic_vector(3 downto 0)
        );
    end component;

    component calc_not is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            not_s_tvalid        : in std_logic;
            not_s_tready        : out std_logic;
            not_s_tdata_val     : in std_logic_vector(11*4-1 downto 0);

            not_m_tvalid        : out std_logic;
            not_m_tready        : in std_logic;
            not_m_tdata         : out std_logic_vector(11*4-1 downto 0);
            not_m_tuser_cb      : out std_logic;
            not_m_tuser_zf      : out std_logic;
            not_m_tuser_msn     : out std_logic_vector(3 downto 0)
        );
    end component;

    component calc_div is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            div_s_tvalid        : in std_logic;
            div_s_tready        : out std_logic;
            div_s_tdata_a       : in std_logic_vector(11*4-1 downto 0);
            div_s_tdata_b       : in std_logic_vector(11*4-1 downto 0);
            div_s_tdata_op      : in std_logic;

            div_m_tvalid        : out std_logic;
            div_m_tready        : in std_logic;
            div_m_tdata         : out std_logic_vector(11*4-1 downto 0);
            div_m_tuser_cb      : out std_logic;
            div_m_tuser_zf      : out std_logic;
            div_m_tuser_msn     : out std_logic_vector(3 downto 0)
        );
    end component;

    signal state : state_t;

    signal alu_req_tvalid       : std_logic;
    signal alu_req_tready       : std_logic;

    signal alu_res_tvalid       : std_logic;
    signal alu_res_tready       : std_logic;
    signal alu_res_tdata        : std_logic_vector(11*4-1 downto 0);
    signal alu_res_tdata_sign   : std_logic;
    signal alu_res_tuser_cb     : std_logic;
    signal alu_res_tuser_zf     : std_logic;
    signal alu_res_tuser_msn    : std_logic_vector(3 downto 0);

    signal base_alu_s_tvalid    : std_logic;
    signal base_alu_s_tready    : std_logic;
    signal base_alu_s_tdata_a   : std_logic_vector(11*4-1 downto 0);
    signal base_alu_s_tdata_b   : std_logic_vector(11*4-1 downto 0);
    signal base_alu_s_tdata_op  : std_logic_vector(2 downto 0);
    signal base_alu_m_tvalid    : std_logic;
    signal base_alu_m_tdata     : std_logic_vector(11*4-1 downto 0);
    signal base_alu_m_tuser_cb  : std_logic;
    signal base_alu_m_tuser_zf  : std_logic;
    signal base_alu_m_tuser_msn : std_logic_vector(3 downto 0);

    signal mult_s_tvalid        : std_logic;
    signal mult_s_tready        : std_logic;
    signal mult_s_tdata_a       : std_logic_vector(11*4-1 downto 0);
    signal mult_s_tdata_b       : std_logic_vector(11*4-1 downto 0);
    signal mult_m_tvalid        : std_logic;
    signal mult_m_tdata         : std_logic_vector(11*4-1 downto 0);
    signal mult_m_tuser_cb      : std_logic;
    signal mult_m_tuser_zf      : std_logic;
    signal mult_m_tuser_msn     : std_logic_vector(3 downto 0);

    signal div_s_tvalid         : std_logic;
    signal div_s_tready         : std_logic;
    signal div_s_tdata_a        : std_logic_vector(11*4-1 downto 0);
    signal div_s_tdata_b        : std_logic_vector(11*4-1 downto 0);
    signal div_s_tdata_op       : std_logic;
    signal div_m_tvalid         : std_logic;
    signal div_m_tdata          : std_logic_vector(11*4-1 downto 0);
    signal div_m_tuser_cb       : std_logic;
    signal div_m_tuser_zf       : std_logic;
    signal div_m_tuser_msn      : std_logic_vector(3 downto 0);

    signal shift_s_tvalid       : std_logic;
    signal shift_s_tready       : std_logic;
    signal shift_s_tdata_val    : std_logic_vector(11*4-1 downto 0);
    signal shift_s_tdata_op     : std_logic;
    signal shift_m_tvalid       : std_logic;
    signal shift_m_tdata        : std_logic_vector(11*4-1 downto 0);
    signal shift_m_tuser_cb     : std_logic;
    signal shift_m_tuser_zf     : std_logic;
    signal shift_m_tuser_msn    : std_logic_vector(3 downto 0);

    signal not_s_tvalid         : std_logic;
    signal not_s_tready         : std_logic;
    signal not_s_tdata_val      : std_logic_vector(11*4-1 downto 0);
    signal not_m_tvalid         : std_logic;
    signal not_m_tdata          : std_logic_vector(11*4-1 downto 0);
    signal not_m_tuser_cb       : std_logic;
    signal not_m_tuser_zf       : std_logic;
    signal not_m_tuser_msn      : std_logic_vector(3 downto 0);

    signal buf_tdata_op         : std_logic_vector(3 downto 0);
    signal buf_tdata_b          : std_logic_vector(11*4-1 downto 0);
    signal buf_tdata_a_sign     : std_logic;
    signal buf_tdata_b_sign     : std_logic;

    signal cor_tdata_a          : std_logic_vector(11*4-1 downto 0);

begin

    calc_base_alu_inst: calc_base_alu port map (
        clk                 => clk,
        resetn              => resetn,

        alu_s_tvalid        => base_alu_s_tvalid,
        alu_s_tready        => base_alu_s_tready,
        alu_s_tdata_a       => base_alu_s_tdata_a,
        alu_s_tdata_b       => base_alu_s_tdata_b,
        alu_s_tdata_op      => base_alu_s_tdata_op,

        alu_m_tvalid        => base_alu_m_tvalid,
        alu_m_tready        => '1',
        alu_m_tdata         => base_alu_m_tdata,
        alu_m_tuser_cb      => base_alu_m_tuser_cb,
        alu_m_tuser_zf      => base_alu_m_tuser_zf,
        alu_m_tuser_msn     => base_alu_m_tuser_msn
    );


    calc_mult_inst: calc_mult port map (
        clk                 => clk,
        resetn              => resetn,

        mult_s_tvalid       => mult_s_tvalid,
        mult_s_tready       => mult_s_tready,
        mult_s_tdata_a      => mult_s_tdata_a,
        mult_s_tdata_b      => mult_s_tdata_b,

        mult_m_tvalid       => mult_m_tvalid,
        mult_m_tready       => '1',
        mult_m_tdata        => mult_m_tdata,
        mult_m_tuser_cb     => mult_m_tuser_cb,
        mult_m_tuser_zf     => mult_m_tuser_zf,
        mult_m_tuser_msn    => mult_m_tuser_msn
    );


    calc_shift_inst: calc_shift port map (
        clk                 => clk,
        resetn              => resetn,

        shift_s_tvalid      => shift_s_tvalid,
        shift_s_tready      => shift_s_tready,
        shift_s_tdata_val   => shift_s_tdata_val,
        shift_s_tdata_op    => shift_s_tdata_op,

        shift_m_tvalid      => shift_m_tvalid,
        shift_m_tready      => '1',
        shift_m_tdata       => shift_m_tdata,
        shift_m_tuser_cb    => shift_m_tuser_cb,
        shift_m_tuser_zf    => shift_m_tuser_zf,
        shift_m_tuser_msn   => shift_m_tuser_msn
    );


    calc_not_inst: calc_not port map (
        clk                 => clk,
        resetn              => resetn,

        not_s_tvalid        => not_s_tvalid,
        not_s_tready        => not_s_tready,
        not_s_tdata_val     => not_s_tdata_val,

        not_m_tvalid        => not_m_tvalid,
        not_m_tready        => '1',
        not_m_tdata         => not_m_tdata,
        not_m_tuser_cb      => not_m_tuser_cb,
        not_m_tuser_zf      => not_m_tuser_zf,
        not_m_tuser_msn     => not_m_tuser_msn
    );


    calc_div_inst: calc_div port map (
        clk                 => clk,
        resetn              => resetn,

        div_s_tvalid        => div_s_tvalid,
        div_s_tready        => div_s_tready,
        div_s_tdata_a       => div_s_tdata_a,
        div_s_tdata_b       => div_s_tdata_b,
        div_s_tdata_op      => div_s_tdata_op,

        div_m_tvalid        => div_m_tvalid,
        div_m_tready        => '1',
        div_m_tdata         => div_m_tdata,
        div_m_tuser_cb      => div_m_tuser_cb,
        div_m_tuser_zf      => div_m_tuser_zf,
        div_m_tuser_msn     => div_m_tuser_msn
    );


    alu_req_tvalid <= alu_s_tvalid;
    alu_s_tready <= alu_req_tready;

    alu_m_tvalid <= alu_res_tvalid;
    alu_res_tready <= alu_m_tready;
    alu_m_tdata <= alu_res_tdata;
    alu_m_tdata_sign <= alu_res_tdata_sign;
    alu_m_tuser_cb <= alu_res_tuser_cb;
    alu_m_tuser_msn <= alu_res_tuser_msn;
    alu_m_tuser_zf <= alu_res_tuser_zf;


    fsm_proc: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                state <= ST_IDLE;
            else

                case state is
                    when ST_IDLE =>
                        if alu_req_tvalid = '1' and alu_req_tready = '1' then
                            state <= ST_CORRECT_A;
                        end if;

                    when ST_CORRECT_A =>
                        if base_alu_m_tvalid = '1' then
                            state <= ST_CORRECT_B;
                        end if;

                    when ST_CORRECT_B =>
                        if base_alu_m_tvalid = '1' then
                            state <= ST_CALC;
                        end if;

                    when ST_CALC =>
                        if (base_alu_m_tvalid = '1' or mult_m_tvalid = '1' or shift_m_tvalid = '1' or div_m_tvalid = '1' or not_m_tvalid = '1') then
                            state <= ST_CORRECT_RES;
                        end if;

                    when ST_CORRECT_RES =>
                        if base_alu_m_tvalid = '1' then
                            state <= ST_DONE;
                        end if;

                    when ST_DONE =>
                        if (alu_res_tvalid = '1' and alu_res_tready = '1') then
                            state <= ST_IDLE;

                        end if;

                    when others =>
                        state <= ST_IDLE;
                end case;

            end if;
        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                alu_req_tready <= '1';
            else
                if (alu_req_tvalid = '1' and alu_req_tready = '1') then
                    alu_req_tready <= '0';
                elsif alu_res_tvalid = '1' and alu_res_tready = '1' then
                    alu_req_tready <= '1';
                end if;
            end if;

            if (alu_req_tvalid = '1' and alu_req_tready = '1') then
                buf_tdata_op <= alu_s_tdata_op;
                buf_tdata_b <= alu_s_tdata_b;
                buf_tdata_b_sign <= alu_s_tdata_b_sign;
                buf_tdata_a_sign <= alu_s_tdata_a_sign;
            end if;

        end if;
    end process;

    alu_loader_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                base_alu_s_tvalid <= '0';
            else

                if (state = ST_IDLE and alu_req_tvalid = '1' and alu_req_tready = '1') then
                    base_alu_s_tvalid <= '1';
                elsif state = ST_CORRECT_A and base_alu_m_tvalid = '1' then
                    base_alu_s_tvalid <= '1';
                elsif state = ST_CORRECT_B and base_alu_m_tvalid = '1' then
                    if (buf_tdata_op = ALU_ADD or buf_tdata_op = ALU_SUB or buf_tdata_op = ALU_AND or
                        buf_tdata_op = ALU_OR or buf_tdata_op = ALU_XOR or buf_tdata_op = ALU_INV)
                    then
                        base_alu_s_tvalid <= '1';
                    else
                        base_alu_s_tvalid <= '0';
                    end if;
                elsif state = ST_CALC and (base_alu_m_tvalid = '1' or mult_m_tvalid = '1' or shift_m_tvalid = '1' or div_m_tvalid = '1' or not_m_tvalid = '1') then
                    base_alu_s_tvalid <= '1';
                elsif base_alu_s_tready = '1' then
                    base_alu_s_tvalid <= '0';
                end if;

            end if;

            if (state = ST_IDLE and alu_req_tvalid = '1' and alu_req_tready = '1') then
                -- load a
                base_alu_s_tdata_op <= ALU_ADD(2 downto 0);
                if alu_s_tdata_a_sign = '1' and (buf_tdata_op = ALU_ADD or buf_tdata_op = ALU_AND or
                    buf_tdata_op = ALU_OR or buf_tdata_op = ALU_XOR or
                    buf_tdata_op = ALU_INV or buf_tdata_op = ALU_SUB)
                then
                    base_alu_s_tdata_a <= not alu_s_tdata_a;
                else
                    base_alu_s_tdata_a <= alu_s_tdata_a;
                end if;

                if alu_s_tdata_a_sign = '1' and (buf_tdata_op = ALU_ADD or buf_tdata_op = ALU_AND or
                    buf_tdata_op = ALU_OR or buf_tdata_op = ALU_XOR or
                    buf_tdata_op = ALU_INV or buf_tdata_op = ALU_SUB)
                then
                    base_alu_s_tdata_b(11*4-1 downto 1) <= (others => '0');
                    base_alu_s_tdata_b(0) <= '1';
                else
                    base_alu_s_tdata_b <= (others => '0');
                end if;

            elsif state = ST_CORRECT_A and base_alu_m_tvalid = '1' then
                -- load b
                base_alu_s_tdata_op <= ALU_ADD(2 downto 0);

                if (buf_tdata_b_sign = '1' and (buf_tdata_op = ALU_ADD or buf_tdata_op = ALU_AND or
                    buf_tdata_op = ALU_OR or buf_tdata_op = ALU_XOR or buf_tdata_op = ALU_INV)) or
                    (buf_tdata_b_sign = '0' and buf_tdata_op = ALU_SUB)
                then
                    base_alu_s_tdata_a <= not buf_tdata_b;
                else
                    base_alu_s_tdata_a <= buf_tdata_b;
                end if;

                if (buf_tdata_b_sign = '1' and (buf_tdata_op = ALU_ADD or buf_tdata_op = ALU_AND or
                    buf_tdata_op = ALU_OR or buf_tdata_op = ALU_XOR or buf_tdata_op = ALU_INV)) or
                    (buf_tdata_b_sign = '0' and buf_tdata_op = ALU_SUB)
                then
                    base_alu_s_tdata_b(11*4-1 downto 1) <= (others => '0');
                    base_alu_s_tdata_b(0) <= '1';
                else
                    base_alu_s_tdata_b <= (others => '0');
                end if;

            elsif state = ST_CORRECT_B and base_alu_m_tvalid = '1' then
                -- load a and b
                if (buf_tdata_op = ALU_ADD or buf_tdata_op = ALU_SUB) then
                    base_alu_s_tdata_op <= ALU_ADD(2 downto 0);
                else
                    base_alu_s_tdata_op <= buf_tdata_op(2 downto 0);
                end if;

                base_alu_s_tdata_a <= cor_tdata_a;
                base_alu_s_tdata_b <= base_alu_m_tdata;

            elsif state = ST_CALC and base_alu_m_tvalid = '1' then
                -- correct result
                base_alu_s_tdata_op <= ALU_ADD(2 downto 0);

                if ((buf_tdata_op = ALU_ADD or buf_tdata_op = ALU_SUB) and base_alu_m_tdata(4*11-1) = '1') then
                    base_alu_s_tdata_a <= not base_alu_m_tdata;
                else
                    base_alu_s_tdata_a <= base_alu_m_tdata;
                end if;

                if ((buf_tdata_op = ALU_ADD or buf_tdata_op = ALU_SUB) and base_alu_m_tdata(4*11-1) = '1') then
                    base_alu_s_tdata_b(11*4-1 downto 1) <= (others => '0');
                    base_alu_s_tdata_b(0) <= '1';
                else
                    base_alu_s_tdata_b <= (others => '0');
                end if;
            elsif state = ST_CALC and mult_m_tvalid = '1' then
                -- correct result
                base_alu_s_tdata_op <= ALU_ADD(2 downto 0);

                if (mult_m_tdata(4*11-1) = '1') then
                    base_alu_s_tdata_a <= not mult_m_tdata;
                else
                    base_alu_s_tdata_a <= mult_m_tdata;
                end if;

                if (mult_m_tdata(4*11-1) = '1') then
                    base_alu_s_tdata_b(11*4-1 downto 1) <= (others => '0');
                    base_alu_s_tdata_b(0) <= '1';
                else
                    base_alu_s_tdata_b <= (others => '0');
                end if;
            elsif state = ST_CALC and div_m_tvalid = '1' then
                base_alu_s_tdata_op <= ALU_ADD(2 downto 0);

                if (div_m_tdata(4*11-1) = '1') then
                    base_alu_s_tdata_a <= not div_m_tdata;
                else
                    base_alu_s_tdata_a <= div_m_tdata;
                end if;

                if (div_m_tdata(4*11-1) = '1') then
                    base_alu_s_tdata_b(11*4-1 downto 1) <= (others => '0');
                    base_alu_s_tdata_b(0) <= '1';
                else
                    base_alu_s_tdata_b <= (others => '0');
                end if;
            elsif state = ST_CALC and not_m_tvalid = '1' then
                base_alu_s_tdata_op <= ALU_ADD(2 downto 0);
                base_alu_s_tdata_a <= not_m_tdata;
                base_alu_s_tdata_b <= (others => '0');
            elsif state = ST_CALC and shift_m_tvalid = '1' then
                base_alu_s_tdata_op <= ALU_ADD(2 downto 0);
                base_alu_s_tdata_a <= shift_m_tdata;
                base_alu_s_tdata_b <= (others => '0');
            end if;

        end if;
    end process;

    mul_loader_proc: process (clk) begin
        if rising_edge(clk) then
            if (resetn = '0') then
                mult_s_tvalid <= '0';
            else
                if state = ST_CORRECT_B and base_alu_m_tvalid = '1' then
                    if (buf_tdata_op = ALU_MUL) then
                        mult_s_tvalid <= '1';
                    else
                        mult_s_tvalid <= '0';
                    end if;
                elsif (mult_s_tready = '1') then
                    mult_s_tvalid <= '0';
                end if;
            end if;

            mult_s_tdata_a <= cor_tdata_a;
            mult_s_tdata_b <= base_alu_m_tdata;

        end if;
    end process;

    div_loader_proc: process (clk) begin
        if rising_edge(clk) then
            if (resetn = '0') then
                div_s_tvalid <= '0';
            else
                if state = ST_CORRECT_B and base_alu_m_tvalid = '1' then
                    if (buf_tdata_op = ALU_DIV or buf_tdata_op = ALU_MOD) then
                        div_s_tvalid <= '1';
                    else
                        div_s_tvalid <= '0';
                    end if;
                elsif (div_s_tready = '1') then
                    div_s_tvalid <= '0';
                end if;
            end if;

            div_s_tdata_a <= cor_tdata_a;
            div_s_tdata_b <= base_alu_m_tdata;

            if (buf_tdata_op = ALU_DIV) then
                div_s_tdata_op <= '0';
            else
                div_s_tdata_op <= '1';
            end if;

        end if;
    end process;

    shift_loader_proc: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                shift_s_tvalid <= '0';
            else

                if state = ST_CORRECT_B and base_alu_m_tvalid = '1' then
                    if (buf_tdata_op = ALU_SHL or buf_tdata_op = ALU_SHR) then
                        shift_s_tvalid <= '1';
                    else
                        shift_s_tvalid <= '0';
                    end if;
                elsif shift_s_tready = '1' then
                    shift_s_tvalid <= '0';
                end if;

            end if;

            shift_s_tdata_val <= cor_tdata_a;
            shift_s_tdata_op <= buf_tdata_op(0);

        end if;
    end process;

    not_loader_proc: process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                not_s_tvalid <= '0';
            else

                if state = ST_CORRECT_B and base_alu_m_tvalid = '1' then
                    if (buf_tdata_op = ALU_NOT) then
                        not_s_tvalid <= '1';
                    else
                        not_s_tvalid <= '0';
                    end if;
                elsif not_s_tready = '1' then
                    not_s_tvalid <= '0';
                end if;

            end if;

            not_s_tdata_val <= cor_tdata_a;

        end if;
    end process;

    alu_res_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                alu_res_tvalid <= '0';
            else
                if state = ST_CORRECT_RES and base_alu_m_tvalid = '1' then
                    alu_res_tvalid <= '1';
                elsif alu_res_tready = '1' then
                    alu_res_tvalid <= '0';
                end if;
            end if;

            if state = ST_CORRECT_A and base_alu_m_tvalid = '1' then
                -- save a
                cor_tdata_a <= base_alu_m_tdata;
            end if;

            if state = ST_CORRECT_RES and base_alu_m_tvalid = '1' then
                -- save result
                alu_res_tdata <= base_alu_m_tdata;
            end if;

            if (state = ST_CORRECT_RES and base_alu_m_tvalid = '1') then
                alu_res_tuser_msn <= base_alu_m_tuser_msn;
            end if;

            if (state = ST_CALC and base_alu_m_tvalid = '1') then
                if (buf_tdata_op = ALU_ADD or buf_tdata_op = ALU_SUB) then
                    alu_res_tdata_sign <= base_alu_m_tdata(11*4-1);
                else
                    alu_res_tdata_sign <= '0';
                end if;

                alu_res_tuser_cb <= base_alu_m_tuser_cb;
                alu_res_tuser_zf <= base_alu_m_tuser_zf;

            elsif state = ST_CALC and not_m_tvalid = '1' then
                alu_res_tdata_sign <= '0';
                alu_res_tuser_cb <= shift_m_tuser_cb;
                alu_res_tuser_zf <= shift_m_tuser_zf;

            elsif state = ST_CALC and shift_m_tvalid = '1' then
                alu_res_tdata_sign <= buf_tdata_a_sign;
                alu_res_tuser_cb <= shift_m_tuser_cb;
                alu_res_tuser_zf <= shift_m_tuser_zf;

            elsif state = ST_CALC and mult_m_tvalid = '1' then
                alu_res_tdata_sign <= not mult_m_tuser_zf and (buf_tdata_a_sign xor buf_tdata_b_sign);
                alu_res_tuser_cb <= mult_m_tuser_cb;
                alu_res_tuser_zf <= mult_m_tuser_zf;

            elsif state = ST_CALC and div_m_tvalid = '1' then
                alu_res_tdata_sign <= not div_m_tuser_zf and (buf_tdata_a_sign xor buf_tdata_b_sign);
                alu_res_tuser_cb <= div_m_tuser_cb;
                alu_res_tuser_zf <= div_m_tuser_zf;

            end if;

        end if;
    end process;

end architecture;
