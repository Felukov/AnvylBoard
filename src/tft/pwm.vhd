library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity pwm is
    generic (
		C_CLK_FREQUENCY     : natural := 50; -- in MHZ
		C_PWM_FREQUENCY     : natural := 20000; -- in Hz
		C_PWM_RESOLUTION    : natural := 8
	);
    port (
		clk                 : in std_logic;
		rst                 : in std_logic;
        pwm_o               : out std_logic;
        duty_factor         : in std_logic_vector (C_PWM_RESOLUTION-1 downto 0)
	);
end pwm;

architecture Behavioral of pwm is
    constant C_CLOCK_DIVIDER : natural := C_CLK_FREQUENCY*1_000_000/C_PWM_FREQUENCY/2/2**C_PWM_RESOLUTION;

    signal pwm_cnt          : std_logic_vector (C_PWM_RESOLUTION-1 downto 0) := (others => '0');
    signal pwm_cnt_en       : std_logic;
    signal int_pwm          : std_logic;

begin

    prescaler_process: process (clk)
    variable
        ps_cnt : natural range 0 to C_CLOCK_DIVIDER := 0;
    begin
        if rising_edge(clk) then
    		if (ps_cnt = C_CLOCK_DIVIDER) then
    			ps_cnt := 0;
    			pwm_cnt_en <= '1'; --enable pulse for PWM counter
    		else
    			ps_cnt := ps_cnt + 1;
    			pwm_cnt_en <= '0';
    		end if;
        end if;
    end process;

    updown_counter_process: process (clk)
    variable
        pwm_cnt_up : boolean := true;
    begin
        if rising_edge(clk) then
            if (rst = '1') then
                pwm_cnt <= (others => '0');
            elsif (pwm_cnt_en='1') then
                if (pwm_cnt_up) then
                    pwm_cnt <= pwm_cnt + 1;
                else
                    pwm_cnt <= pwm_cnt - 1;
                end if;
            end if;

    		if (pwm_cnt = 0) then
    			pwm_cnt_up := true;
    		elsif (pwm_cnt = 2**C_PWM_RESOLUTION-1) then
    			pwm_cnt_up := false;
    		end if;
        end if;
    end process;

    output_process: process (clk) begin
    	if rising_edge(clk) then
    		if pwm_cnt < duty_factor then
    			int_pwm <= '1';
    		else
    			int_pwm <= '0';
    		end if;
    	end if;
    end process;

    pwm_o <= 'Z' when rst = '1' else int_pwm;

end Behavioral;
