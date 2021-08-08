library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity dsp_div_u is
    generic (
        USER_WIDTH              : natural := 16
    );
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        div_s_tvalid            : in std_logic;
        div_s_tready            : out std_logic;
        div_s_tdata             : in std_logic_vector(95 downto 0);
        div_s_tuser             : in std_logic_vector(USER_WIDTH-1 downto 0);

        div_m_tvalid            : out std_logic;
        div_m_tready            : in std_logic;
        div_m_tdata             : out std_logic_vector(95 downto 0);
        div_m_tuser             : out std_logic_vector(USER_WIDTH-1 downto 0)
    );
end entity dsp_div_u;

architecture rtl of dsp_div_u is
    constant MAX_WIDTH          : natural := 48;
    constant STEPS              : natural := MAX_WIDTH;

    signal input_tvalid         : std_logic;
    signal input_tready         : std_logic;
    signal input_tdata          : std_logic_vector(2*MAX_WIDTH-1 downto 0);
    signal input_tuser          : std_logic_vector(USER_WIDTH-1 downto 0);

    signal output_tvalid        : std_logic;
    signal output_tready        : std_logic;
    signal output_tdata         : std_logic_vector(2*MAX_WIDTH-1 downto 0);
    signal output_tuser         : std_logic_vector(USER_WIDTH-1 downto 0);

    signal n                    : unsigned(MAX_WIDTH-1 downto 0);
    signal d                    : unsigned(MAX_WIDTH-1 downto 0);
    signal q                    : unsigned(MAX_WIDTH-1 downto 0);
    signal r                    : unsigned(MAX_WIDTH-1 downto 0);
    signal r2                   : unsigned(MAX_WIDTH-1 downto 0);

    signal i                    : natural range 0 to STEPS;
    signal idx                  : natural range 0 to STEPS-1;


    signal addsub_s_tvalid      : std_logic;
    signal addsub_s_tready      : std_logic;
    signal addsub_s_tdata_a     : std_logic_vector(47 downto 0);
    signal addsub_s_tdata_b     : std_logic_vector(47 downto 0);
    signal addsub_s_tdata_op    : std_logic;

    signal addsub_m_tvalid      : std_logic;
    signal addsub_m_tready      : std_logic;
    signal addsub_m_tdata       : std_logic_vector(47 downto 0);

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

begin

    dsp_addsub_inst: dsp_addsub port map (
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


    input_tvalid <= div_s_tvalid;
    div_s_tready <= input_tready;
    input_tdata <= div_s_tdata;
    input_tuser <= div_s_tuser;

    div_m_tvalid <= output_tvalid;
    output_tready <= div_m_tready;
    div_m_tdata <= output_tdata;
    div_m_tuser <= output_tuser;

    output_tdata(2*MAX_WIDTH-1 downto MAX_WIDTH) <= std_logic_vector(q);
    output_tdata(MAX_WIDTH-1 downto 0) <= std_logic_vector(r);

    r2 <= r(MAX_WIDTH - 2 downto 0) & n(idx); -- Left-shift R by 1 bit and R(0) := N(i)

    addsub_s_tdata_op <= '0';
    addsub_m_tready <= '1';

    addsub_s_tdata_a <= std_logic_vector(r2);
    addsub_s_tdata_b <= std_logic_vector(d);

    process (clk) begin
        if rising_edge(clk) then
            if resetn = '0' then
                input_tready <= '1';
                i <= 0;
                output_tvalid <= '0';
                addsub_s_tvalid <= '0';
            else
                if input_tvalid = '1' and input_tready = '1' then
                    input_tready <= '0';
                elsif (output_tvalid = '1' and output_tready = '1') then
                    input_tready <= '1';
                end if;

                if input_tvalid = '1' and input_tready = '1' then
                    i <= STEPS;
                elsif (addsub_s_tvalid = '1' and addsub_s_tready = '1' and i /= 0) then
                    i <= i - 1;
                end if;

                if (input_tvalid = '1' and input_tready = '1') then
                    addsub_s_tvalid <= '1';
                elsif (addsub_m_tvalid = '1' and addsub_m_tready = '1' and i /= 0) then
                    addsub_s_tvalid <= '1';
                elsif (addsub_s_tready = '1') then
                    addsub_s_tvalid <= '0';
                end if;

            end if;

            if input_tvalid = '1' and input_tready = '1' then
                idx <= STEPS-1;
            elsif (addsub_m_tvalid = '1' and addsub_m_tready = '1') then
                if (idx > 0) then
                    idx <= idx - 1;
                end if;
            end if;

            if input_tvalid = '1' and input_tready = '1' then
                n <= unsigned(input_tdata(2*MAX_WIDTH-1 downto MAX_WIDTH));
                d <= unsigned(input_tdata(MAX_WIDTH-1 downto 0));
                r <= (others => '0') ;
                q <= (others => '0');
            elsif (addsub_m_tvalid = '1' and addsub_m_tready = '1') then
                if (r2 >= d) then
                    r <= unsigned(addsub_m_tdata);
                    q(idx) <= '1';
                else
                    r <= r2;
                    q(idx) <= '0';
                end if;

            end if;

            if (addsub_m_tvalid = '1' and addsub_m_tready = '1' and i = 0) then
                output_tvalid <= '1';
            elsif (output_tready = '1') then
                output_tvalid <= '0';
            end if;

            if input_tvalid = '1' and input_tready = '1' then
                output_tuser <= input_tuser;
            end if;

        end if;
    end process;

end architecture;
