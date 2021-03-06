----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    08:17:33 04/04/2021
-- Design Name:
-- Module Name:    tft - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

entity tft is
    generic (
        SIMULATION                          : string := "FALSE"
    );
    port (
        --clock and syncho
        clk_100                             : in std_logic;
        init_done                           : in std_logic;
        --control interface
        ctrl_en                             : in std_logic;
        --tft interface
        tft_clk                             : out std_logic;
        tft_de                              : out std_logic;
        tft_vidden                          : out std_logic;
        tft_disp                            : out std_logic;
        tft_bklt                            : out std_logic;
        tft_r                               : out std_logic_vector(7 downto 0);
        tft_g                               : out std_logic_vector(7 downto 0);
        tft_b                               : out std_logic_vector(7 downto 0);
        --rd cmd channel to ddr
        rd_cmd_m_tvalid                     : out std_logic;
        rd_cmd_m_tready                     : in std_logic;
        rd_cmd_m_tlast                      : out std_logic;
        rd_cmd_m_taddr                      : out std_logic_vector(25 downto 0);
        -- rd data channel from ddr
        rd_data_s_tvalid                    : in std_logic;
        rd_data_s_tready                    : out std_logic;
        rd_data_s_tdata                     : in std_logic_vector(127 downto 0)
    );
end tft;

architecture Behavioral of tft is

    function get_delay(simulation : string) return integer is begin
        if SIMULATION = "TRUE" then
            return 10;
        else
            return 1000;
        end if;
    end function;

    function get_warm_up_cool_down_time(simulation : string) return integer is begin
        if SIMULATION = "TRUE" then
            return 2;
        else
            return 200;
        end if;
    end function;

    constant CLOCKFREQ                      : natural := 9; --9 MHZ
    constant TPOWERUP                       : natural := 1; --1 ms
    constant TPOWERDOWN                     : natural := 1; --1 ms
    constant TLEDWARMUP                     : natural := get_warm_up_cool_down_time(SIMULATION); --200 ms
    constant TLEDCOOLDOWN                   : natural := get_warm_up_cool_down_time(SIMULATION); --200 ms
    constant DELAY                          : natural := get_delay(SIMULATION); -- 1000
    constant TLEDWARMUP_CYCLES              : natural := natural(CLOCKFREQ*TLEDWARMUP*DELAY);
    constant TLEDCOOLDOWN_CYCLES            : natural := natural(CLOCKFREQ*TLEDCOOLDOWN*DELAY);
    constant TPOWERUP_CYCLES                : natural := natural(CLOCKFREQ*TPOWERUP*DELAY);
    constant TPOWERDOWN_CYCLES              : natural := natural(CLOCKFREQ*TPOWERDOWN*DELAY);

    function get_max_delay_cnt return integer is begin
        return CLOCKFREQ*get_delay("FALSE")*get_warm_up_cool_down_time("FALSE");
    end function;

    component pwm
        generic (
            C_CLK_FREQUENCY                 : natural;
            C_PWM_FREQUENCY                 : natural;
            C_PWM_RESOLUTION                : natural
        );
    	port (
    		clk                             : in std_logic;
    		rst                             : in std_logic;
            duty_factor                     : in std_logic_vector (C_PWM_RESOLUTION-1 downto 0);
    		pwm_o                           : out std_logic
        );
    end component;

    component tft_video_timing_gen
       port (
            clk                             : in std_logic;
            clk_en                          : in std_logic;
            rst                             : in std_logic;
            vde                             : out std_logic;
            hs                              : out std_logic;
            vs                              : out std_logic;
            hcnt                            : out natural;
            vcnt                            : out natural
    );
    end component;

    component tft_ddr2_reader is
        port (
            clk                             : in std_logic;
            resetn                          : in std_logic;
            -- control requests
            next_frame_s_tvalid             : in std_logic;
            next_frame_s_tready             : out std_logic;
            next_frame_s_tdata              : in std_logic_vector(8 downto 0);
            --rd cmd channel
            rd_cmd_m_tvalid                 : out std_logic;
            rd_cmd_m_tready                 : in std_logic;
            rd_cmd_m_tlast                  : out std_logic;
            rd_cmd_m_taddr                  : out std_logic_vector(25 downto 0);
            --rd data channel from ddr
            rd_data_s_tvalid                : in std_logic;
            rd_data_s_tready                : out std_logic;
            rd_data_s_tdata                 : in std_logic_vector(127 downto 0);
            --rd data channel to tft
            rd_data_m_tvalid                : out std_logic;
            rd_data_m_tready                : in std_logic;
            rd_data_m_tdata                 : out std_logic_vector(23 downto 0)

        );
    end component;

    type state_t is (ST_OFF, ST_POWER_UP, ST_LED_WARM_UP, ST_LED_COOL_DOWN, ST_POWER_DOWN, ST_ON);

    signal state_next, state                : state_t := ST_POWER_DOWN;
    signal tft_clk_counter                  : integer range 0 to 65535;
    signal tft_clk_counter_vec              : std_logic_vector(15 downto 0);
    signal tft_clk_ovf                      : std_logic;
    signal tft_clk_ovf_prev                 : std_logic;
    signal tft_clk_en                       : std_logic;

    signal local_rst                        : std_logic;

    signal delay_cnt                        : natural range 0 to get_max_delay_cnt := 0;
    signal delay_reload                     : std_logic;
    signal delay_event_power_up             : std_logic;
    signal delay_event_power_down           : std_logic;
    signal delay_event_led_warm_up          : std_logic;
    signal delay_event_led_cool_down        : std_logic;

    signal pwm_backlight                    : std_logic;
    signal vde                              : std_logic;

    signal x                                : natural;
    signal y                                : natural;

    signal rd_data_m_tvalid                 : std_logic;
    signal rd_data_m_tready                 : std_logic;
    signal rd_data_m_tdata                  : std_logic_vector(23 downto 0);

    --signal
    signal ddr_sync                         : std_logic;
    signal frame_started                    : std_logic;

    signal next_frame_tvalid                : std_logic;
    signal next_frame_tdata                 : std_logic_vector(8 downto 0);

begin

    -- 4-bit Shift Register For resetting on startup
    -- Asserts local_rst for 4 clock periods
    SRL16_inst : SRL16E generic map (
        INIT                => X"000F"
    ) port map (
        CLK                 => clk_100,     -- Clock input
        CE                  => init_done,   -- Clock enable
        D                   => '0',         -- SRL data input
        A0                  => '1',         -- Select[0] input
        A1                  => '1',         -- Select[1] input
        A2                  => '0',         -- Select[2] input
        A3                  => '0',         -- Select[3] input
        Q                   => local_rst    -- SRL data output
    );

    pwm_inst: pwm generic map (
        C_CLK_FREQUENCY     => 100, -- in MHZ
        C_PWM_FREQUENCY     => 25_000, -- in Hz
        C_PWM_RESOLUTION    => 3
    ) port map (
        clk                 => clk_100,
        rst                 => local_rst,
        pwm_o               => pwm_backlight,
        duty_factor         => "111"
    );

    tft_video_timing_gen_inst: tft_video_timing_gen port map(
        clk                 => clk_100,
        clk_en              => tft_clk_en,
        rst                 => local_rst,
        vde                 => vde,
        hs                  => open,
        vs                  => open,
        hcnt                => x,
        vcnt                => y
    );

    rd_data_m_tready <= '1' when vde = '1' and tft_clk_en = '1' else '0';
    tft_clk_counter_vec <= std_logic_vector(to_unsigned(tft_clk_counter, 16));

    tft_ddr2_reader_inst : tft_ddr2_reader port map (
        clk                 => clk_100,
        resetn              => init_done,
        next_frame_s_tvalid => next_frame_tvalid,
        next_frame_s_tready => open,
        next_frame_s_tdata  => next_frame_tdata,

        rd_cmd_m_tvalid     => rd_cmd_m_tvalid,
        rd_cmd_m_tready     => rd_cmd_m_tready,
        rd_cmd_m_tlast      => rd_cmd_m_tlast,
        rd_cmd_m_taddr      => rd_cmd_m_taddr,

        rd_data_s_tvalid    => rd_data_s_tvalid,
        rd_data_s_tready    => rd_data_s_tready,
        rd_data_s_tdata     => rd_data_s_tdata,

        rd_data_m_tvalid    => rd_data_m_tvalid,
        rd_data_m_tready    => rd_data_m_tready,
        rd_data_m_tdata     => rd_data_m_tdata

    );

    next_frame_process: process (clk_100) begin
        if rising_edge(clk_100) then
            if init_done = '0' then
                next_frame_tvalid <= '0';
                next_frame_tdata <= (others => '0');
            else
                if (tft_clk_en = '1' and x = 479 and y < 271) or (state = ST_POWER_UP and state_next = ST_LED_WARM_UP) then
                    next_frame_tvalid <= '1';
                elsif (next_frame_tvalid = '1') then
                    next_frame_tvalid <= '0';
                end if;

                if (tft_clk_en = '1' and x = 479) then
                    next_frame_tdata <= std_logic_vector(to_unsigned(y+1, 9));
                end if;
            end if;
        end if;
    end process;

    -- the process generates 9MHZ clock for TFT
    tft_clk_process: process(clk_100) begin
        -- counting
        if (rising_edge(clk_100)) then
            if (local_rst = '1') then
                tft_clk_counter <= 0;
                tft_clk_ovf <= '0';
                tft_clk_ovf_prev <= '0';
            else

                tft_clk_counter <= (tft_clk_counter + 5898) mod 65535;
                --get msb
                tft_clk_ovf <= tft_clk_counter_vec(tft_clk_counter_vec'left);
                --latch prev value
                tft_clk_ovf_prev <= tft_clk_ovf;
                --generate pulse
                if (tft_clk_ovf = '1' and tft_clk_ovf_prev = '0') then
                    tft_clk_en <= '1';
                else
                    tft_clk_en <= '0';
                end if;

            end if;
        end if;
    end process;

    -- the process generates delayed events
    delay_event_power_up        <= '1' when delay_cnt = TPOWERUP_CYCLES     else '0';
    delay_event_power_down      <= '1' when delay_cnt = TPOWERDOWN_CYCLES   else '0';
    delay_event_led_warm_up     <= '1' when delay_cnt = TLEDWARMUP_CYCLES   else '0';
    delay_event_led_cool_down   <= '1' when delay_cnt = TLEDCOOLDOWN_CYCLES else '0';

    delay_counter_process: process(clk_100) begin
        if (rising_edge(clk_100)) then
            if (local_rst = '1') then
                delay_cnt <= 0;
            elsif (tft_clk_en = '1') then
                if (delay_reload = '1') then
                    delay_cnt <= 0;
                else
                    delay_cnt <= delay_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    tft_fsm_next: process (state, tft_clk_en, delay_event_power_up, delay_event_led_warm_up,
        delay_event_led_cool_down, delay_event_power_down, ctrl_en) begin
        state_next <= state;
        delay_reload <= '0';

        case (state) is
            when ST_OFF =>
                if (tft_clk_en = '1' and ctrl_en = '1') then
                    state_next <= ST_POWER_UP;
                    delay_reload <= '1';
                end if;
            when ST_POWER_UP =>
                if (tft_clk_en = '1' and delay_event_power_up = '1') then
                    state_next <= ST_LED_WARM_UP;
                    delay_reload <= '1';
                end if;
            when ST_LED_WARM_UP =>
                if (tft_clk_en = '1' and delay_event_led_warm_up = '1') then
                    state_next <= ST_ON;
                    delay_reload <= '1';
                end if;
            when ST_ON =>
                if (tft_clk_en = '1' and ctrl_en = '0') then
                    state_next <= ST_LED_COOL_DOWN;
                    delay_reload <= '1';
                end if;
            when ST_LED_COOL_DOWN =>
                if (tft_clk_en = '1' and delay_event_led_cool_down = '1') then
                    state_next <= ST_POWER_DOWN;
                    delay_reload <= '1';
                end if;
            when ST_POWER_DOWN =>
                if (tft_clk_en = '1' and delay_event_power_down = '1') then
                    delay_reload <= '1';
                    state_next <= ST_OFF;
                end if;
        end case;
    end process;

    tft_fsm: process(clk_100) begin
        if (rising_edge(clk_100)) then
            if (local_rst = '1') then
                state <= ST_POWER_DOWN;
            else
                state <= state_next;
            end if;
        end if;
    end process;

    tft_out_signals: process(clk_100) begin
        if (rising_edge(clk_100)) then
            if (state = ST_OFF or state = ST_POWER_DOWN) then
                tft_vidden  <= '0';
            else
                tft_vidden  <= '1';
            end if;

            if (state = ST_OFF or state = ST_POWER_DOWN or state = ST_POWER_UP) then
                tft_clk     <= '0';
                tft_de      <= '0';
                tft_disp    <= '0';
                tft_r       <= (others => '0');
                tft_g       <= (others => '0');
                tft_b       <= (others => '0');
            else
                tft_clk     <= tft_clk_ovf;
                tft_de      <= vde;
                tft_disp    <= '1';
                tft_r       <= rd_data_m_tdata(7 downto 0);
                tft_g       <= rd_data_m_tdata(15 downto 8);
                tft_b       <= rd_data_m_tdata(23 downto 16);
            end if;

            if (state = ST_ON) then
                tft_bklt <= pwm_backlight;
            else
                tft_bklt <= '0';
            end if;
        end if;

    end process;

end Behavioral;
