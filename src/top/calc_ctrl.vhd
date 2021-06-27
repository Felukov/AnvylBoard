library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;
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

        touch_s_tvalid      : in std_logic;
        touch_s_tdata       : in std_logic_vector(7 downto 0);

        tft_upd_s_tvalid    : in std_logic;

        sseg_m_tvalid       : out std_logic;
        sseg_m_taddr        : out std_logic_vector(2 downto 0);
        sseg_m_tdata        : out std_logic_vector(3 downto 0);
        sseg_m_tuser        : out std_logic_vector(3 downto 0);

        tft_m_tvalid        : out std_logic;
        tft_m_tready        : in std_logic;
        tft_m_tlast         : out std_logic;
        tft_m_tdata         : out std_logic_vector(55 downto 0);
        tft_m_tuser         : out std_logic_vector(6 downto 0);

        led_m_tdata         : out std_logic_vector(3 downto 0)

    );
end entity calc_ctrl;

architecture rtl of calc_ctrl is
    -- Constants
    constant CH_QTY         : natural range 0 to 6 := 6;

    constant EVENT_KEY0     : std_logic_vector(3 downto 0) := x"0";
    constant EVENT_KEY1     : std_logic_vector(3 downto 0) := x"1";
    constant EVENT_KEY2     : std_logic_vector(3 downto 0) := x"2";
    constant EVENT_KEY3     : std_logic_vector(3 downto 0) := x"3";
    constant EVENT_KEY_PAD  : std_logic_vector(3 downto 0) := x"4";
    constant EVENT_TOUCH    : std_logic_vector(3 downto 0) := x"5";

    constant SSEG_DIGIT     : std_logic_vector(3 downto 0) := x"0";
    constant SSEG_NULL      : std_logic_vector(3 downto 0) := x"1";
    constant SSEG_MINUS     : std_logic_vector(3 downto 0) := x"2";

    constant GL_ADD         : std_logic_vector(4 downto 0) := std_logic_vector(to_unsigned(16, 5));
    constant GL_SUB         : std_logic_vector(4 downto 0) := std_logic_vector(to_unsigned(17, 5));
    constant GL_MUL         : std_logic_vector(4 downto 0) := std_logic_vector(to_unsigned(18, 5));
    constant GL_DIV         : std_logic_vector(4 downto 0) := std_logic_vector(to_unsigned(19, 5));
    constant GL_AND         : std_logic_vector(4 downto 0) := std_logic_vector(to_unsigned(20, 5));
    constant GL_OR          : std_logic_vector(4 downto 0) := std_logic_vector(to_unsigned(21, 5));
    constant GL_XOR         : std_logic_vector(4 downto 0) := std_logic_vector(to_unsigned(22, 5));
    constant GL_NOT         : std_logic_vector(4 downto 0) := std_logic_vector(to_unsigned(23, 5));
    constant GL_NEG         : std_logic_vector(4 downto 0) := std_logic_vector(to_unsigned(24, 5));
    constant GL_SHL         : std_logic_vector(4 downto 0) := std_logic_vector(to_unsigned(25, 5));
    constant GL_SHR         : std_logic_vector(4 downto 0) := std_logic_vector(to_unsigned(26, 5));
    constant GL_EQ          : std_logic_vector(4 downto 0) := std_logic_vector(to_unsigned(27, 5));
    constant GL_BACK        : std_logic_vector(4 downto 0) := std_logic_vector(to_unsigned(28, 5));
    constant GL_NULL        : std_logic_vector(4 downto 0) := std_logic_vector(to_unsigned(29, 5));

    constant ALU_ADD        : std_logic_vector(2 downto 0) := "000";
    constant ALU_SUB        : std_logic_vector(2 downto 0) := "001";
    constant ALU_AND        : std_logic_vector(2 downto 0) := "010";
    constant ALU_OR         : std_logic_vector(2 downto 0) := "011";
    constant ALU_XOR        : std_logic_vector(2 downto 0) := "100";
    constant ALU_INV        : std_logic_vector(2 downto 0) := "101";

    constant NUM_START_POS  : natural := 12*2-1;

    -- Types
    type num_hex_t is array (natural range 0 to 10) of std_logic_vector(3 downto 0);
    type sseg_hex_t is array (natural range 0 to 5) of std_logic_vector(3 downto 0);
    type rgb_ch_t is (R, G, B);
    type rgb_t is array (rgb_ch_t) of std_logic_vector(7 downto 0);

    type rgb_vector_t is array(4 downto 0) of rgb_t;
    type glyph_t is record
        fg                      : rgb_t;
        bg                      : rgb_t;
        glyph                   : std_logic_vector(4 downto 0);
    end record;

    component axis_reg is
        generic (
            DATA_WIDTH          : natural := 32
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;
            in_s_tvalid         : in std_logic;
            in_s_tready         : out std_logic;
            in_s_tdata          : in std_logic_vector (DATA_WIDTH-1 downto 0);
            out_m_tvalid        : out std_logic;
            out_m_tready        : in std_logic;
            out_m_tdata         : out std_logic_vector (DATA_WIDTH-1 downto 0)
        );
    end component;

    component axis_interconnect is
        generic (
            CH_QTY              : integer := 4;
            DATA_WIDTH          : integer := 32;
            USER_WIDTH          : integer := 32
        );
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            ch_in_s_tvalid      : in std_logic_vector(CH_QTY-1 downto 0);
            ch_in_s_tready      : out std_logic_vector(CH_QTY-1 downto 0);
            ch_in_s_tlast       : in std_logic_vector(CH_QTY-1 downto 0);
            ch_in_s_tdata       : in std_logic_vector(CH_QTY*DATA_WIDTH-1 downto 0);
            ch_in_s_tuser       : in std_logic_vector(CH_QTY*USER_WIDTH-1 downto 0);

            ch_out_m_tvalid     : out std_logic;
            ch_out_m_tready     : in std_logic;
            ch_out_m_tlast      : out std_logic;
            ch_out_m_tdata      : out std_logic_vector(DATA_WIDTH-1 downto 0);
            ch_out_m_tuser      : out std_logic_vector(USER_WIDTH-1 downto 0)
        );
    end component;

    component calc_alu is
        port (
            clk                 : in std_logic;
            resetn              : in std_logic;

            alu_s_tvalid        : in std_logic;
            alu_s_tready        : out std_logic;
            alu_s_tdata_a       : in std_logic_vector(11*4-1 downto 0);
            alu_s_tdata_a_sign  : in std_logic;
            alu_s_tdata_b       : in std_logic_vector(11*4-1 downto 0);
            alu_s_tdata_b_sign  : in std_logic;
            alu_s_tdata_op      : in std_logic_vector(2 downto 0);

            alu_m_tvalid        : out std_logic;
            alu_m_tready        : in std_logic;
            alu_m_tdata         : out std_logic_vector(11*4-1 downto 0);
            alu_m_tdata_sign    : out std_logic;
            alu_m_tuser_cb      : out std_logic;
            alu_m_tuser_msn     : out std_logic_vector(3 downto 0)

        );
    end component;

    function glyph_to_slv(glyph : glyph_t) return std_logic_vector is
        variable vec : std_logic_vector (55 downto 0);
    begin
        vec(55 downto 48) := glyph.fg(R);
        vec(47 downto 40) := glyph.fg(G);
        vec(39 downto 32) := glyph.fg(B);
        vec(31 downto 24) := glyph.bg(R);
        vec(23 downto 16) := glyph.bg(G);
        vec(15 downto  8) := glyph.bg(B);
        vec( 7 downto  5) := "000";
        vec( 4 downto  0) := glyph.glyph;
        return vec;
    end function;

    function slv_to_num_hex(val : std_logic_vector(11*4-1 downto 0)) return num_hex_t is
        variable num : num_hex_t;
    begin
        for i in 0 to 10 loop
            num(i) := val((i+1)*4-1 downto i*4);
        end loop;
        return num;
    end function;

    function num_hex_to_slv(num : num_hex_t) return std_logic_vector is
        variable vec : std_logic_vector(11*4-1 downto 0);
    begin
        for i in 0 to 10 loop
            vec((i+1)*4-1 downto i*4) := num(i);
        end loop;
        return vec;
    end function;

    signal event_tvalid             : std_logic;
    signal event_tready             : std_logic;
    signal event_tlast              : std_logic;
    signal event_tdata              : std_logic_vector(7 downto 0);
    signal event_tuser              : std_logic_vector(3 downto 0);

    signal num_pos                  : natural range 0 to 10;
    signal active_num_hex           : num_hex_t;
    signal active_num_hex_show_fl   : std_logic_vector(10 downto 0);
    signal active_num_hex_sign      : std_logic;
    signal buffer_num_hex           : num_hex_t;
    signal buffer_num_hex_sign      : std_logic;
    signal buffer_op                : std_logic_vector(2 downto 0);

    signal alu_s_tvalid             : std_logic;
    signal alu_s_tready             : std_logic;
    signal alu_s_tdata_a            : std_logic_vector(11*4-1 downto 0);
    signal alu_s_tdata_a_sign       : std_logic;
    signal alu_s_tdata_b            : std_logic_vector(11*4-1 downto 0);
    signal alu_s_tdata_b_sign       : std_logic;
    signal alu_s_tdata_op           : std_logic_vector(2 downto 0);
    signal alu_m_tvalid             : std_logic;
    signal alu_m_tready             : std_logic;
    signal alu_m_tdata              : std_logic_vector(11*4-1 downto 0);
    signal alu_m_tdata_hex          : num_hex_t;
    signal alu_m_tdata_sign         : std_logic;
    signal alu_m_tuser_cb           : std_logic;
    signal alu_m_tuser_msn          : std_logic_vector(3 downto 0);

    signal sseg_hex                 : sseg_hex_t;

    signal key_pad_tvalid           : std_logic;
    signal key_pad_tready           : std_logic;
    signal key_pad_tdata            : std_logic_vector(3 downto 0);

    signal key_btn0_tvalid          : std_logic;
    signal key_btn0_tready          : std_logic;
    signal key_btn1_tvalid          : std_logic;
    signal key_btn1_tready          : std_logic;
    signal key_btn2_tvalid          : std_logic;
    signal key_btn2_tready          : std_logic;
    signal key_btn3_tvalid          : std_logic;
    signal key_btn3_tready          : std_logic;

    signal touch_tvalid             : std_logic;
    signal touch_tready             : std_logic;
    signal touch_tdata              : std_logic_vector(7 downto 0);

    signal touch_glyph              : std_logic_vector(7 downto 0);

    signal inter_tvalid             : std_logic_vector(CH_QTY-1 downto 0);
    signal inter_tready             : std_logic_vector(CH_QTY-1 downto 0);
    signal inter_tdata              : std_logic_vector(8*CH_QTY-1 downto 0);
    signal inter_tuser              : std_logic_vector(4*CH_QTY-1 downto 0);

    signal sseg_loop_tvalid         : std_logic;
    signal sseg_tvalid              : std_logic;
    signal sseg_taddr               : std_logic_vector(2 downto 0);
    signal sseg_tdata               : std_logic_vector(3 downto 0);
    signal sseg_tuser               : std_logic_vector(3 downto 0);
    signal sseg_loop_cnt            : natural range 0 to 5;
    signal sseg_done_s_tvalid       : std_logic;
    signal sseg_done_m_tvalid       : std_logic;

    signal tft_loop_tvalid          : std_logic;
    signal tft_loop_tready          : std_logic;
    signal tft_loop_cnt             : natural range 0 to 11;
    signal tft_tvalid               : std_logic;
    signal tft_tready               : std_logic;
    signal tft_tlast                : std_logic;
    signal tft_tdata                : glyph_t;
    signal tft_tuser                : std_logic_vector(6 downto 0);
    signal tft_upd_m_tvalid         : std_logic;

    signal event_type               : std_logic_vector(3 downto 0);
    signal event_completed          : std_logic;
    signal event_keypad_completed   : std_logic;
    signal event_key0_completed     : std_logic;
    signal event_key3_completed     : std_logic;
    signal event_touch_completed    : std_logic;

begin

    sseg_m_tvalid <= sseg_tvalid;
    sseg_m_taddr <= sseg_taddr;
    sseg_m_tdata <= sseg_tdata;
    sseg_m_tuser <= sseg_tuser;

    tft_m_tvalid <= tft_tvalid;
    tft_tready <= tft_m_tready;
    tft_m_tlast <= tft_tlast;
    tft_m_tdata <= glyph_to_slv(tft_tdata);
    tft_m_tuser <= tft_tuser;

    tft_loop_tready <= '1' when tft_tvalid = '0' or (tft_tvalid = '1' and tft_tready = '1') else '0';

    sseg_done_s_tvalid <= '1' when sseg_tvalid = '1' and sseg_loop_cnt = 5 else '0';

    event_keypad_completed <= '1' when (event_type = EVENT_KEY_PAD) and tft_upd_m_tvalid = '1' else '0';
    event_key0_completed <= '1' when (event_type = EVENT_KEY0) and tft_upd_m_tvalid = '1' else '0';
    event_key3_completed <= '1' when (event_type = EVENT_KEY3) and tft_upd_m_tvalid = '1' else '0';
    event_touch_completed <= '1' when (event_type = EVENT_TOUCH) and sseg_done_m_tvalid = '1' and tft_upd_m_tvalid = '1' else '0';
    event_completed <= '1' when event_keypad_completed = '1' or event_key0_completed = '1' or event_key3_completed = '1' or event_touch_completed = '1' else '0';

    sseg_hex(5) <= x"0";
    sseg_hex(4) <= x"0";
    sseg_hex(3) <= x"0";
    sseg_hex(2) <= x"0";
    sseg_hex(1) <= touch_glyph( 7 downto 4);
    sseg_hex(0) <= touch_glyph( 3 downto 0);

    alu_m_tready <= '1';
    alu_m_tdata_hex <= slv_to_num_hex(alu_m_tdata);


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


    axis_reg_touch_inst : axis_reg generic map (
        DATA_WIDTH          => 8
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        in_s_tvalid         => touch_s_tvalid,
        in_s_tready         => open,
        in_s_tdata          => touch_s_tdata,

        out_m_tvalid        => touch_tvalid,
        out_m_tready        => touch_tready,
        out_m_tdata         => touch_tdata
    );


    sseg_done_reg : axis_reg generic map (
        DATA_WIDTH          => 4
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        in_s_tvalid         => sseg_done_s_tvalid,
        in_s_tready         => open,
        in_s_tdata          => x"0",

        out_m_tvalid        => sseg_done_m_tvalid,
        out_m_tready        => event_completed,
        out_m_tdata         => open
    );


    tft_upd_done_reg : axis_reg generic map (
        DATA_WIDTH          => 4
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        in_s_tvalid         => tft_upd_s_tvalid,
        in_s_tready         => open,
        in_s_tdata          => x"0",

        out_m_tvalid        => tft_upd_m_tvalid,
        out_m_tready        => event_completed,
        out_m_tdata         => open
    );


    calc_alu_inst: calc_alu port map (
        clk                 => clk,
        resetn              => resetn,

        alu_s_tvalid        => alu_s_tvalid,
        alu_s_tready        => alu_s_tready,
        alu_s_tdata_a       => alu_s_tdata_a,
        alu_s_tdata_a_sign  => alu_s_tdata_a_sign,
        alu_s_tdata_b       => alu_s_tdata_b,
        alu_s_tdata_b_sign  => alu_s_tdata_b_sign,
        alu_s_tdata_op      => alu_s_tdata_op,

        alu_m_tvalid        => alu_m_tvalid,
        alu_m_tready        => alu_m_tready,
        alu_m_tdata         => alu_m_tdata,
        alu_m_tdata_sign    => alu_m_tdata_sign,
        alu_m_tuser_cb      => alu_m_tuser_cb,
        alu_m_tuser_msn     => alu_m_tuser_msn
    );


    inter_tvalid <= touch_tvalid & key_pad_tvalid & key_btn3_tvalid & key_btn2_tvalid & key_btn1_tvalid & key_btn0_tvalid;
    touch_tready <= inter_tready(5);
    key_pad_tready <= inter_tready(4);
    key_btn3_tready <= inter_tready(3);
    key_btn2_tready <= inter_tready(2);
    key_btn1_tready <= inter_tready(1);
    key_btn0_tready <= inter_tready(0);
    inter_tdata <=
        touch_tdata &
        x"0" & key_pad_tdata &
        x"00" &
        x"00" &
        x"00" &
        x"00";
    inter_tuser <= x"5" & x"4" & x"3" & x"2" & x"1" & x"0";


    axis_interconnect_inst : axis_interconnect generic map (
        CH_QTY              => CH_QTY,
        DATA_WIDTH          => 8,
        USER_WIDTH          => 4
    ) port map (
        clk                 => clk,
        resetn              => resetn,

        ch_in_s_tvalid      => inter_tvalid,
        ch_in_s_tready      => inter_tready,
        ch_in_s_tlast       => "111111",
        ch_in_s_tdata       => inter_tdata,
        ch_in_s_tuser       => inter_tuser,

        ch_out_m_tvalid     => event_tvalid,
        ch_out_m_tready     => event_tready,
        ch_out_m_tlast      => event_tlast,
        ch_out_m_tdata      => event_tdata,
        ch_out_m_tuser      => event_tuser
    );


    ready_monitor_process: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                event_tready <= '1';
            else
                if (event_tvalid = '1' and event_tready = '1') then
                    if (event_tuser = EVENT_KEY_PAD or event_tuser = EVENT_KEY0 or
                        event_tuser = EVENT_KEY3 or event_tuser = EVENT_TOUCH) then
                        event_tready <= '0';
                    end if;
                elsif (event_tready = '0' and event_completed = '1') then
                    event_tready <= '1';
                end if;
            end if;

            if event_tvalid = '1' and event_tready = '1' then
                event_type <= event_tuser;
            end if;

        end if;
    end process;


    led_monitor_process: process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                led_m_tdata <= "0000";
            else
                if (event_tvalid = '1' and event_tready = '1') then
                    case event_tuser is
                        when EVENT_KEY_PAD =>
                            led_m_tdata <= event_tdata(3 downto 0);
                        when EVENT_TOUCH  =>
                            led_m_tdata <= "0101";
                        when EVENT_KEY0  =>
                            led_m_tdata <= "0001";
                        when EVENT_KEY1  =>
                            led_m_tdata <= "0010";
                        when EVENT_KEY2  =>
                            led_m_tdata <= "0100";
                        when EVENT_KEY3  =>
                            led_m_tdata <= "1000";
                        when others =>
                            led_m_tdata <= "0000";
                    end case;
                end if;
            end if;

        end if;
    end process;


    touch_pos_process : process (clk) begin
        if rising_edge(clk) then

            if (event_tvalid = '1' and event_tready = '1' and event_tuser = EVENT_TOUCH) then
                touch_glyph <= event_tdata(7 downto 0);
            end if;

        end if;
    end process;


    active_num_hex_update_process : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                for i in 0 to 10 loop
                    active_num_hex(i) <= x"0";
                end loop;

                for i in 1 to 10 loop
                    active_num_hex_show_fl(i) <= '0';
                end loop;
                active_num_hex_show_fl(0) <= '1';

                active_num_hex_sign <= '0';

                num_pos <= 0;
            else
                if (event_tvalid = '1' and event_tready = '1') then

                    if (event_tuser = EVENT_KEY_PAD or (event_tuser = EVENT_TOUCH and event_tdata(7 downto 4) = x"0")) then
                        if (num_pos /= 10) then
                            if not (num_pos = 0 and active_num_hex(0) = x"0") then
                                num_pos <= num_pos + 1;
                            end if;
                        end if;
                    elsif (event_tuser = EVENT_TOUCH and event_tdata = GL_BACK) then
                        if (num_pos > 0) then
                            num_pos <= num_pos - 1;
                        end if;
                    elsif (event_tuser = EVENT_KEY0 or event_tuser = EVENT_KEY3 or (event_tuser = EVENT_TOUCH and event_tdata = GL_ADD)) then
                        num_pos <= 0;
                    end if;

                    if (event_tuser = EVENT_KEY_PAD or (event_tuser = EVENT_TOUCH and event_tdata(7 downto 4) = x"0")) then

                        if (num_pos /= 10) then
                            for i in 1 to 10 loop
                                active_num_hex(i) <= active_num_hex(i-1);
                            end loop;
                            active_num_hex(0) <= event_tdata(3 downto 0);

                            if not (num_pos = 0 and active_num_hex(0) = x"0") then
                                active_num_hex_show_fl <= active_num_hex_show_fl(9 downto 0) & "1";
                            end if;
                        end if;

                    elsif (event_tuser = EVENT_TOUCH and event_tdata = GL_NEG) then
                        active_num_hex_sign <= not active_num_hex_sign;

                    elsif (event_tuser = EVENT_TOUCH and event_tdata = GL_BACK) then

                        active_num_hex(10) <= x"0";
                        for i in 0 to 9 loop
                            active_num_hex(i) <= active_num_hex(i+1);
                        end loop;

                        if (num_pos = 0 or num_pos = 1) then
                            for i in 1 to 10 loop
                                active_num_hex_show_fl(i) <= '0';
                            end loop;
                            active_num_hex_show_fl(0) <= '1';
                        else
                            active_num_hex_show_fl <= "0" & active_num_hex_show_fl(10 downto 1);
                        end if;

                    elsif (event_tuser = EVENT_KEY0 or event_tuser = EVENT_KEY3 or (event_tuser = EVENT_TOUCH and event_tdata = GL_ADD)) then

                        for i in 0 to 10 loop
                            active_num_hex(i) <= x"0";
                        end loop;

                        for i in 1 to 10 loop
                            active_num_hex_show_fl(i) <= '0';
                        end loop;
                        active_num_hex_show_fl(0) <= '1';

                        active_num_hex_sign <= '0';

                    end if;

                    if (event_tuser = EVENT_KEY3 or (event_tuser = EVENT_TOUCH and event_tdata = GL_ADD)) then
                        buffer_op <= ALU_ADD;
                    end if;

                    if (event_tuser = EVENT_KEY3 or (event_tuser = EVENT_TOUCH and event_tdata = GL_ADD)) then
                        buffer_num_hex <= active_num_hex;
                        buffer_num_hex_sign <= active_num_hex_sign;
                    end if;

                elsif alu_m_tvalid = '1' and alu_m_tready = '1' then

                    active_num_hex <= alu_m_tdata_hex;
                    active_num_hex_sign <= alu_m_tdata_sign;

                    active_num_hex_show_fl(0) <= '1';
                    for i in 1 to 10 loop
                        if unsigned(alu_m_tuser_msn) <= to_unsigned(i, 4) then
                            if (alu_m_tdata_hex(i) /= x"0") then
                                active_num_hex_show_fl(i) <= '1';
                            else
                                active_num_hex_show_fl(i) <= '0';
                            end if;
                        else
                            active_num_hex_show_fl(i) <= '0';
                        end if;
                    end loop;

                end if;

            end if;

        end if;
    end process;


    control_alu_process : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                alu_s_tvalid <= '0';
            else

                if (event_tvalid = '1' and event_tready = '1') then
                    if (event_tuser = EVENT_TOUCH and event_tdata = GL_EQ) then
                        alu_s_tvalid <= '1';
                    else
                        alu_s_tvalid <= '0';
                    end if;
                elsif (alu_s_tready = '1') then
                    alu_s_tvalid <= '0';
                end if;

            end if;

            if (event_tvalid = '1' and event_tready = '1') then
                if (event_tuser = EVENT_TOUCH and event_tdata = GL_EQ) then

                    alu_s_tdata_a <= num_hex_to_slv(buffer_num_hex);
                    alu_s_tdata_a_sign <= buffer_num_hex_sign;

                    alu_s_tdata_b <= num_hex_to_slv(active_num_hex);
                    alu_s_tdata_b_sign <= active_num_hex_sign;

                    alu_s_tdata_op <= buffer_op;

                end if;
            end if;

        end if;
    end process;


    update_sseg_process : process (clk) begin
        if rising_edge(clk) then

            if (resetn = '0') then
                sseg_loop_tvalid <= '0';
                sseg_loop_cnt <= 0;
                sseg_tvalid <= '0';
            else
                if event_tvalid = '1' and event_tready = '1' and (event_tuser = EVENT_TOUCH) then
                    sseg_loop_tvalid <= '1';
                elsif (sseg_loop_tvalid = '1' and sseg_loop_cnt = 5) then
                    sseg_loop_tvalid <= '0';
                end if;

                if (sseg_loop_tvalid = '1') then
                    if (sseg_loop_cnt = 5) then
                        sseg_loop_cnt <= 0;
                    else
                        sseg_loop_cnt <= sseg_loop_cnt + 1;
                    end if;
                end if;

                sseg_tvalid <= sseg_loop_tvalid;
            end if;

            sseg_taddr <= std_logic_vector(to_unsigned(sseg_loop_cnt, 3));
            sseg_tdata <= sseg_hex(sseg_loop_cnt);
            sseg_tuser <= SSEG_DIGIT;

            if (sseg_loop_cnt < 2) then
                sseg_tuser <= SSEG_DIGIT;
            else
                sseg_tuser <= SSEG_NULL;
            end if;

        end if;
    end process;


    update_tft_process : process (clk) begin
        if rising_edge(clk) then

            if resetn = '0' then
                tft_loop_tvalid <= '0';
                tft_loop_cnt <= 0;

                tft_tvalid <= '0';
                tft_tlast <= '0';
            else

                if event_tvalid = '1' and event_tready = '1' and (event_tuser = EVENT_KEY_PAD or event_tuser = EVENT_KEY0 or
                    event_tuser = EVENT_KEY3 or event_tuser = EVENT_TOUCH) then
                    tft_loop_tvalid <= '1';
                elsif (alu_m_tvalid = '1' and alu_m_tready = '1') then
                    tft_loop_tvalid <= '1';
                elsif (tft_loop_tvalid = '1' and tft_loop_tready = '1' and tft_loop_cnt = 11) then
                    tft_loop_tvalid <= '0';
                end if;

                if (tft_loop_tvalid = '1' and tft_loop_tready = '1') then
                    if (tft_loop_cnt = 11) then
                        tft_loop_cnt <= 0;
                    else
                        tft_loop_cnt <= tft_loop_cnt + 1;
                    end if;
                end if;

                if (tft_loop_tvalid = '1' and tft_loop_tready = '1') then
                    tft_tvalid <= '1';
                elsif (tft_tready = '1') then
                    tft_tvalid <= '0';
                end if;

                if (tft_loop_tvalid = '1' and tft_loop_tready = '1') then
                    if tft_loop_cnt = 11 then
                        tft_tlast <= '1';
                    else
                        tft_tlast <= '0';
                    end if;
                end if;

            end if;

            if (tft_loop_tvalid = '1' and tft_loop_tready = '1') then
                tft_tdata.bg(R) <= x"00";
                tft_tdata.bg(G) <= x"00";
                tft_tdata.bg(B) <= x"00";

                tft_tdata.fg(R) <= x"FF";
                tft_tdata.fg(G) <= x"FF";
                tft_tdata.fg(B) <= x"FF";

                if (tft_loop_cnt = 11) then
                    if (active_num_hex_sign = '1') then
                        tft_tdata.glyph <= GL_SUB;
                    else
                        tft_tdata.glyph <= GL_NULL;
                    end if;
                else
                    if (active_num_hex_show_fl(tft_loop_cnt) = '1') then
                        tft_tdata.glyph <= '0' & active_num_hex(tft_loop_cnt);
                    else
                        tft_tdata.glyph <= GL_NULL;
                    end if;
                end if;


                tft_tuser <= std_logic_vector(to_unsigned(NUM_START_POS - tft_loop_cnt, 7));
            end if;

        end if;
    end process;


end architecture;
