library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;
use ieee.std_logic_unsigned.all;

entity calc_base_alu is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        alu_s_tvalid            : in std_logic;
        alu_s_tready            : out std_logic;
        alu_s_tdata_a           : in std_logic_vector(11*4-1 downto 0);
        alu_s_tdata_b           : in std_logic_vector(11*4-1 downto 0);
        alu_s_tdata_op          : in std_logic_vector(2 downto 0);

        alu_m_tvalid            : out std_logic;
        alu_m_tready            : in std_logic;
        alu_m_tdata             : out std_logic_vector(11*4-1 downto 0);
        alu_m_tuser_cb          : out std_logic;
        alu_m_tuser_zf          : out std_logic
    );
end entity calc_base_alu;

architecture rtl of calc_base_alu is

    constant ALU_ADD            : std_logic_vector(2 downto 0) := "000";
    constant ALU_AND            : std_logic_vector(2 downto 0) := "010";
    constant ALU_OR             : std_logic_vector(2 downto 0) := "011";
    constant ALU_XOR            : std_logic_vector(2 downto 0) := "100";
    constant ALU_INV            : std_logic_vector(2 downto 0) := "101";

    type num_hex_t is array (natural range 0 to 10) of std_logic_vector(3 downto 0);

    signal alu_tvalid           : std_logic;
    signal alu_tready           : std_logic;

    signal alu_loop_tvalid      : std_logic;
    signal alu_loop_cnt         : natural range 0 to 10;
    signal alu_loop_op          : std_logic_vector(2 downto 0);
    signal alu_loop_a_vec       : num_hex_t;
    signal alu_loop_b_vec       : num_hex_t;

    signal alu_calc_tvalid      : std_logic;
    signal alu_calc_tdata_a     : unsigned(3 downto 0);
    signal alu_calc_tdata_b     : unsigned(3 downto 0);
    signal alu_calc_tdata_cb    : unsigned(3 downto 0);

    signal alu_res_tvalid       : std_logic;
    signal alu_res_tready       : std_logic;
    signal alu_res_tdata        : num_hex_t;
    signal alu_res_tuser_zf     : std_logic;
    signal alu_calc_cnt         : natural range 0 to 10;

    signal add_calc_tdata       : unsigned(4 downto 0);
    signal and_calc_tdata       : std_logic_vector(3 downto 0);
    signal or_calc_tdata        : std_logic_vector(3 downto 0);
    signal xor_calc_tdata       : std_logic_vector(3 downto 0);
    signal inv_calc_tdata       : std_logic_vector(3 downto 0);

    function slv_to_num_hex(val : std_logic_vector(11*4-1 downto 0)) return num_hex_t is
        variable num : num_hex_t;
    begin
        for i in 0 to 10 loop
            num(i) := val((i+1)*4-1 downto i*4);
        end loop;
        return num;
    end function;

    function num_hex_to_slv(num : num_hex_t) return std_logic_vector is
        variable vec : std_logic_vector(11*4-1 downto 0);
    begin
        for i in 0 to 10 loop
            vec((i+1)*4-1 downto i*4) := num(i);
        end loop;
        return vec;
    end function;

begin

    alu_tvalid <= alu_s_tvalid;
    alu_s_tready <= alu_tready;

    alu_m_tvalid <= alu_res_tvalid;
    alu_res_tready <= alu_m_tready;
    alu_m_tdata <= num_hex_to_slv(alu_res_tdata);
    alu_m_tuser_cb <= '1' when alu_calc_tdata_cb = "00001" else '0';
    alu_m_tuser_zf <= alu_res_tuser_zf;

    add_calc_tdata <= '0' & alu_calc_tdata_a + alu_calc_tdata_b + alu_calc_tdata_cb;
    and_calc_tdata <= std_logic_vector(alu_calc_tdata_a) and std_logic_vector(alu_calc_tdata_b);
    or_calc_tdata <= std_logic_vector(alu_calc_tdata_a) or std_logic_vector(alu_calc_tdata_b);
    xor_calc_tdata <= std_logic_vector(alu_calc_tdata_a) xor std_logic_vector(alu_calc_tdata_b);
    inv_calc_tdata <= not std_logic_vector(alu_calc_tdata_a);

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                alu_tready <= '1';
                alu_loop_tvalid <= '0';
            else

                if alu_tvalid = '1' and alu_tready = '1' then
                    alu_tready <= '0';
                elsif (alu_res_tvalid = '1' and alu_res_tready = '1') then
                    alu_tready <= '1';
                end if;

                if (alu_tvalid = '1' and alu_tready = '1') then
                    alu_loop_tvalid <= '1';
                elsif alu_loop_tvalid = '1' and alu_loop_cnt = 10 then
                    alu_loop_tvalid <= '0';
                end if;

                if (alu_tvalid = '1' and alu_tready = '1') then
                    alu_loop_op <= alu_s_tdata_op;
                    alu_loop_a_vec <= slv_to_num_hex(alu_s_tdata_a);
                    alu_loop_b_vec <= slv_to_num_hex(alu_s_tdata_b);
                end if;

            end if;
        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                alu_calc_tvalid <= '0';
                alu_loop_cnt <= 0;
            else
                alu_calc_tvalid <= alu_loop_tvalid;

                if (alu_loop_tvalid = '1') then
                    if (alu_loop_cnt = 10) then
                        alu_loop_cnt <= 0;
                    else
                        alu_loop_cnt <= alu_loop_cnt + 1;
                    end if;
                end if;

            end if;

            if (alu_loop_tvalid = '1') then
                alu_calc_tdata_a <= unsigned(alu_loop_a_vec(alu_loop_cnt));
                alu_calc_tdata_b <= unsigned(alu_loop_b_vec(alu_loop_cnt));

                if (alu_loop_cnt = 0) then
                    alu_calc_tdata_cb <= "0000";
                else
                    case alu_loop_op is
                        when ALU_ADD =>
                            if (add_calc_tdata(4) = '1') then
                                alu_calc_tdata_cb <= "0001";
                            else
                                alu_calc_tdata_cb <= "0000";
                            end if;

                        when others =>
                            alu_calc_tdata_cb <= "0000";

                    end case;
                end if;

            end if;

        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                alu_res_tvalid <= '0';
                alu_calc_cnt <= 0;
            else

                if (alu_calc_tvalid = '1' and alu_calc_cnt = 10) then
                    alu_res_tvalid <= '1';
                elsif (alu_res_tready = '1') then
                    alu_res_tvalid <= '0';
                end if;

                if (alu_calc_tvalid = '1') then
                    if (alu_calc_cnt = 10) then
                        alu_calc_cnt <= 0;
                    else
                        alu_calc_cnt <= alu_calc_cnt + 1;
                    end if;
                end if;

            end if;

            if (alu_tvalid = '1' and alu_tready = '1') then
                alu_res_tuser_zf <= '1';
            elsif (alu_calc_tvalid = '1' and alu_res_tuser_zf = '1') then
                case alu_loop_op is
                    when ALU_AND =>
                        if and_calc_tdata /= x"0" then
                            alu_res_tuser_zf <= '0';
                        end if;

                    when ALU_OR =>
                        if or_calc_tdata /= x"0" then
                            alu_res_tuser_zf <= '0';
                        end if;

                    when ALU_XOR =>
                        if xor_calc_tdata /= x"0" then
                            alu_res_tuser_zf <= '0';
                        end if;

                    when ALU_INV =>
                        if inv_calc_tdata /= x"0" then
                            alu_res_tuser_zf <= '0';
                        end if;


                    when others =>
                        if add_calc_tdata(3 downto 0) /= x"0" then
                            alu_res_tuser_zf <= '0';
                        end if;

                end case;
            end if;

            if (alu_calc_tvalid = '1') then
                case alu_loop_op is
                    when ALU_AND =>
                        alu_res_tdata(alu_calc_cnt) <= and_calc_tdata;

                    when ALU_OR =>
                        alu_res_tdata(alu_calc_cnt) <= or_calc_tdata;

                    when ALU_XOR =>
                        alu_res_tdata(alu_calc_cnt) <= xor_calc_tdata;

                    when ALU_INV =>
                        alu_res_tdata(alu_calc_cnt) <=inv_calc_tdata;

                    when others =>
                        alu_res_tdata(alu_calc_cnt) <= std_logic_vector(add_calc_tdata(3 downto 0));

                end case;
            end if;

        end if;
    end process;

end architecture;
