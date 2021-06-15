library ieee;
library unisim;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use unisim.vcomponents.all;

entity touch_ctrl_tb is
end entity touch_ctrl_tb;

architecture rtl of touch_ctrl_tb is

    -- Clock period definitions
    constant CLK_PERIOD : time := 10 ns;

    component touch_ctrl is
        port (
            -- Control/Data Signals,
            clk         : in std_logic;        -- FPGA Clock
            resetn      : in std_logic;        -- FPGA Reset

            -- SPI Interface
            SCK         : out std_logic;
            SDI         : in std_logic;
            SDO         : out std_logic
        );
    end component;

    signal CLK          : std_logic := '0';
    signal RESETN       : std_logic := '0';

    signal SCK          : std_logic;
    signal SDI          : std_logic;
    signal SDO          : std_logic;

    signal dat          : std_logic_vector(11 downto 0);

begin

    uut: touch_ctrl port map (
        clk           => CLK,
        resetn        => RESETN,

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
