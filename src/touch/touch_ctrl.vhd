library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

entity touch_ctrl is
    port (
        clk                     : in std_logic;
        resetn                  : in std_logic;

        touch_m_tvalid          : out std_logic;
        touch_m_tdata           : out std_logic_vector(11 downto 0);
        touch_m_tuser           : out std_logic_vector(1 downto 0);

        -- SPI Interface
        CSn                     : out std_logic;
        SCK                     : out std_logic;
        SDI                     : in std_logic;
        SDO                     : out std_logic

    );
end entity touch_ctrl;

architecture rtl of touch_ctrl is
    -- 16 significant samples + 1 garbage sample + 2 min/max samples
    constant SAMPLES_CNT        : natural := 19;
    constant SAMPLE_X           : natural range 0 to 2 := 0;
    constant SAMPLE_Y           : natural range 0 to 2 := 1;
    constant SAMPLE_Z           : natural range 0 to 2 := 2;

	constant ADS_START          : std_logic := '1';
	constant ADS_AX             : std_logic_vector(2 downto 0) := "101";
	constant ADS_AY             : std_logic_vector(2 downto 0) := "001";
	constant ADS_AZ1            : std_logic_vector(2 downto 0) := "011";
	constant ADS_12BIT          : std_logic := '0';
	constant ADS_DIF            : std_logic := '0';
	constant ADS_NOPD           : std_logic_vector(1 downto 0) := "11";
	constant ADS_PD             : std_logic_vector(1 downto 0) := "00";

    component spi_master is
        port (
            -- Control/Data Signals,
            clk                 : in std_logic;
            resetn              : in std_logic;
            -- TX (MOSI) Signals
            tx_s_tvalid         : in std_logic;
            tx_s_tdata          : in std_logic_vector(7 downto 0);
            tx_s_tready         : out std_logic;
            -- RX (MISO) Signals
            rx_m_tvalid         : out std_logic;
            rx_m_tdata          : out std_logic_vector(11 downto 0);
            -- SPI Interface
            CSn                 : out std_logic;
            SCK                 : out std_logic;
            SDI                 : in std_logic;
            SDO                 : out std_logic
        );
    end component;

    signal start_cnt            : std_logic_vector(3 downto 0);

    signal tx_tvalid            : std_logic;
    signal tx_tready            : std_logic;
    signal tx_tdata             : std_logic_vector( 7 downto 0);
    signal tx_tdata_next        : std_logic_vector( 7 downto 0);
    signal tx_cnt               : natural range 0 to SAMPLES_CNT-1;
    signal tx_sample            : natural range 0 to 2;

    signal rx_tvalid            : std_logic;
    signal rx_tdata             : std_logic_vector(11 downto 0);
    signal rx_cnt               : natural range 0 to SAMPLES_CNT-1;

    signal rx_sum               : natural range 0 to 2**17-1;
    signal rx_max               : natural range 0 to 2**12-1;
    signal rx_min               : natural range 0 to 2**12-1;

    signal rx_raw_tvalid        : std_logic_vector (3 downto 0);
    signal rx_raw_tdata         : natural range 0 to 2**17-1;
    signal rx_raw_tuser         : natural range 0 to 2;
    signal rx_raw_max           : natural range 0 to 2**12-1;
    signal rx_raw_min           : natural range 0 to 2**12-1;

begin

    touch_m_tvalid <= rx_raw_tvalid(3);
    touch_m_tdata <= std_logic_vector(to_unsigned(rx_raw_tdata, 12));
    touch_m_tuser <= std_logic_vector(to_unsigned(rx_raw_tuser, 2));

    tx_tdata_next(7) <= ADS_START;
    tx_tdata_next(6 downto 4) <=
        ADS_AX when tx_sample = SAMPLE_X else
        ADS_AY when tx_sample = SAMPLE_Y else ADS_AZ1;
    tx_tdata_next(3) <= ADS_12BIT;
    tx_tdata_next(2) <= ADS_DIF;
    tx_tdata_next(1 downto 0) <= ADS_NOPD;

    spi_master_inst: spi_master port map (
        clk           => CLK,
        resetn        => RESETN,
        -- TX (MOSI) Signals
        tx_s_tvalid   => tx_tvalid,
        tx_s_tready   => tx_tready,
        tx_s_tdata    => tx_tdata,
        -- RX (MISO) Signals
        rx_m_tvalid   => rx_tvalid,
        rx_m_tdata    => rx_tdata,
        -- SPI Interface
        CSn           => CSn,
        SCK           => SCK,
        SDI           => SDI,
        SDO           => SDO
    );

    start_cnt_process: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                start_cnt <= "0001";
            else
                start_cnt <= start_cnt(2 downto 0) & '0';
            end if;

        end if;
    end process;

    send_tx_proc : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                tx_tvalid <= '0';
                tx_cnt <= 0;
                tx_sample <= SAMPLE_X;
            else

                if start_cnt(3) = '1' then
                    tx_tvalid <= '1';
                end if;

                if (tx_tvalid = '1' and tx_tready = '1') then
                    if (tx_cnt = SAMPLES_CNT-1) then
                        tx_cnt <= 0;
                    else
                        tx_cnt <= tx_cnt + 1;
                    end if;
                end if;

                if (tx_tvalid = '1' and tx_tready = '1' and tx_cnt = SAMPLES_CNT-2) then
                    if (tx_sample = SAMPLE_X) then
                        tx_sample <= SAMPLE_Y;
                    elsif (tx_sample = SAMPLE_Y) then
                        tx_sample <= SAMPLE_Z;
                    elsif (tx_sample = SAMPLE_Z) then
                        tx_sample <= SAMPLE_X;
                    end if;
                end if;

            end if;

            if start_cnt(3) = '1' then
                tx_tdata <= tx_tdata_next;
            elsif (tx_tvalid = '1' and tx_tready = '1' and tx_cnt = SAMPLES_CNT-1) then
                tx_tdata <= tx_tdata_next;
            end if;

        end if;
    end process;

    get_rx_proc : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                rx_cnt <= 0;
            else

                if (rx_tvalid = '1') then
                    if (rx_cnt = SAMPLES_CNT-1)then
                        rx_cnt <= 0;
                    else
                        rx_cnt <= rx_cnt + 1;
                    end if;
                end if;

            end if;

            if (rx_tvalid = '1' and rx_cnt = 0) then
                -- skip garbage due to settling of signal and load initial values
                rx_sum <= 0;
                rx_min <= 2**12-1;
                rx_max <= 0;

            elsif (rx_tvalid = '1' and rx_cnt > 0) then
                --load data
                rx_sum <= rx_sum + to_integer(unsigned(rx_tdata));

                if (to_integer(unsigned(rx_tdata)) < rx_min) then
                    rx_min <= to_integer(unsigned(rx_tdata));
                end if;

                if (to_integer(unsigned(rx_tdata)) > rx_max) then
                    rx_max <= to_integer(unsigned(rx_tdata));
                end if;

            end if;

        end if;
    end process;

    averaging_proc: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                rx_raw_tvalid <= "0000";
                rx_raw_tuser <= SAMPLE_X;
            else
                if (rx_tvalid = '1' and rx_cnt = SAMPLES_CNT-1) then
                    rx_raw_tvalid <= rx_raw_tvalid(2 downto 0) & '1';
                else
                    rx_raw_tvalid <= rx_raw_tvalid(2 downto 0) & '0';
                end if;
            end if;

            if (rx_tvalid = '1' and rx_cnt = SAMPLES_CNT-1) then
                rx_raw_max <= rx_max;
                rx_raw_min <= rx_min;
            end if;

            if (rx_raw_tvalid(0) = '1') then
                rx_raw_tdata <= rx_sum - rx_raw_min;
            elsif (rx_raw_tvalid(1) = '1') then
                rx_raw_tdata <= rx_raw_tdata - rx_raw_max;
            elsif (rx_raw_tvalid(2) = '1') then
                rx_raw_tdata <= rx_raw_tdata / 16;
            end if;

            if (rx_raw_tvalid(3) = '1') then
                if (rx_raw_tuser = SAMPLE_X) then
                    rx_raw_tuser <= SAMPLE_Y;
                elsif (rx_raw_tuser = SAMPLE_Y) then
                    rx_raw_tuser <= SAMPLE_Z;
                elsif (rx_raw_tuser = SAMPLE_Z) then
                    rx_raw_tuser <= SAMPLE_X;
                end if;
            end if;

        end if;

    end process;

end rtl;