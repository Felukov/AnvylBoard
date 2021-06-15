library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity spi_master is
    generic (
        CLOCKFREQ                   : natural := 100; --in MHz
        MHZ_MAX                     : natural := 2 --2 MHz max
    );
    port (
        -- Control/Data Signals,
        clk                         : in std_logic;        -- FPGA Clock
        resetn                      : in std_logic;        -- FPGA Reset

        -- TX (MOSI) Signals
        tx_s_tvalid                 : in std_logic;          -- Data Valid Pulse with tx_s_tdata
        tx_s_tready                 : out std_logic;         -- Transmit Ready for next byte
        tx_s_tdata                  : in std_logic_vector(7 downto 0);   -- Byte to transmit on MOSI

        -- RX (MISO) Signals
        rx_m_tvalid                 : out std_logic;    -- Data Valid pulse (1 clock cycle)
        rx_m_tdata                  : out std_logic_vector(11 downto 0);   -- Byte received on MISO

        -- SPI Interface
        CSn                         : out std_logic;
        SCK                         : out std_logic;
        SDI                         : in std_logic;
        SDO                         : out std_logic
    );
end entity spi_master;

architecture rtl of spi_master is

    constant DCLK_CYCLES            : positive := positive(ceil(real(CLOCKFREQ/MHZ_MAX))) / 2; -- Half duty cycle

    component axis_reg is
        generic (
            DATA_WIDTH              : natural := 32
        );
        port (
            clk                     : in std_logic;
            resetn                  : in std_logic;
            in_s_tvalid             : in std_logic;
            in_s_tready             : out std_logic;
            in_s_tdata              : in std_logic_vector (DATA_WIDTH-1 downto 0);
            out_m_tvalid            : out std_logic;
            out_m_tready            : in std_logic;
            out_m_tdata             : out std_logic_vector (DATA_WIDTH-1 downto 0)
        );
    end component;

    signal clk_cnt                  : natural range 0 to DCLK_CYCLES-1; --clock divider for DCLK of the ADS7873

    signal dclk                     : std_logic;
    signal dclk_rising              : std_logic;
    signal dclk_falling             : std_logic;

    signal cycle_dclk_cnt           : natural range 0 to 23;

    signal tx_tvalid                : std_logic; -- Data Valid Pulse with tx_s_tdata
    signal tx_tdata                 : std_logic_vector(7 downto 0); -- Byte to transmit on MOSI
    signal tx_tready                : std_logic; -- Transmit Ready for next byte

    signal spi_tvalid               : std_logic;
    signal spi_tready               : std_logic;
    signal spi_tdata                : std_logic_vector(7 downto 0);

    signal rx_tvalid                : std_logic;
    signal rx_tdata                 : std_logic_vector(11 downto 0);

begin

    input_reg : axis_reg generic map (
        DATA_WIDTH          => 8
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        in_s_tvalid         => tx_s_tvalid,
        in_s_tready         => tx_s_tready,
        in_s_tdata          => tx_s_tdata,

        out_m_tvalid        => tx_tvalid,
        out_m_tready        => tx_tready,
        out_m_tdata         => tx_tdata
    );

    tx_tready <= '1' when dclk_rising = '1' and (spi_tvalid = '0' or (spi_tvalid = '1' and spi_tready = '1')) else '0';
    spi_tready <= '1' when dclk_rising = '1' and cycle_dclk_cnt = 23 else '0';

    dclk_rising <= '1' when dclk = '0' and clk_cnt = 0 else '0';
    dclk_falling <= '1' when dclk = '1' and clk_cnt = 0 else '0';

    rx_m_tvalid <= rx_tvalid;
    rx_m_tdata <= rx_tdata;


    clock_div_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                dclk <= '0';
                clk_cnt <= 0;
            else
                if (clk_cnt = 0) then
                    clk_cnt <= DCLK_CYCLES - 1;
                else
                    clk_cnt <= clk_cnt - 1;
                end if;

                if (clk_cnt = 0) then
                    dclk <= not dclk;
                end if;
            end if;

        end if;
    end process;

    process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                spi_tvalid <= '0';
                cycle_dclk_cnt <= 0;
            else
                if tx_tvalid = '1' and tx_tready = '1' then
                    spi_tvalid <= '1';
                elsif spi_tready = '1' then
                    spi_tvalid <= '0';
                end if;

                if spi_tvalid = '1' and dclk_rising = '1' then
                    if (cycle_dclk_cnt = 23) then
                        cycle_dclk_cnt <= 0;
                    else
                        cycle_dclk_cnt <= cycle_dclk_cnt + 1;
                    end if;
                end if;
            end if;

            if tx_tvalid = '1' and tx_tready = '1' then
                spi_tdata <= tx_tdata;
            elsif spi_tvalid = '1' and dclk_rising = '1' then
                spi_tdata <= spi_tdata(spi_tdata'high-1 downto 0) & '0';
            end if;

        end if;
    end process;

    forming_output_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                SDO <= '0';
                SCK <= '0';
                CSn <= '1';
            else
                if (spi_tvalid = '1') then
                    SCK <= not dclk;
                else
                    SCK <= '0';
                end if;

                if (spi_tvalid = '1') then
                    CSn <= '0';
                else
                    CSn <= '1';
                end if;

                SDO <= spi_tdata(spi_tdata'high);
            end if;

        end if;
    end process;

    latching_input : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                rx_tvalid <= '0';
            else

                if dclk_falling = '1' and cycle_dclk_cnt = 20 then
                    rx_tvalid <= '1';
                else
                    rx_tvalid <= '0';
                end if;
            end if;

            if dclk_falling = '1' and cycle_dclk_cnt > 8 and cycle_dclk_cnt < 21 then
                rx_tdata <= rx_tdata(10 downto 0) & SDI;
            end if;

        end if;
    end process;

end architecture rtl;
