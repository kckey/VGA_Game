library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SevenSegmentDriver is
    port (
        reset: in std_logic;
        clock: in std_logic;

        digit3: in std_logic_vector(3 downto 0);
        digit2: in std_logic_vector(3 downto 0);
        digit1: in std_logic_vector(3 downto 0);
        digit0: in std_logic_vector(3 downto 0);

        blank3: in std_logic;
        blank2: in std_logic;
        blank1: in std_logic;
        blank0: in std_logic;

        sevenSegs: out std_logic_vector(6 downto 0);
        anodes: out std_logic_vector(3 downto 0)
    );
end SevenSegmentDriver;

architecture SevenSegmentDriver_ARCH of SevenSegmentDriver is
    constant ACTIVE: std_logic := '1';
    constant COUNT_1KHZ: integer := 100000000 / 1000;

    constant SELECT_DIGIT_0: std_logic_vector(3 downto 0) := "1110";
    constant SELECT_DIGIT_1: std_logic_vector(3 downto 0) := "1101";
    constant SELECT_DIGIT_2: std_logic_vector(3 downto 0) := "1011";
    constant SELECT_DIGIT_3: std_logic_vector(3 downto 0) := "0111";
    constant SELECT_NO_DIGITS: std_logic_vector(3 downto 0) := "1111";

    constant ZERO_7SEG: std_logic_vector(6 downto 0) := "1000000";
    constant ONE_7SEG: std_logic_vector(6 downto 0) := "1111001";
    constant TWO_7SEG: std_logic_vector(6 downto 0) := "0100100";
    constant THREE_7SEG: std_logic_vector(6 downto 0) := "0110000";
    constant FOUR_7SEG: std_logic_vector(6 downto 0) := "0011001";
    constant FIVE_7SEG: std_logic_vector(6 downto 0) := "0010010";
    constant SIX_7SEG: std_logic_vector(6 downto 0) := "0000010";
    constant SEVEN_7SEG: std_logic_vector(6 downto 0) := "1111000";
    constant EIGHT_7SEG: std_logic_vector(6 downto 0) := "0000000";
    constant NINE_7SEG: std_logic_vector(6 downto 0) := "0011000";
    constant A_7SEG: std_logic_vector(6 downto 0) := "0001000";
    constant B_7SEG: std_logic_vector(6 downto 0) := "0000011";
    constant C_7SEG: std_logic_vector(6 downto 0) := "1000110";
    constant D_7SEG: std_logic_vector(6 downto 0) := "0100001";
    constant E_7SEG: std_logic_vector(6 downto 0) := "0000110";
    constant F_7SEG: std_logic_vector(6 downto 0) := "0001110";

    signal enableCount: std_logic;
    signal selectedBlank: std_logic;
    signal selectedDigit: std_logic_vector(3 downto 0);
    signal digitSelect: unsigned(1 downto 0);

begin
    with selectedDigit select
        sevenSegs <= ZERO_7SEG when "0000",
                     ONE_7SEG when "0001",
                     TWO_7SEG when "0010",
                     THREE_7SEG when "0011",
                     FOUR_7SEG when "0100",
                     FIVE_7SEG when "0101",
                     SIX_7SEG when "0110",
                     SEVEN_7SEG when "0111",
                     EIGHT_7SEG when "1000",
                     NINE_7SEG when "1001",
                     A_7SEG when "1010",
                     B_7SEG when "1011",
                     C_7SEG when "1100",
                     D_7SEG when "1101",
                     E_7SEG when "1110",
                     F_7SEG when others;

    with digitSelect select
        selectedDigit <= digit0 when "00",
                         digit1 when "01",
                         digit2 when "10",
                         digit3 when others;

    with digitSelect select
        selectedBlank <= blank0 when "00",
                         blank1 when "01",
                         blank2 when "10",
                         blank3 when others;

    ANODE_SELECT: process(selectedBlank, digitSelect)
    begin
        if (selectedBlank = ACTIVE) then
            anodes <= SELECT_NO_DIGITS;
        else
            case digitSelect is
                when "00" =>
                    anodes <= SELECT_DIGIT_0;
                when "01" =>
                    anodes <= SELECT_DIGIT_1;
                when "10" =>
                    anodes <= SELECT_DIGIT_2;
                when others =>
                    anodes <= SELECT_DIGIT_3;
            end case;
        end if;
    end process ANODE_SELECT;

    SCAN_RATE: process(reset, clock)
        variable count: integer range 0 to COUNT_1KHZ;
    begin
        enableCount <= not ACTIVE;

        if (reset = ACTIVE) then
            count := 0;
        elsif (rising_edge(clock)) then
            if (count = COUNT_1KHZ) then
                count := 0;
                enableCount <= ACTIVE;
            else
                count := count + 1;
            end if;
        end if;
    end process SCAN_RATE;

    DIGIT_COUNT: process(reset, clock)
    begin
        if (reset = ACTIVE) then
            digitSelect <= "00";
        elsif (rising_edge(clock)) then
            if (enableCount = ACTIVE) then
                digitSelect <= digitSelect + 1;
            end if;
        end if;
    end process DIGIT_COUNT;
end SevenSegmentDriver_ARCH;
