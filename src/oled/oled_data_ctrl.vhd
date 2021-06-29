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
            CLK        : in std_logic;
            resetn     : in std_logic;
            SPI_EN     : in std_logic;
            SPI_DATA   : in std_logic_vector(7 downto 0);
            CS         : out std_logic;
            SDO        : out std_logic;
            SCLK       : out std_logic;
            SPI_FIN    : out std_logic
        );
    end component;

    component oled_delay
        port(
            clk        : in std_logic;
            resetn     : in std_logic;
            delay_ms   : in std_logic_vector(11 downto 0);
            delay_en   : in std_logic;
            delay_fin  : out std_logic
        );
    end component;

    --character library, latency = 1
    component oled_char_lib
        port (
            clk       : in std_logic; --attach system clock to it
            addra      : in std_logic_vector(10 downto 0); --first 8 bits is the ascii value of the character the last 3 bits are the parts of the char
            douta      : out std_logic_vector(7 downto 0) --data byte out
        );
    end component;

    -- COMPONENT butterfly_ram
    -- PORT (
    --     clk : IN std_logic;
    --     wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    --     addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    --     dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    --     douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    -- );
    -- end COMPONENT;

    --States for state machine
    type states is (
        Idle,
        SetPageAddr,
        SetPageCmd,
        PageNum,
        PageEnd,
        LeftColumn1,
        LeftColumn2,
        SetDC,
        Alphabet,
        Wait1,
        Wait2,
        ClearScreen,
        Wait3,
        ZedboardScreen,
        ScrollSetPageAddr,
        ScrollDisplay1,
        ScrollDisplay2,
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
        Transition1,
        Transition2,
        Transition3,
        Transition4,
        Transition5
    );

    type OledMem is array(0 to 7, 0 to 15) of STD_LOGIC_VECTOR(7 downto 0);

    --Variable that contains what the screen will be after the next UpdateScreen state
    signal current_screen : OledMem;
    --Constant that holds "Zedboard's OLED Display" followed by Alphabet and numbers
    constant zedboard_screen : OledMem:= (
                                        (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                        (X"50",X"6D",X"6F",X"64",X"4F",X"4C",X"45",X"44",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                        (X"44",X"69",X"67",X"69",X"6C",X"65",X"6E",X"74",X"27",X"73",X"20",X"20",X"20",X"20",X"20",X"20"),
                                        (X"54",X"68",X"69",X"73",X"20",X"69",X"73",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                        (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                        (X"50",X"6D",X"6F",X"64",X"4F",X"4C",X"45",X"44",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                        (X"44",X"69",X"67",X"69",X"6C",X"65",X"6E",X"74",X"27",X"73",X"20",X"20",X"20",X"20",X"20",X"20"),
                                        (X"54",X"68",X"69",X"73",X"20",X"69",X"73",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20")
                                        );

    --Current overall state of the state machine
    signal current_state : states := Idle;
    --State to go to after the SPI transmission is finished
    signal after_state : states;
    --State to go to after the set page sequence
    signal after_page_state : states;
    --State to go to after sending the character sequence
    signal after_char_state : states;
    --State to go to after the UpdateScreen is finished
    signal after_update_state : states;

    --Contains the value to be outputted to DC
    signal temp_dc : STD_LOGIC := '0';

    --Variables used in the Delay Controller Block
    signal temp_delay_ms : STD_LOGIC_VECTOR (11 downto 0); --amount of ms to delay
    signal temp_delay_en : STD_LOGIC := '0'; --Enable signal for the delay block
    signal temp_delay_fin : STD_LOGIC; --Finish signal for the delay block

    --Variables used in the SPI controller block
    signal temp_spi_en : STD_LOGIC := '0'; --Enable signal for the SPI block
    signal temp_spi_data : STD_LOGIC_VECTOR (7 downto 0) := (others => '0'); --Data to be sent out on SPI
    signal temp_spi_fin : STD_LOGIC; --Finish signal for the SPI block

    signal temp_char : STD_LOGIC_VECTOR (7 downto 0) := (others => '0'); --Contains ASCII value for character
    signal temp_addr : STD_LOGIC_VECTOR (10 downto 0) := (others => '0'); --Contains address to BYTE needed in memory
    signal temp_dout : STD_LOGIC_VECTOR (7 downto 0); --Contains byte outputted from memory
    signal temp_dout_inv : STD_LOGIC_VECTOR (7 downto 0); --Contains byte outputted from memory
    signal temp_index : integer range 0 to 15 := 15; --Current character on page

    signal page_addr : STD_LOGIC_VECTOR (2 downto 0) := (others => '0'); --Current page
    signal page_shft : std_logic_vector (5 downto 0) := "100000";

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

    -- Delay block
    oled_delay_inst: oled_delay port map (
        clk         => clk,
        resetn      => resetn,
        delay_ms    => temp_delay_ms,
        delay_en    => temp_delay_en,
        delay_fin   => temp_delay_fin
    );

    -- Memory block
    char_lib_comp_inst : oled_char_lib port map (
        clk        => clk,
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
						if(EN = '1') then
							page_addr <= "000";
							current_state <= SetPageAddr;
							after_page_state <= ZedboardScreen;--Alphabet;
						end if;

					--Set currentScreen to constant zedboard_screen and update the screen.
					when ZedboardScreen =>
						current_screen <= zedboard_screen;
						after_update_state <= Wait3;
						current_state <= UpdateScreen;
					when Wait3 =>
						temp_delay_ms <= "011111010000"; --2000
						after_state <= ScrollSetPageAddr;
						current_state <= Transition3;

					-- Scroll through the OLED memory
					when ScrollSetPageAddr =>
						temp_dc <= '0';
						current_state <= ScrollDisplay1;
					when ScrollDisplay1=>
						temp_spi_data <= "01" & page_shft; --0x40 + 0x??
						after_state <= ScrollDisplay2;
						current_state <= Transition1;
					when ScrollDisplay2 =>
						temp_delay_ms <= "000001111101"; --125 (8 lines per second)
						page_shft <= page_shft + 1;
						after_state <= ScrollDisplay1;
						current_state <= Transition3;

					--Do nothing until EN is deassertted and then current_state is Idle
					when Done			=>
						if (EN = '0') then
							current_state <= Idle;
						end if;

					--UpdateScreen State
					--1. Gets ASCII value from current_screen at the current page and the current spot of the page
					--2. If on the last character of the page transition update the page number, if on the last page(3)
					--			then the updateScreen go to "after_update_state" after
					when UpdateScreen =>
						temp_char <= current_screen(CONV_INTEGER(page_addr),temp_index);
						if (temp_index = 0) then
							temp_index <= 15;
							page_addr <= page_addr + 1;
							after_char_state <= SetPageAddr;
							if(page_addr = "111") then
								after_page_state <= after_update_state;
							else
								after_page_state <= UpdateScreen;
							end if;
						else
							temp_index <= temp_index - 1;
							after_char_state <= UpdateScreen;
						end if;
						current_state <= SendChar1;

					--Update Page states
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
						after_state <= PageNum;
						current_state <= Transition1;
					when PageNum =>
						temp_spi_data <= "00000" & page_addr;
						after_state <= PageEnd;
						current_state <= Transition1;
					when PageEnd =>
						temp_spi_data <= "00000000"; --The page stop is not used in this design
						after_state <= LeftColumn1;
						current_state <= Transition1;
					when LeftColumn1 =>
						temp_spi_data <= "00000000";
						after_state <= LeftColumn2;
						current_state <= Transition1;
					when LeftColumn2 =>
						temp_spi_data <= "00010000";
						after_state <= SetDC;
						current_state <= Transition1;
					when SetDC =>
						temp_dc <= '1';
						current_state <= after_page_state;
					--End Update Page States

					--Send Character States
					--1. Sets the Address to ASCII value of char with the counter appended to the end
					--2. Waits a clock for the data to get ready by going to ReadMem and ReadMem2 states
					--3. Send the byte of data given by the block Ram
					--4. Repeat 7 more times for the rest of the character bytes
					when SendChar1 =>
						temp_addr <= temp_char & "111";
						after_state <= SendChar2;
						current_state <= ReadMem;
					when SendChar2 =>
						temp_addr <= temp_char & "110";
						after_state <= SendChar3;
						current_state <= ReadMem;
					when SendChar3 =>
						temp_addr <= temp_char & "101";
						after_state <= SendChar4;
						current_state <= ReadMem;
					when SendChar4 =>
						temp_addr <= temp_char & "100";
						after_state <= SendChar5;
						current_state <= ReadMem;
					when SendChar5 =>
						temp_addr <= temp_char & "011";
						after_state <= SendChar6;
						current_state <= ReadMem;
					when SendChar6 =>
						temp_addr <= temp_char & "010";
						after_state <= SendChar7;
						current_state <= ReadMem;
					when SendChar7 =>
						temp_addr <= temp_char & "001";
						after_state <= SendChar8;
						current_state <= ReadMem;
					when SendChar8 =>
						temp_addr <= temp_char & "000";
						after_state <= after_char_state;
						current_state <= ReadMem;
					when ReadMem =>
						current_state <= ReadMem2;
					when ReadMem2 =>
						temp_spi_data <= temp_dout_inv;
						current_state <= Transition1;
					--End Send Character States

					--SPI transitions
					--1. Set SPI_EN to 1
					--2. Waits for SpiCtrl to finish
					--3. Goes to clear state (Transition5)
					when Transition1 =>
						temp_spi_en <= '1';
						current_state <= Transition2;
					when Transition2 =>
						if(temp_spi_fin = '1') then
							current_state <= Transition5;
						end if;

					--Delay Transitions
					--1. Set DELAY_EN to 1
					--2. Waits for Delay to finish
					--3. Goes to Clear state (Transition5)
					when Transition3 =>
						temp_delay_en <= '1';
						current_state <= Transition4;
					when Transition4 =>
						if(temp_delay_fin = '1') then
							current_state <= Transition5;
						end if;

					--Clear transition
					--1. Sets both DELAY_EN and SPI_EN to 0
					--2. Go to after state
					when Transition5 =>
						temp_spi_en <= '0';
						temp_delay_en <= '0';
						current_state <= after_state;
					--END SPI transitions
					--END Delay Transitions
					--END Clear transition

					when others 		=>
						current_state <= Idle;
				end case;
            end if;
        end if;
    end process;


end rtl;
