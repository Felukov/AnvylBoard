library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;
use ieee.std_logic_unsigned.all;

entity timer is
    port (
        clk_100                             : in std_logic;

        cmd_s_tvalid                        : in std_logic;
        cmd_s_tdata                         : in std_logic_vector(15 downto 0);
        cmd_s_tuser                         : in std_logic;

        pulse1ms_m_tvalid                   : out std_logic;
        pulse_m_tvalid                      : out std_logic
    );
end entity timer;

architecture rtl of timer is
    signal local_rst                        : std_logic;

    signal pulse1ms_tvalid                  : std_logic;
    signal pulse1ms_counter                 : natural range 0 to 99_999;

    signal cmd_tvalid                       : std_logic;
    signal cmd_tdata                        : natural range 0 to 2**16-1;
    signal cmd_tuser                        : std_logic;

    signal delay_tvalid                     : std_logic;
    signal delay_max                        : natural range 0 to 2**16-1;
    signal delay_one_hot                    : std_logic;
    signal delay_counter                    : natural range 0 to 2**16-1;

    signal pulse_tvalid                     : std_logic;

begin

    -- 4-bit Shift Register For resetting on startup
    -- Asserts local_rst for 4 clock periods
    SRL16_inst : SRL16E generic map (
        INIT                => X"000F"
    ) port map (
        CLK                 => clk_100,     -- Clock input
        CE                  => '1',         -- Clock enable
        D                   => '0',         -- SRL data input
        A0                  => '1',         -- Select[0] input
        A1                  => '1',         -- Select[1] input
        A2                  => '0',         -- Select[2] input
        A3                  => '0',         -- Select[3] input
        Q                   => local_rst    -- SRL data output
    );

    cmd_tvalid <= cmd_s_tvalid;
    cmd_tdata <= to_integer(unsigned(cmd_s_tdata));
    cmd_tuser <= cmd_s_tuser;

    pulse1ms_m_tvalid <= pulse1ms_tvalid;
    pulse_m_tvalid <= pulse_tvalid;

    process (clk_100) begin
        if rising_edge(clk_100) then
            if local_rst = '1' then
                pulse1ms_tvalid <= '0';
                pulse1ms_counter <= 0;
            else
                if (cmd_tvalid = '1' or pulse1ms_counter = 99_999) then
                    pulse1ms_counter <= 0;
                else
                    pulse1ms_counter <= pulse1ms_counter + 1;
                end if;

                if (pulse1ms_counter = 99_999) then
                    pulse1ms_tvalid <= '1';
                else
                    pulse1ms_tvalid <= '0';
                end if;
            end if;

        end if;
    end process;

    process (clk_100) begin
        if rising_edge(clk_100) then
            if local_rst = '1' then
                delay_tvalid <= '0';
            else

                if (cmd_tvalid = '1') then
                    delay_tvalid <= '1';
                elsif (delay_tvalid = '1' and pulse1ms_tvalid = '1' and delay_max = delay_counter and delay_one_hot = '1') then
                    delay_tvalid <= '0';
                end if;

                if (delay_tvalid = '1' and pulse1ms_tvalid = '1' and delay_max = delay_counter) then
                    pulse_tvalid <= '1';
                else
                    pulse_tvalid <= '0';
                end if;

            end if;

            if (cmd_tvalid = '1') then
                delay_max <= cmd_tdata;
                delay_one_hot <= cmd_tuser;
            end if;

            if (delay_tvalid = '1' and pulse1ms_tvalid = '1') then
                if (delay_max = delay_counter) then
                    delay_counter <= 0;
                else
                    delay_counter <= delay_counter + 1;
                end if;
            end if;

        end if;
    end process;

end architecture;
