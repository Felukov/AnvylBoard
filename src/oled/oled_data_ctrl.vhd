----------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Ryan Kim
--
-- Create Date:    11:50:03 10/24/2011
-- Module Name:    oled_data_ctrlample - rtl
-- Project Name:      PmodOLED Demo
-- Tool versions:  ISE 13.2
-- Description: Demo for the PmodOLED.  First displays the alphabet for ~4 seconds and then
--                Clears the display, waits for a ~1 second and then displays "This is Digilent's
--                PmodOLED"
--
-- Revision: 1.2
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity oled_data_ctrl is
    Port (
        CLK             : in std_logic; --System CLK
        resetn          : in std_logic; --Synchronous Reset
        EN              : in std_logic; --Example block enable pin
        CS              : out std_logic; --SPI Chip Select
        SDO             : out std_logic; --SPI Data out
        SCLK            : out std_logic; --SPI Clock
        DC              : out std_logic; --Data/Command Controller
        FIN             : out std_logic--Finish flag for example block
    );
end oled_data_ctrl;

architecture rtl of oled_data_ctrl is

    component oled_spi_ctrl
        port(
            clk         : in std_logic;
            resetn      : in std_logic;
            spi_en      : in std_logic;
            spi_data    : in std_logic_vector(7 downto 0);
            CS          : out std_logic;
            SDO         : out std_logic;
            SCLK        : out std_logic;
            SPI_FIN     : out std_logic
        );
    end component;

    --character library, latency = 1
    component oled_char_lib
        port (
            clk         : in std_logic; --attach system clock to it
            addra       : in std_logic_vector(10 downto 0); --first 8 bits is the ascii value of the character the last 3 bits are the parts of the char
            douta       : out std_logic_vector(7 downto 0) --data byte out
        );
    end component;

    type oled_line_t is array (0 to 15) of std_logic_vector(7 downto 0);


    function str_to_oled_line(a : string) return oled_line_t is
        variable ret : oled_line_t;
    begin
        for i in 0 to 15 loop
            ret(i) := x"20"; --space
        end loop;

        for i in a'range loop
            ret(i-1) := std_logic_vector(to_unsigned(character'pos(a(i)), 8));
        end loop;
        return ret;
    end function str_to_oled_line;

    --state_t for state machine
    type state_t is (
        Idle,
        SetPageAddr,
        SetPageCmd,
        PageNum,
        PageEnd,
        LeftColumn1,
        LeftColumn2,
        SetDC,
        LoadLogoScreen,
        UpdateScreen,
        SendChar1,
        SendChar2,
        SendChar3,
        SendChar4,
        SendChar5,
        SendChar6,
        SendChar7,
        SendChar8,
        ReadMem,
        ReadMem2,
        Done,
        SendSPI,
        WaitSPI,
        ClearAndBack
    );

    type oled_mem_t is array(0 to 7) of oled_line_t;

    --Variable that contains what the screen will be after the next UpdateScreen state
    --signal current_screen : oled_mem_t;

    constant logo_screen_text : oled_mem_t := (
        str_to_oled_line("2021           "),
        str_to_oled_line("Felukov K.S.   "),
        str_to_oled_line("made by        "),
        str_to_oled_line("Simple calc    "),
        str_to_oled_line("               "),
        str_to_oled_line("               "),
        str_to_oled_line("               "),
        str_to_oled_line("               ")
    );

    --Current overall state of the state machine
    signal current_state        : state_t;
    --State to go to after the SPI transmission is finished
    signal next_cmd             : state_t;
    --State to go to after the set page sequence
    signal after_page_state     : state_t;
    --State to go to after sending the character sequence
    signal after_char_state     : state_t;
    --State to go to after the UpdateScreen is finished
    signal after_update_state   : state_t;

    --contains the value to be outputted to dc
    signal temp_dc              : std_logic := '0';

    --variables used in the delay controller block
    signal temp_delay_ms        : std_logic_vector (11 downto 0); --amount of ms to delay
    signal temp_delay_en        : std_logic := '0'; --enable signal for the delay block
    signal temp_delay_fin       : std_logic; --finish signal for the delay block

    --variables used in the spi controller block
    signal temp_spi_en          : std_logic := '0'; --enable signal for the spi block
    signal temp_spi_data        : std_logic_vector (7 downto 0) := (others => '0'); --data to be sent out on spi
    signal temp_spi_fin         : std_logic; --finish signal for the spi block

    signal temp_char            : std_logic_vector (7 downto 0) := (others => '0'); --contains ascii value for character
    signal temp_addr            : std_logic_vector (10 downto 0) := (others => '0'); --contains address to byte needed in memory
    signal temp_dout            : std_logic_vector (7 downto 0); --contains byte outputted from memory
    signal temp_dout_inv        : std_logic_vector (7 downto 0); --contains byte outputted from memory
    signal temp_index           : integer range 0 to 15 := 15; --current character on page

    signal page_addr            : std_logic_vector (2 downto 0) := (others => '0'); --current page
    signal page_shft            : std_logic_vector (5 downto 0);

begin
    DC <= temp_dc;
    --Example finish flag only high when in done state
    FIN <= '1' when (current_state = Done) else '0';

    -- SPI Block
    oled_spi_ctrl_inst: oled_spi_ctrl port map (
        clk         => clk,
        resetn      => resetn,
        spi_en      => temp_spi_en,
        spi_data    => temp_spi_data,
        spi_fin     => temp_spi_fin,
        CS          => CS,
        SDO         => SDO,
        SCLK        => SCLK
    );

    -- Memory block
    char_lib_comp_inst : oled_char_lib port map (
        clk         => clk,
        addra       => temp_addr,
        douta       => temp_dout
    );

    -- inverse the 8 bit of ram data
    temp_dout_inv <= temp_dout(0) & temp_dout(1) & temp_dout(2) & temp_dout(3) &
                   temp_dout(4) & temp_dout(5) & temp_dout(6) & temp_dout(7);

    process (clk) begin
        if (rising_edge(clk)) then
           if resetn = '0' then
               current_state <= Idle;
            else
                case(current_state) is
                    --Idle until EN pulled high then intialize Page to 0 and go to state Alphabet afterwards
                    when Idle =>
                        if (EN = '1') then
                            page_addr <= "000";
                            current_state <= SetPageAddr;
                            after_page_state <= LoadLogoScreen;--Alphabet;
                        end if;

                    --Set currentScreen to constant logo_screen_text and update the screen.
                    when LoadLogoScreen =>
                        --current_screen <= logo_screen_text;
                        after_update_state <= Done;
                        current_state <= UpdateScreen;

                    --Do nothing until EN is deassertted and then current_state is Idle
                    when Done =>
                        if (EN = '0') then
                            current_state <= Idle;
                        end if;

                    --UpdateScreen State
                    --1. Gets ASCII value from current_screen at the current page and the current spot of the page
                    --2. If on the last character of the page transition update the page number, if on the last page(3)
                    --            then the updateScreen go to "after_update_state" after
                    when UpdateScreen =>
                        temp_char <= logo_screen_text(CONV_INTEGER(page_addr))(temp_index);
                        if (temp_index = 0) then
                            temp_index <= 15;
                            page_addr <= page_addr + 1;
                            after_char_state <= SetPageAddr;
                            if (page_addr = "111") then
                                after_page_state <= after_update_state;
                            else
                                after_page_state <= UpdateScreen;
                            end if;
                        else
                            temp_index <= temp_index - 1;
                            after_char_state <= UpdateScreen;
                        end if;
                        current_state <= SendChar1;

                    --Update Page state_t
                    --1. Sets DC to command mode
                    --2. Sends the SetPageCmd Command
                    --3. Sends the Page to be set to
                    --4. Sets the start pixel to the left column
                    --5. Sets DC to data mode
                    when SetPageAddr =>
                        temp_dc <= '0';
                        current_state <= SetPageCmd;
                    when SetPageCmd =>
                        temp_spi_data <= "00100010"; -- 0x22
                        next_cmd <= PageNum;
                        current_state <= SendSPI;
                    when PageNum =>
                        temp_spi_data <= "00000" & page_addr;
                        next_cmd <= PageEnd;
                        current_state <= SendSPI;
                    when PageEnd =>
                        temp_spi_data <= "00000000"; --The page stop is not used in this design
                        next_cmd <= LeftColumn1;
                        current_state <= SendSPI;
                    when LeftColumn1 =>
                        temp_spi_data <= "00000000";
                        next_cmd <= LeftColumn2;
                        current_state <= SendSPI;
                    when LeftColumn2 =>
                        temp_spi_data <= "00010000";
                        next_cmd <= SetDC;
                        current_state <= SendSPI;
                    when SetDC =>
                        temp_dc <= '1';
                        current_state <= after_page_state;
                    --End Update Page state_t

                    --Send Character state_t
                    --1. Sets the Address to ASCII value of char with the counter appended to the end
                    --2. Waits a clock for the data to get ready by going to ReadMem and ReadMem2 state_t
                    --3. Send the byte of data given by the block Ram
                    --4. Repeat 7 more times for the rest of the character bytes
                    when SendChar1 =>
                        temp_addr <= temp_char & "111";
                        next_cmd <= SendChar2;
                        current_state <= ReadMem;
                    when SendChar2 =>
                        temp_addr <= temp_char & "110";
                        next_cmd <= SendChar3;
                        current_state <= ReadMem;
                    when SendChar3 =>
                        temp_addr <= temp_char & "101";
                        next_cmd <= SendChar4;
                        current_state <= ReadMem;
                    when SendChar4 =>
                        temp_addr <= temp_char & "100";
                        next_cmd <= SendChar5;
                        current_state <= ReadMem;
                    when SendChar5 =>
                        temp_addr <= temp_char & "011";
                        next_cmd <= SendChar6;
                        current_state <= ReadMem;
                    when SendChar6 =>
                        temp_addr <= temp_char & "010";
                        next_cmd <= SendChar7;
                        current_state <= ReadMem;
                    when SendChar7 =>
                        temp_addr <= temp_char & "001";
                        next_cmd <= SendChar8;
                        current_state <= ReadMem;
                    when SendChar8 =>
                        temp_addr <= temp_char & "000";
                        next_cmd <= after_char_state;
                        current_state <= ReadMem;
                    when ReadMem =>
                        current_state <= ReadMem2;
                    when ReadMem2 =>
                        temp_spi_data <= temp_dout_inv;
                        current_state <= SendSPI;
                    --End Send Character state_t

                    --SPI transitions
                    --1. Set SPI_EN to 1
                    --2. Waits for SpiCtrl to finish
                    --3. Goes to clear state (ClearAndBack)
                    when SendSPI =>
                        temp_spi_en <= '1';
                        current_state <= WaitSPI;
                    when WaitSPI =>
                        if (temp_spi_fin = '1') then
                            current_state <= ClearAndBack;
                        end if;

                    --Clear transition
                    --1. Sets both DELAY_EN and SPI_EN to 0
                    --2. Go to after state
                    when ClearAndBack =>
                        temp_spi_en <= '0';
                        temp_delay_en <= '0';
                        current_state <= next_cmd;
                    --END SPI transitions
                    --END Delay Transitions
                    --END Clear transition

                    when others =>
                        current_state <= Idle;
                end case;
            end if;
        end if;
    end process;


end rtl;
