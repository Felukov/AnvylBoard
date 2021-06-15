library ieee;
library unisim;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

entity vid_mem_gen_tb is
end entity vid_mem_gen_tb;

architecture rtl of vid_mem_gen_tb is

    -- Clock period definitions
    constant CLK_PERIOD                 : time := 10 ns;

    component vid_mem_gen is
        port (
            clk                         : in std_logic;
            resetn                      : in std_logic;

            event_s_tvalid              : in std_logic;
            event_s_tready              : out std_logic;
            event_s_tlast               : in std_logic;
            event_s_tdata               : in std_logic_vector(55 downto 0);
            event_s_tuser               : in std_logic_vector(6 downto 0);

            event_m_tvalid              : out std_logic;

            wr_m_tvalid                 : out std_logic;
            wr_m_tready                 : in std_logic;
            wr_m_tlast                  : out std_logic;
            wr_m_tdata                  : out std_logic_vector(127 downto 0);
            wr_m_taddr                  : out std_logic_vector(25 downto 0)
        );
    end component;

    signal CLK                          : std_logic := '0';
    signal RESETN                       : std_logic := '0';

    signal tft_vid_gen_tvalid           : std_logic;
    signal tft_vid_gen_tready           : std_logic;
    signal tft_vid_gen_tlast            : std_logic;
    signal tft_vid_gen_tdata            : std_logic_vector(55 downto 0);
    signal tft_vid_gen_tuser            : std_logic_vector(6 downto 0);

    signal tft_upd_tvalid               : std_logic;

    signal vid_gen_wr_tvalid            : std_logic;
    signal vid_gen_wr_tready            : std_logic;
    signal vid_gen_wr_tlast             : std_logic;
    signal vid_gen_wr_tdata             : std_logic_vector(127 downto 0);
    signal vid_gen_wr_taddr             : std_logic_vector(25 downto 0);

begin

    uut: vid_mem_gen port map (
        clk                 => CLK,
        resetn              => RESETN,

        event_s_tvalid      => tft_vid_gen_tvalid,
        event_s_tready      => tft_vid_gen_tready,
        event_s_tlast       => tft_vid_gen_tlast,
        event_s_tdata       => tft_vid_gen_tdata,
        event_s_tuser       => tft_vid_gen_tuser,

        wr_m_tvalid         => vid_gen_wr_tvalid,
        wr_m_tready         => vid_gen_wr_tready,
        wr_m_tlast          => vid_gen_wr_tlast,
        wr_m_tdata          => vid_gen_wr_tdata,
        wr_m_taddr          => vid_gen_wr_taddr,

        event_m_tvalid      => tft_upd_tvalid
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
    stimuli: process begin

        tft_vid_gen_tvalid <= '0';
        tft_vid_gen_tlast <= '0';
        tft_vid_gen_tdata <= x"FFFFFF_000000_00";

        wait for 2 ms;
        wait until rising_edge(clk);

        for col in 0 to 11 loop
            tft_vid_gen_tvalid <= '1';
            if (col = 11) then
                tft_vid_gen_tlast <= '1';
            else
                tft_vid_gen_tlast <= '0';
            end if;
            tft_vid_gen_tuser <= std_logic_vector(to_unsigned(23-col, 7));
            wait until rising_edge(clk) and tft_vid_gen_tvalid = '1' and tft_vid_gen_tready = '1';
            wait for CLK_PERIOD;

        end loop;

        tft_vid_gen_tvalid <= '0';
        wait;

    end process;

    vid_gen_wr_ready_proc : process begin
        vid_gen_wr_tready <= '1';
        wait until vid_gen_wr_tvalid = '1' and vid_gen_wr_tready = '1' and vid_gen_wr_tlast = '1';
        wait for CLK_PERIOD;

        vid_gen_wr_tready <= '0';
        wait for 1000 ns;

        vid_gen_wr_tready <= '1';
        wait for CLK_PERIOD;
    end process;

    -- -- TFT UPD Call Back
    -- tft_upd : process begin
    --     tft_upd_s_tvalid <= '0';
    --     wait until tft_m_tvalid = '1' and tft_m_tready = '1' and tft_m_tlast = '1';
    --     wait for 2*CLK_PERIOD;

    --     wait until tft_m_tready = '1';
    --     wait for CLK_PERIOD;

    --     tft_upd_s_tvalid <= '1';
    --     wait for CLK_PERIOD;

    --     tft_upd_s_tvalid <= '0';
    -- end process;

end architecture;
