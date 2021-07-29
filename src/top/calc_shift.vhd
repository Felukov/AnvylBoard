library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;
use ieee.std_logic_unsigned.all;

entity calc_shift is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        shift_s_tvalid          : in std_logic;
        shift_s_tready          : out std_logic;
        shift_s_tdata_val       : in std_logic_vector(11*4-1 downto 0);
        shift_s_tdata_op        : in std_logic;

        shift_m_tvalid          : out std_logic;
        shift_m_tready          : in std_logic;
        shift_m_tdata           : out std_logic_vector(11*4-1 downto 0);
        shift_m_tuser_cb        : out std_logic;
        shift_m_tuser_zf        : out std_logic;
        shift_m_tuser_msn       : out std_logic_vector(3 downto 0)
    );
end entity calc_shift;

architecture rtl of calc_shift is
    type num_hex_t is array (natural range 0 to 10) of std_logic_vector(3 downto 0);

    signal req_tvalid           : std_logic;
    signal req_tready           : std_logic;
    signal req_tdata            : std_logic_vector(11*4-1 downto 0);

    signal shift_l              : std_logic_vector(11*4-1 downto 0);
    signal shift_r              : std_logic_vector(11*4-1 downto 0);

    signal loop_tvalid          : std_logic;
    signal loop_tdata           : num_hex_t;
    signal loop_cnt             : natural range 0 to 10;

    signal res_tvalid           : std_logic;
    signal res_tready           : std_logic;
    signal res_tdata            : num_hex_t;
    signal res_tuser_zf         : std_logic;
    signal res_tuser_msn        : std_logic_vector(3 downto 0);

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

    req_tvalid        <= shift_s_tvalid;
    shift_s_tready    <= req_tready;
    req_tdata         <= shift_s_tdata_val;

    shift_m_tvalid    <= res_tvalid;
    res_tready        <= shift_m_tready;
    shift_m_tdata     <= num_hex_to_slv(res_tdata);
    shift_m_tuser_cb  <= '0';
    shift_m_tuser_zf  <= res_tuser_zf;
    shift_m_tuser_msn <= res_tuser_msn;

    shift_l           <= req_tdata(11*4-2 downto 0) & '0';
    shift_r           <= '0' & req_tdata(11*4-1 downto 1);

    process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                req_tready <= '1';
                loop_tvalid <= '0';
            else

                if (req_tvalid = '1' and req_tready = '1') then
                    req_tready <= '0';
                elsif (res_tvalid = '1' and res_tready = '1') then
                    req_tready <= '1';
                end if;

                if (req_tvalid = '1' and req_tready = '1') then
                    loop_tvalid <= '1';
                elsif loop_tvalid = '1' and loop_cnt = 10 then
                    loop_tvalid <= '0';
                end if;

            end if;

            if (req_tvalid = '1' and req_tready = '1') then
                if (shift_s_tdata_op = '0') then
                    loop_tdata <= slv_to_num_hex(shift_l);
                else
                    loop_tdata <= slv_to_num_hex(shift_r);
                end if;
            end if;

        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                loop_cnt <= 0;
                res_tvalid <= '0';
            else

                if (loop_tvalid = '1') then
                    if (loop_cnt = 10) then
                        loop_cnt <= 0;
                    else
                        loop_cnt <= loop_cnt + 1;
                    end if;
                end if;

                if (loop_tvalid = '1' and loop_cnt = 10) then
                    res_tvalid <= '1';
                elsif (res_tready = '1') then
                    res_tvalid <= '0';
                end if;

            end if;

            if (loop_tvalid = '1') then
                res_tdata <= loop_tdata;
            end if;

            if (req_tvalid = '1' and req_tready = '1') then
                res_tuser_zf <= '1';
            elsif (loop_tvalid = '1' and res_tuser_zf = '1') then
                if (loop_tdata(loop_cnt) /= x"0") then
                    res_tuser_zf <= '0';
                end if;
            end if;

            if (req_tvalid = '1' and req_tready = '1') then
                res_tuser_msn <= x"0";
            elsif (loop_tvalid = '1') then
                if (loop_tdata(loop_cnt) /= x"0") then
                    res_tuser_msn <= std_logic_vector(to_unsigned(loop_cnt, 4));
                end if;
            end if;

        end if;
    end process;


end architecture;