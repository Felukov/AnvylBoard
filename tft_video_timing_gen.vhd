library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tft_video_timing_gen is
	port (
        clk          : in std_logic; --variable depending on RSEL_I
        clk_en       : in std_logic;
        rst          : in std_logic; --reset
        vde          : out std_logic; --data enable for pixel bus
        hs           : out std_logic;
        vs           : out std_logic;
        hcnt         : out natural;
        vcnt         : out natural
    );
end tft_video_timing_gen;

architecture Behavioral of tft_video_timing_gen is
    -- Timing Constants for 480x272 @60Hz
    ----------------------------------------------------------------------------------
    --horizontal constants
    constant H_S            : natural := 45;    --sync
    constant H_FP           : natural := 0; 	--front porch
    constant H_AV           : natural := 480; 	--active video
    constant H_BP           : natural := 0;	    --back porch

    constant H_AV_FP        : natural := H_AV + H_FP;
    constant H_AV_FP_S      : natural := H_AV + H_FP + H_S;
    constant H_AV_FP_S_BP   : natural := H_AV + H_FP + H_S + H_BP;
    --vertical constants
    constant V_S            : natural := 16;	--sync
    constant V_FP           : natural := 0; 	--front porch
    constant V_AV           : natural := 272; 	--active video
    constant V_BP           : natural := 0;	    --back porch

    constant V_AV_FP        : natural := V_AV + V_FP;
    constant V_AV_FP_S      : natural := V_AV + V_FP + V_S;
    constant V_AV_FP_S_BP   : natural := V_AV + V_FP + V_S + V_BP;

    --horizontal counter
    signal h_cnt            : natural range 0 to H_AV_FP_S_BP;
    --vertical counter
    signal v_cnt            : natural range 0 to V_AV_FP_S_BP;

begin

    vid_timing_counter_process: process(clk) begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                h_cnt   <= H_AV_FP_S_BP - 1; -- 0 is an active pixel
                v_cnt   <= V_AV_FP_S_BP - 1;
                vde     <= '0';
                hs      <= '1';
                vs      <= '1';
            elsif (clk_en = '1') then
                --pixel/line counters and video data enable
                if (h_cnt = H_AV_FP_S_BP - 1) then
                    h_cnt <= 0;
                    if (v_cnt = V_AV_FP_S_BP - 1) then
                        v_cnt <= 0;
                    else
                        v_cnt <= v_cnt + 1;
                    end if;
                else
                    h_cnt <= h_cnt + 1;
                end if;

                --sync pulse in sync phase
                if (h_cnt >= H_AV_FP-1) and (h_cnt < H_AV_FP_S-1) then -- one cycle earlier (registered)
                    hs <= '0';
                    if (v_cnt >= V_AV_FP) and (v_cnt < V_AV_FP_S) then
                        vs <= '0';
                    else
                        vs <= '1';
                    end if;
                else
                    hs <= '1';
                end if;

                --video data enable
                if ((h_cnt = H_AV_FP_S_BP - 1 and (v_cnt = V_AV_FP_S_BP - 1 or v_cnt < V_AV - 1)) or -- first pixel in frame
                     (h_cnt < H_AV - 1 and v_cnt < V_AV)) then
                    vde <= '1';
                else
                    vde <= '0';
                end if;
            end if;
        end if;
    end process;

    hcnt <= h_cnt;
    vcnt <= v_cnt;

end Behavioral;
