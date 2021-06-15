library ieee;
library unisim;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use unisim.vcomponents.all;

entity spi_master_tb is
end entity spi_master_tb;

architecture rtl of spi_master_tb is

    -- Clock period definitions
    constant CLK_PERIOD : time := 10 ns;

    component spi_master is
        port (
            -- Control/Data Signals,
            clk         : in std_logic;        -- FPGA Clock
            resetn      : in std_logic;        -- FPGA Reset

            -- TX (MOSI) Signals
            tx_s_tvalid : in std_logic;          -- Data Valid Pulse with tx_s_tdata
            tx_s_tdata  : in std_logic_vector(7 downto 0);   -- Byte to transmit on MOSI
            tx_s_tready : out std_logic;         -- Transmit Ready for next byte

            -- RX (MISO) Signals
            rx_m_tvalid : out std_logic;    -- Data Valid pulse (1 clock cycle)
            rx_m_tdata  : out std_logic_vector(11 downto 0);   -- Byte received on MISO

            -- SPI Interface
            SCK         : out std_logic;
            SDI         : in std_logic;
            SDO         : out std_logic
        );
    end component;

    signal CLK          : std_logic := '0';
    signal RESETN       : std_logic := '0';

    signal tx_s_tvalid  : std_logic;          -- Data Valid Pulse with tx_s_tdata
    signal tx_s_tdata   : std_logic_vector(7 downto 0);   -- Byte to transmit on MOSI
    signal tx_s_tready  : std_logic;         -- Transmit Ready for next byte

    signal rx_m_tvalid  : std_logic;    -- Data Valid pulse (1 clock cycle)
    signal rx_m_tdata   : std_logic_vector(11 downto 0);   -- Byte received on MISO

    signal SCK          : std_logic;
    signal SDI          : std_logic;
    signal SDO          : std_logic;

    signal dat          : std_logic_vector(11 downto 0);

begin

    uut: spi_master port map (
        clk           => CLK,
        resetn        => RESETN,

        -- TX (MOSI) Signals
        tx_s_tvalid   => tx_s_tvalid,
        tx_s_tready   => tx_s_tready,
        tx_s_tdata    => tx_s_tdata,

        -- RX (MISO) Signals
        rx_m_tvalid   => rx_m_tvalid,
        rx_m_tdata    => rx_m_tdata,

        -- SPI Interface
        SCK           => SCK,
        SDI           => SDI,
        SDO           => SDO
    );

    -- Clock process
    clk_process : process begin
    	CLK <= '0';
    	wait for CLK_PERIOD/2;
    	CLK <= '1';
    	wait for CLK_PERIOD/2;
    end process;

    -- Reset process
    reset_process : process begin
        RESETN <= '0';
        wait for 200 ns;
        RESETN <= '1';
        wait;
    end process;

    --Stimuli
    input_data_proc: process begin

        tx_s_tvalid <= '0';
        tx_s_tdata <= x"AF";

        wait until RESETN = '1';
        wait for 1 us;
        wait for 390 ns;
        wait until rising_edge(clk);

        for col in 0 to 15 loop
            tx_s_tvalid <= '1';
            tx_s_tdata <= std_logic_vector(to_unsigned(col, 4)) & std_logic_vector(to_unsigned(col, 4));
            wait until rising_edge(clk) and tx_s_tvalid = '1' and tx_s_tready = '1';
        end loop;

        tx_s_tvalid <= '0';
        wait;

    end process;

    generate_adc_input : process

        variable seed1  : integer := 1;
        variable seed2  : integer := 999;
        variable cnt    : natural range 0 to 23 := 0;

        impure function rand_slv(len : integer) return std_logic_vector is
            variable r   : real;
            variable slv : std_logic_vector(len - 1 downto 0);
        begin
            for i in slv'range loop
                uniform(seed1, seed2, r);
                if r > 0.5 then
                    slv(i) := '1';
                else
                    slv(i) := '0';
                end if;
            end loop;
            return slv;
        end function;

    begin
        if (cnt = 0) then
            dat <= rand_slv(12);
        end if;
        if (cnt > 8 and cnt < 21) then
            SDI <= dat(11);
            dat <= dat(10 downto 0) & '0';
        else
            SDI <= '0';
        end if;
        wait until falling_edge(SCK);
        if (cnt = 23 ) then
            cnt := 0;
        else
            cnt := cnt + 1;
        end if;
    end process;


end architecture;
