library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use UNISIM.VComponents.all;
use ieee.std_logic_unsigned.all;

entity calc_ctrl is
    port (
        clk                 : in std_logic;
        resetn              : in std_logic;

        key_pad_s_tvalid    : in std_logic;
        key_pad_s_tdata     : in std_logic_vector(3 downto 0);

        key_btn0_s_tvalid   : in std_logic;
        key_btn1_s_tvalid   : in std_logic;
        key_btn2_s_tvalid   : in std_logic;
        key_btn3_s_tvalid   : in std_logic;

        sseg_m_tvalid       : out std_logic;
        sseg_m_tdata        : out std_logic_vector(3 downto 0);

        led_m_tdata         : out std_logic_vector(3 downto 0)
    );
end entity calc_ctrl;

architecture rtl of calc_ctrl is
    constant CH_QTY : natural range 0 to 5 := 5;

    type num_hex_t is array (natural range 0 to 5) of std_logic_vector(3 downto 0);

    component axis_reg is
        generic (
            DATA_WIDTH      : natural := 32
        );
        port (
            clk             : in std_logic;
            resetn          : in std_logic;
            in_s_tvalid     : in std_logic;
            in_s_tready     : out std_logic;
            in_s_tdata      : in std_logic_vector (DATA_WIDTH-1 downto 0);
            out_m_tvalid    : out std_logic;
            out_m_tready    : in std_logic;
            out_m_tdata     : out std_logic_vector (DATA_WIDTH-1 downto 0)
        );
    end component;

    component axis_interconnect is
        generic (
            CH_QTY          : integer := 4;
            DATA_WIDTH      : integer := 32;
            USER_WIDTH      : integer := 32
        );
        port (
            clk             : in std_logic;
            resetn          : in std_logic;

            ch_in_s_tvalid  : in std_logic_vector(CH_QTY-1 downto 0);
            ch_in_s_tready  : out std_logic_vector(CH_QTY-1 downto 0);
            ch_in_s_tlast   : in std_logic_vector(CH_QTY-1 downto 0);
            ch_in_s_tdata   : in std_logic_vector(CH_QTY*DATA_WIDTH-1 downto 0);
            ch_in_s_tuser   : in std_logic_vector(CH_QTY*USER_WIDTH-1 downto 0);

            ch_out_m_tvalid : out std_logic;
            ch_out_m_tready : in std_logic;
            ch_out_m_tlast  : out std_logic;
            ch_out_m_tdata  : out std_logic_vector(DATA_WIDTH-1 downto 0);
            ch_out_m_tuser  : out std_logic_vector(USER_WIDTH-1 downto 0)
        );
    end component;

    signal event_tvalid     : std_logic;
    signal event_tready     : std_logic;
    signal event_tlast      : std_logic;
    signal event_tdata      : std_logic_vector(3 downto 0);
    signal event_tuser      : std_logic_vector(3 downto 0);

    signal num_pos          : natural range 0 to 5;
    signal active_num_hex   : num_hex_t;
    signal buffer_num_hex   : num_hex_t;

    signal key_pad_tvalid   : std_logic;
    signal key_pad_tready   : std_logic;
    signal key_pad_tdata    : std_logic_vector(3 downto 0);

    signal key_btn0_tvalid  : std_logic;
    signal key_btn0_tready  : std_logic;
    signal key_btn1_tvalid  : std_logic;
    signal key_btn1_tready  : std_logic;
    signal key_btn2_tvalid  : std_logic;
    signal key_btn2_tready  : std_logic;
    signal key_btn3_tvalid  : std_logic;
    signal key_btn3_tready  : std_logic;

    signal inter_tvalid     : std_logic_vector(CH_QTY-1 downto 0);
    signal inter_tready     : std_logic_vector(CH_QTY-1 downto 0);
    signal inter_tdata      : std_logic_vector(4*CH_QTY-1 downto 0);
    signal inter_tuser      : std_logic_vector(4*CH_QTY-1 downto 0);

begin

    event_tready <= '1';

    axis_reg_key_pad_inst : axis_reg generic map (
        DATA_WIDTH          => 4
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        in_s_tvalid         => key_pad_s_tvalid,
        in_s_tready         => open,
        in_s_tdata          => key_pad_s_tdata,

        out_m_tvalid        => key_pad_tvalid,
        out_m_tready        => key_pad_tready,
        out_m_tdata         => key_pad_tdata
    );

    axis_reg_key_btn0_inst : axis_reg generic map (
        DATA_WIDTH          => 4
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        in_s_tvalid         => key_btn0_s_tvalid,
        in_s_tready         => open,
        in_s_tdata          => x"0",

        out_m_tvalid        => key_btn0_tvalid,
        out_m_tready        => key_btn0_tready,
        out_m_tdata         => open
    );

    axis_reg_key_btn1_inst : axis_reg generic map (
        DATA_WIDTH          => 4
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        in_s_tvalid         => key_btn1_s_tvalid,
        in_s_tready         => open,
        in_s_tdata          => x"0",

        out_m_tvalid        => key_btn1_tvalid,
        out_m_tready        => key_btn1_tready,
        out_m_tdata         => open
    );

    axis_reg_key_btn2_inst : axis_reg generic map (
        DATA_WIDTH          => 4
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        in_s_tvalid         => key_btn2_s_tvalid,
        in_s_tready         => open,
        in_s_tdata          => x"0",

        out_m_tvalid        => key_btn2_tvalid,
        out_m_tready        => key_btn2_tready,
        out_m_tdata         => open
    );

    axis_reg_key_btn3_inst : axis_reg generic map (
        DATA_WIDTH          => 4
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        in_s_tvalid         => key_btn3_s_tvalid,
        in_s_tready         => open,
        in_s_tdata          => x"0",

        out_m_tvalid        => key_btn3_tvalid,
        out_m_tready        => key_btn3_tready,
        out_m_tdata         => open
    );

    inter_tvalid <= key_pad_tvalid & key_btn3_tvalid & key_btn2_tvalid & key_btn1_tvalid & key_btn0_tvalid;
    key_pad_tready <= inter_tready(4);
    key_btn3_tready <= inter_tready(3);
    key_btn2_tready <= inter_tready(2);
    key_btn1_tready <= inter_tready(1);
    key_btn0_tready <= inter_tready(0);
    inter_tdata <= key_pad_tdata & x"0" & x"0" & x"0" & x"0";
    inter_tuser <= x"4" & x"3" & x"2" & x"1" & x"0";

    axis_interconnect_inst : axis_interconnect generic map (
        CH_QTY              => 5,
        DATA_WIDTH          => 4,
        USER_WIDTH          => 4
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        ch_in_s_tvalid      => inter_tvalid,
        ch_in_s_tready      => inter_tready,
        ch_in_s_tlast       => "11111",
        ch_in_s_tdata       => inter_tdata,
        ch_in_s_tuser       => inter_tuser,

        ch_out_m_tvalid     => event_tvalid,
        ch_out_m_tready     => event_tready,
        ch_out_m_tlast      => event_tlast,
        ch_out_m_tdata      => event_tdata,
        ch_out_m_tuser      => event_tuser
    );

    sseg_m_tvalid <= '0';
    sseg_m_tdata <= x"0";

    led_monitor_process: process (clk) begin

        if rising_edge(clk) then
            if resetn = '0' then
                led_m_tdata <= "0000";
            else
                if (event_tvalid = '1' and event_tready = '1') then
                    if event_tuser = x"4" then
                        led_m_tdata <= event_tdata;
                    elsif event_tuser = x"0" then
                        led_m_tdata <= "0001";
                    elsif event_tuser = x"1" then
                        led_m_tdata <= "0010";
                    elsif event_tuser = x"2" then
                        led_m_tdata <= "0100";
                    elsif event_tuser = x"3" then
                        led_m_tdata <= "1000";
                    end if;
                end if;
            end if;
        end if;

    end process;


    -- latch_event : process (clk) begin

    --     if rising_edge(clk) then
    --         if resetn = '0' then
    --             event_tvalid <= '1';
    --         else
    --             event_tvalid <= key_pad_s_tvalid or key_btn0_s_tvalid or key_btn1_s_tvalid or key_btn2_s_tvalid or key_btn3_s_tvalid;
    --         end if;

    --         if key_pad_s_tvalid = '1' then
    --             event_tdata <= key_pad_s_tdata;
    --         end if;
    --     end if;

    -- end process;


    -- handle_active_num_events : process (clk) begin

    --     if rising_edge(clk) then
    --         if resetn = '0' then
    --             num_pos <= 0;
    --         else
    --             if event_tvalid = '1' then
    --                 if num_pos = 5 then
    --                     num_pos <= 0;
    --                 else
    --                     num_pos <= num_pos + 1;
    --                 end if;
    --             end if;

    --             if event_tvalid = '1' then
    --                 active_num_hex(num_pos) <= event_tdata;
    --             end if;

    --         end if;
    --     end if;

    -- end process;

end architecture;