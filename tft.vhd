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
library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;

entity tft is
    Port (
        clk_100                              : in std_logic;
        init_done                            : in std_logic;
        ctrl_en                              : in std_logic;
        tft_clk                              : out std_logic;
        tft_de                               : out std_logic;
        tft_vidden                           : out std_logic;
        tft_disp                             : out std_logic;
        tft_bklt                             : out std_logic;
        tft_r                                : out std_logic_vector(7 downto 0);
        tft_g                                : out std_logic_vector(7 downto 0);
        tft_b                                : out std_logic_vector(7 downto 0)
    );
end tft;

architecture Behavioral of tft is
    constant CLOCKFREQ                      : natural := 9; --MHZ
    constant TPOWERUP                       : natural := 1; --ms
    constant TPOWERDOWN                     : natural := 1; --ms
    constant TLEDWARMUP                     : natural := 200; --ms
    constant TLEDCOOLDOWN                   : natural := 200; --ms
    constant TLEDWARMUP_CYCLES              : natural := natural(CLOCKFREQ*TLEDWARMUP*1000);
    constant TLEDCOOLDOWN_CYCLES            : natural := natural(CLOCKFREQ*TLEDCOOLDOWN*1000);
    constant TPOWERUP_CYCLES                : natural := natural(CLOCKFREQ*TPOWERUP*1000);
    constant TPOWERDOWN_CYCLES              : natural := natural(CLOCKFREQ*TPOWERDOWN*1000);

    component pwm
        generic (
            C_CLK_I_FREQUENCY : natural;
            C_PWM_FREQUENCY   : natural;
            C_PWM_RESOLUTION  : natural
        );
    	port (
    		CLK_I            : IN std_logic;
    		RST_I            : IN std_logic;
            DUTY_FACTOR_I    : in std_logic_vector (C_PWM_RESOLUTION-1 downto 0);
    		PWM_O            : OUT std_logic
        );
    end component;

    COMPONENT tft_video_timing_gen
       PORT(
            clk             : IN std_logic;
            clk_en          : IN std_logic;
            rst             : IN std_logic;
            vde             : OUT std_logic;
            hs              : OUT std_logic;
            vs              : OUT std_logic;
            hcnt            : OUT natural;
            vcnt            : OUT natural
    );
    END COMPONENT;

    type state_t is (ST_OFF, ST_POWER_UP, ST_LED_WARM_UP, ST_LED_COOL_DOWN, ST_POWER_DOWN, ST_ON);

    signal state_next, state                : state_t := ST_POWER_DOWN;
    signal tft_clk_counter                  : integer range 0 to 65535;
    signal tft_clk_counter_vec              : std_logic_vector(15 downto 0);
    signal tft_clk_ovf                      : std_logic;
    signal tft_clk_ovf_prev                 : std_logic;
    signal tft_clk_en                       : std_logic;

    signal local_rst                        : std_logic;

    signal delay_cnt                        : natural range 0 to TLEDCOOLDOWN_CYCLES := 0;
    signal delay_reload                     : std_logic;
    signal delay_event_power_up             : std_logic;
    signal delay_event_power_down           : std_logic;
    signal delay_event_led_warm_up          : std_logic;
    signal delay_event_led_cool_down        : std_logic;

    signal pwm_backlight                    : std_logic;
    signal vde                              : std_logic;

begin

    --4-bit Shift Register For resetting on startup
    --Asserts local_rst for 4 clock periods
    SRL16_inst : SRL16E generic map (
        INIT              => X"000F"
    ) port map (
        CLK               => clk_100,     -- Clock input
        CE                => init_done,   -- Clock enable
        D                 => '0',         -- SRL data input
        A0                => '1',         -- Select[0] input
        A1                => '1',         -- Select[1] input
        A2                => '0',         -- Select[2] input
        A3                => '0',         -- Select[3] input
        Q                 => local_rst    -- SRL data output
    );

    pwm_inst: pwm generic map (
        C_CLK_I_FREQUENCY => 100, -- in MHZ
        C_PWM_FREQUENCY   => 25_000, -- in Hz
        C_PWM_RESOLUTION  => 3
    ) port map (
        CLK_I             => clk_100,
        RST_I             => local_rst,
        PWM_O             => pwm_backlight,
        DUTY_FACTOR_I     => "111"
    );

    tft_video_timing_gen_inst: tft_video_timing_gen port map(
        clk               => clk_100,
        clk_en            => tft_clk_en,
        rst               => local_rst,
        vde               => vde,
        hs                => open,
        vs                => open,
        hcnt              => open,
        vcnt              => open
    );


    tft_clk_counter_vec <= std_logic_vector(to_unsigned(tft_clk_counter, 16));
    -- the process generates 9MHZ clock for TFT
    tft_clk_process: process(clk_100) begin
        -- counting
        if (rising_edge(clk_100)) then
            if (local_rst = '1') then
                tft_clk_counter <= 0;
            else
                tft_clk_counter <= (tft_clk_counter + 5898) mod 65535;
            end if;
        end if;
        --get msb
        if (rising_edge(clk_100)) then
            if (local_rst = '1') then
                tft_clk_ovf <= '0';
            else
                tft_clk_ovf <= tft_clk_counter_vec(tft_clk_counter_vec'left);
            end if;
        end if;
        --latch prev value
        if (rising_edge(clk_100)) then
            if (local_rst = '1') then
                tft_clk_ovf_prev <= '0';
            else
                tft_clk_ovf_prev <= tft_clk_ovf;
            end if;
        end if;
        --generate pulse
        if (rising_edge(clk_100)) then
            if (local_rst = '1') then
                tft_clk_en <= '0';
            else
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
                tft_r       <= (others => '1');
                tft_g       <= (others => '1');
                tft_b       <= (others => '0');
            end if;

            if (state = ST_ON) then
                tft_bklt <= pwm_backlight;
            else
                tft_bklt <= '0';
            end if;
        end if;

    end process;

end Behavioral;
