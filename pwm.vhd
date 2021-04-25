library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity pwm is
    generic (
		C_CLK_I_FREQUENCY : natural := 50; -- in MHZ
		C_PWM_FREQUENCY   : natural := 20000; -- in Hz
		C_PWM_RESOLUTION  : natural := 8
	);
    port (
		CLK_I             : in STD_LOGIC;
		RST_I             : in STD_LOGIC;
        PWM_O             : out STD_LOGIC;
        DUTY_FACTOR_I     : in STD_LOGIC_VECTOR (C_PWM_RESOLUTION-1 downto 0)
	);
end pwm;

architecture Behavioral of pwm is
    constant C_CLOCK_DIVIDER : natural := C_CLK_I_FREQUENCY*1_000_000/C_PWM_FREQUENCY/2/2**C_PWM_RESOLUTION;

    signal PWMCnt            : STD_LOGIC_VECTOR (C_PWM_RESOLUTION-1 downto 0) := (others => '0');
    signal PWMCntEn          : std_logic;
    signal int_PWM           : std_logic;

begin

    prescaler_process: process (CLK_I)
    variable
        PSCnt : natural range 0 to C_CLOCK_DIVIDER := 0;
    begin
        if rising_edge(CLK_I) then
    		if (PSCnt = C_CLOCK_DIVIDER) then
    			PSCnt := 0;
    			PWMCntEn <= '1'; --enable pulse for PWM counter
    		else
    			PSCnt := PSCnt + 1;
    			PWMCntEn <= '0';
    		end if;
        end if;
    end process;

    updown_counter_process: process (CLK_I)
    variable
        PWMCntUp : boolean := true;
    begin
       if rising_edge(CLK_I) then
            if (RST_I='1') then
                PWMCnt <= (others => '0');
            elsif (PWMCntEn='1') then
                if (PWMCntUp) then
                    PWMCnt <= PWMCnt + 1;
                else
                    PWMCnt <= PWMCnt - 1;
                end if;
            end if;

    		if (PWMCnt = 0) then
    			PWMCntUp := true;
    		elsif (PWMCnt = 2**C_PWM_RESOLUTION-1) then
    			PWMCntUp := false;
    		end if;
       end if;
    end process;

    output_process: process (CLK_I, RST_I)
    begin
    	if rising_edge(CLK_I) then
    		if PWMCnt < DUTY_FACTOR_I then
    			int_PWM <= '1';
    		else
    			int_PWM <= '0';
    		end if;
    	end if;
    end process;

    PWM_O <= 'Z' when RST_I = '1' else int_PWM;

end Behavioral;
