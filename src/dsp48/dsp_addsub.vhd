library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;
use ieee.std_logic_unsigned.all;


entity dsp_addsub is
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        addsub_s_tvalid     : in std_logic;
        addsub_s_tready     : out std_logic;
        addsub_s_tdata_a    : in std_logic_vector(47 downto 0);
        addsub_s_tdata_b    : in std_logic_vector(47 downto 0);
        addsub_s_tdata_op   : in std_logic;

        addsub_m_tvalid     : out std_logic;
        addsub_m_tready     : in std_logic;
        addsub_m_tdata      : out std_logic_vector(47 downto 0)
    );
end entity dsp_addsub;

architecture rtl of dsp_addsub is
    signal p                : std_logic_vector(47 downto 0);
    signal a                : std_logic_vector(17 downto 0);
    signal b                : std_logic_vector(17 downto 0);
    signal d0, d1           : std_logic_vector(17 downto 0);
    signal c0, c1, c2       : std_logic_vector(47 downto 0);
    signal opmode0, opmode1 : std_logic_vector(7 downto 0);
    signal opmode2          : std_logic_vector(7 downto 0);
    signal cout             : std_logic;

    signal req_tvalid       : std_logic;
    signal req_tready       : std_logic;
    signal req_tdata_a      : std_logic_vector(47 downto 0);
    signal req_tdata_b      : std_logic_vector(47 downto 0);
    signal req_tdata_op     : std_logic;

    signal dsp_res_tvalid   : std_logic;
    signal dsp_res_tready   : std_logic;
    signal dsp_res_tdata    : std_logic_vector(47 downto 0);

    signal dsp_tvalid       : std_logic_vector(3 downto 0);
    signal dsp_tready       : std_logic;

    signal cea              : std_logic;
    signal ceb              : std_logic;
    signal ced              : std_logic;
    signal cec              : std_logic;
    signal cep              : std_logic;
    signal ceopmode         : std_logic;
    signal rst              : std_logic;
begin
    rst <= not resetn;

    req_tvalid <= addsub_s_tvalid;
    addsub_s_tready <= req_tready;
    req_tdata_a <= addsub_s_tdata_a;
    req_tdata_b <= addsub_s_tdata_b;
    req_tdata_op <= addsub_s_tdata_op;

    addsub_m_tvalid <= dsp_res_tvalid;
    dsp_res_tready <= addsub_m_tready;
    addsub_m_tdata <= dsp_res_tdata;

    req_tready <= '1' when ((dsp_tvalid(0) = '0' or (dsp_tvalid(0) = '1' and dsp_tready = '1')) and
        (dsp_tvalid(3) = '0' or (dsp_tvalid(3) = '1' and dsp_tready = '1'))) else '0';

    dsp_tready <= '1' when (dsp_res_tvalid = '0' or (dsp_res_tvalid = '1' and dsp_res_tready = '1')) else '0';

    cea <= '1' when (dsp_tvalid(0) = '1' or dsp_tvalid(1) = '1') and dsp_tready = '1' else '0';
    ceb <= '1' when (dsp_tvalid(0) = '1' or dsp_tvalid(1) = '1') and dsp_tready = '1' else '0';
    cec <= '1' when dsp_tvalid(2) = '1' and dsp_tready = '1' else '0';
    ced <= '1' when dsp_tvalid(1) = '1' and dsp_tready = '1' else '0';
    cep <= '1' when dsp_tvalid(2) = '1' and dsp_tready = '1' else '0';
    ceopmode <= '1' when dsp_tvalid(2) = '1' and dsp_tready = '1' else '0';

    process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                dsp_tvalid <= (others => '0');
                dsp_res_tvalid <= '0';
                a <= (others => '0');
                b <= (others => '0');
                c0 <= (others => '0');
                c1 <= (others => '0');
                c2 <= (others => '0');
                d0 <= (others => '0');
                d1 <= (others => '0');
            else
                if (req_tvalid = '1' and req_tready = '1') then
                    dsp_tvalid(0) <= '1';
                elsif dsp_tready = '1' then
                    dsp_tvalid(0) <= '0';
                end if;

                if (dsp_tready = '1') then
                    dsp_tvalid(3 downto 1) <= dsp_tvalid(2 downto 0);
                end if;

                if (dsp_tvalid(3) = '1' and dsp_tready = '1') then
                    dsp_res_tvalid <= '1';
                elsif dsp_tready = '1' then
                    dsp_res_tvalid <= '0';
                end if;

                if (req_tvalid = '1' and req_tready = '1') then
                    b <= req_tdata_b(17 downto 0);
                    a <= req_tdata_b(35 downto 18);
                    d0(11 downto 0) <= req_tdata_b(47 downto 36);
                    d0(17 downto 12) <= (others => '0');
                    c0 <= req_tdata_a;
                end if;

                if (req_tvalid = '1' and req_tready = '1') then
                    if (req_tdata_op = '1') then
                        opmode0 <= "00001111";
                    else
                        opmode0 <= "10001111";
                    end if;
                else

                end if;

                if (dsp_tvalid(0) = '1' and dsp_tready = '1') then
                    d1 <= d0;
                    c1 <= c0;
                    opmode1 <= opmode0;
                end if;

                if (dsp_tvalid(1) = '1' and dsp_tready = '1') then
                    c2 <= c1;
                    opmode2 <= opmode1;
                end if;

            end if;

            if (dsp_tready = '1') then
                dsp_res_tdata <= p;
            end if;

        end if;
    end process;


    DSP48A1_inst : DSP48A1
        generic map (
            A0REG           => 1,               -- First stage A input pipeline register (0/1)
            A1REG           => 1,               -- Second stage A input pipeline register (0/1)
            B0REG           => 1,               -- First stage B input pipeline register (0/1)
            B1REG           => 1,               -- Second stage B input pipeline register (0/1)
            CARRYINREG      => 1,               -- CARRYIN input pipeline register (0/1)
            CARRYINSEL      => "OPMODE5",       -- Specify carry-in source, "CARRYIN" or "OPMODE5"
            CARRYOUTREG     => 1,               -- CARRYOUT output pipeline register (0/1)
            CREG            => 0,               -- C input pipeline register (0/1)
            DREG            => 1,               -- D pre-adder input pipeline register (0/1)
            MREG            => 0,               -- M pipeline register (0/1)
            OPMODEREG       => 1,               -- Enable=1/disable=0 OPMODE input pipeline registers
            PREG            => 1,               -- P output pipeline register (0/1)
            RSTTYPE         => "SYNC"           -- Specify reset type, "SYNC" or "ASYNC"
        ) port map (
            -- Cascade Ports: 18-bit (each) output: Ports to cascade from one DSP48 to another
            BCOUT           => open,            -- 18-bit output: B port cascade output
            PCOUT           => open,            -- 48-bit output: P cascade output (if used, connect to PCIN of another DSP48A1)

            -- Data Ports: 1-bit (each) output: Data input and output ports
            CARRYOUT        => cout,            -- 1-bit output: carry output (if used, connect to CARRYIN pin of another DSP48A1)
            CARRYOUTF       => open,            -- 1-bit output: fabric carry output
            M               => open,            -- 36-bit output: fabric multiplier data output
            P               => P,               -- 48-bit output: data output

            -- Cascade Ports: 48-bit (each) input: Ports to cascade from one DSP48 to another
            PCIN            => open,            -- 48-bit input: P cascade input (if used, connect to PCOUT of another DSP48A1)

            -- Control Input Ports: 1-bit (each) input: Clocking and operation mode
            CLK             => CLK,             -- 1-bit input: clock input
            OPMODE          => opmode2,      -- C ± (D:A:B + CIN) 8-bit input: operation mode input

            -- Data Ports: 18-bit (each) input: Data input and output ports
            A               => A,               -- 18-bit input: A data input
            B               => B,               -- 18-bit input: B data input (connected to fabric or BCOUT of adjacent DSP48A1)
            C               => c2,               -- 48-bit input: C data input
            CARRYIN         => '0',             -- 1-bit input: carry input signal (if used, connect to CARRYOUT pin of another DSP48A1)
            D               => d1,              -- 18-bit input: B pre-adder data input

            -- Reset/Clock Enable Input Ports: 1-bit (each) input: Reset and enable input ports
            CEA             => cea,             -- 1-bit input: active high clock enable input for A registers
            CEB             => ceb,             -- 1-bit input: active high clock enable input for B registers
            CEC             => '0',             -- 1-bit input: active high clock enable input for C registers
            CECARRYIN       => '1',             -- 1-bit input: active high clock enable input for CARRYIN registers
            CED             => ced,             -- 1-bit input: active high clock enable input for D registers
            CEM             => '0',             -- 1-bit input: active high clock enable input for multiplier registers
            CEOPMODE        => ceopmode,        -- 1-bit input: active high clock enable input for OPMODE registers
            CEP             => cep,             -- 1-bit input: active high clock enable input for P registers
            RSTA            => rst,             -- 1-bit input: reset input for A pipeline registers
            RSTB            => rst,             -- 1-bit input: reset input for B pipeline registers
            RSTC            => rst,             -- 1-bit input: reset input for C pipeline registers
            RSTCARRYIN      => rst,             -- 1-bit input: reset input for CARRYIN pipeline registers
            RSTD            => rst,             -- 1-bit input: reset input for D pipeline registers
            RSTM            => rst,             -- 1-bit input: reset input for M pipeline registers
            RSTOPMODE       => rst,             -- 1-bit input: reset input for OPMODE pipeline registers
            RSTP            => rst              -- 1-bit input: reset input for P pipeline registers
        );

end architecture;
