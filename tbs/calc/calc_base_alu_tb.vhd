library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity calc_base_alu_tb is
end entity calc_base_alu_tb;

architecture rtl of calc_base_alu_tb is
    constant CLK_PERIOD     : time := 10 ns;
    constant MAX_WIDTH      : natural := 12;

    signal clk              : std_logic;
    signal resetn           : std_logic;

    component calc_base_alu is
        port (
            clk             : in std_logic;
            resetn          : in std_logic;

            alu_s_tvalid    : in std_logic;
            alu_s_tready    : out std_logic;
            alu_s_tdata_a   : in std_logic_vector(11*4-1 downto 0);
            alu_s_tdata_b   : in std_logic_vector(11*4-1 downto 0);
            alu_s_tdata_op  : in std_logic_vector(2 downto 0);

            alu_m_tvalid    : out std_logic;
            alu_m_tready    : in std_logic;
            alu_m_tdata     : out std_logic_vector(11*4-1 downto 0)
        );
    end component;

    signal alu_s_tvalid     : std_logic;
    signal alu_s_tready     : std_logic;
    signal alu_s_tdata_a    : std_logic_vector(11*4-1 downto 0);
    signal alu_s_tdata_b    : std_logic_vector(11*4-1 downto 0);
    signal alu_s_tdata_op   : std_logic_vector(2 downto 0);

    signal alu_m_tvalid     : std_logic;
    signal alu_m_tready     : std_logic;
    signal alu_m_tdata      : std_logic_vector(11*4-1 downto 0);

begin

    uut: calc_base_alu port map (
        clk             => clk,
        resetn          => resetn,

        alu_s_tvalid    => alu_s_tvalid,
        alu_s_tready    => alu_s_tready,
        alu_s_tdata_a   => alu_s_tdata_a,
        alu_s_tdata_b   => alu_s_tdata_b,
        alu_s_tdata_op  => alu_s_tdata_op,

        alu_m_tvalid    => alu_m_tvalid,
        alu_m_tready    => alu_m_tready,
        alu_m_tdata     => alu_m_tdata
    );

    -- continuous clock
    process begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    resetn <= '0', '1' after 10*CLK_PERIOD;

    process begin
        wait until resetn = '1';
        alu_s_tvalid <= '0';
        wait for CLK_PERIOD;
        wait until rising_edge(clk);

        alu_s_tvalid <= '1';
        --alu_s_tdata_a <= x"12345123451";
        alu_s_tdata_a <= x"00000000001";
        --alu_s_tdata_a <= x"FFFFFFFFFFF";
        alu_s_tdata_b <= x"FFFFFFFFFFF";
        --alu_s_tdata_b <= std_logic_vector(to_unsigned(1, 4*11));
        alu_s_tdata_op <= "000";
        wait until rising_edge(clk) and alu_s_tready = '1';


        -- for i in 0 to 100 loop
        --     alu_s_tvalid <= '1';
        --     alu_s_tdata(2*MAX_WIDTH-1 downto MAX_WIDTH) <= std_logic_vector(to_unsigned(1000, MAX_WIDTH));
        --     alu_s_tdata(MAX_WIDTH-1 downto 0) <= std_logic_vector(to_unsigned(i, MAX_WIDTH));
        --     alu_s_tuser(2*MAX_WIDTH-1 downto MAX_WIDTH) <= std_logic_vector(to_unsigned(1000, MAX_WIDTH));
        --     alu_s_tuser(MAX_WIDTH-1 downto 0) <= std_logic_vector(to_unsigned(i, MAX_WIDTH));
        --     wait until rising_edge(clk) and alu_s_tready = '1';
        -- end loop;
        alu_s_tvalid <= '0';

    end process;

    process begin
        alu_m_tready <= '0';

        wait until resetn = '1';
        wait for CLK_PERIOD;
        wait until rising_edge(clk);

        loop
            alu_m_tready <= '1';
            wait until rising_edge(clk) and alu_m_tvalid = '1' and alu_m_tready = '1';


            alu_m_tready <= '0';
            wait until rising_edge(clk);

            alu_m_tready <= '1';
        end loop;
    end process;

end architecture;
