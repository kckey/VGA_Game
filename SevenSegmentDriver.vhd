library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;



entity Two_Player_Race is
 port(
 --Input
 clk: in std_logic;
 btnC: in std_logic;
 btnD: in std_logic;
 sw: in std_logic_vector(15 downto 0);
 -- Output
 seg: out std_logic_vector(6 downto 0);
 an: out std_logic_vector(3 downto 0);
 led: out std_logic_vector(15 downto 0)
 );
end Two_Player_Race;
architecture Two_Player_Race_ARCH of Two_Player_Race is
 ----General Definitions----------------------------------------------CONSTANTS
 constant DISABLE_RESET: std_logic := '0';
 constant DISABLE_DIGIT: std_logic := '1';
 constant ENABLE_DIGIT: std_logic := '0';
 constant PASSIVE: std_logic := '0';
 constant ACTIVE: std_logic := '1';
 constant NO_PATTERN: std_logic_vector(15 downto 0) := "0000000000000000";
 constant CLEAR: std_logic_vector(6 downto 0) := "0000000";
 constant PATTERN_AT_START: std_logic_vector(6 downto 0) := "0000001";

 ----Seven Segment Display for digit----------------------------------CONSTANTS
 constant ZERO_7SEG: std_logic_vector(3 downto 0) := "0000";
 constant ONE_7SEG: std_logic_vector(3 downto 0) := "0001";
 constant TWO_7SEG: std_logic_vector(3 downto 0) := "0010";
 constant THREE_7SEG: std_logic_vector(3 downto 0) := "0011"; 
 constant FOUR_7SEG: std_logic_vector(3 downto 0) := "0100";
 constant FIVE_7SEG: std_logic_vector(3 downto 0) := "0101";
 constant SIX_7SEG: std_logic_vector(3 downto 0) := "0110";
 constant SEVEN_7SEG: std_logic_vector(3 downto 0) := "0111";
 constant EIGHT_7SEG: std_logic_vector(3 downto 0) := "1000";
 constant NINE_7SEG: std_logic_vector(3 downto 0) := "1001";
 constant A_7SEG: std_logic_vector(3 downto 0) := "1010";
 constant B_7SEG: std_logic_vector(3 downto 0) := "1011";
 constant C_7SEG: std_logic_vector(3 downto 0) := "1100";
 constant D_7SEG: std_logic_vector(3 downto 0) := "1101";
 constant E_7SEG: std_logic_vector(3 downto 0) := "1110";
 constant F_7SEG: std_logic_vector(3 downto 0) := "1111";

 ----internal connections-----------------------------------------------SIGNALS
 signal digit3_value: std_logic_vector(3 downto 0);
 signal digit2_value: std_logic_vector(3 downto 0);
 signal digit1_value: std_logic_vector(3 downto 0);
 signal digit0_value: std_logic_vector(3 downto 0);
 signal digit3_blank: std_logic;
 signal digit2_blank: std_logic;
 signal digit1_blank: std_logic;
 signal digit0_blank: std_logic;
 signal ButtonSync: std_logic;
 signal Button: std_logic;
 signal P1_CountActive: std_logic;
 signal P2_CountActive: std_logic;
 signal P1_Count: std_logic;
 signal P2_Count: std_logic;
 signal reset: std_logic;
 signal P1_Decode: integer range 0 to 100;
 signal P2_Decode: integer range 0 to 100;
 signal P1_Lit: std_logic_vector (6 downto 0);
 signal P2_Lit: std_logic_vector (6 downto 0);
 signal LitFinal: std_logic_vector (15 downto 0);
 signal HitLit: std_logic_vector (15 downto 0);
 signal SwitchSync: std_logic_vector (15 downto 0);
 signal P1_victory: integer range 0 to 9;
 signal P2_victory: integer range 0 to 9;
 signal P1_Victory_Lap: std_logic;
 signal P2_Victory_Lap: std_logic;
 signal P1_Score: std_logic;
 signal P2_Score: std_logic;
 signal P1_Shift: integer range 0 to 6;
 signal P2_Shift: integer range 0 to 6;
 signal switch: std_logic_vector (15 downto 0);
 signal P1_Victory_Init: std_logic := '0';
 signal P2_Victory_Init: std_logic := '0';
 signal Victory_Lap: std_logic;
 ---state-machine-declarations----------------------------CONSTANTS
 type states is (IDLE, STAND_BY, PLAYING, P1_HITLit, P2_HITLit, BOTH_HITLit);
 signal Current_State: states;
 signal Next_State: states;

 --============================================================================
 -- Component SevenSegmentDriver
 --============================================================================
 component SevenSegmentDriver 
 port (
 reset: in std_logic; --reset
 clock: in std_logic; --clock

 digit3: in std_logic_vector(3 downto 0); --leftmost digit
 digit2: in std_logic_vector(3 downto 0); --2nd from left digit
 digit1: in std_logic_vector(3 downto 0); --2nd from right digit
 digit0: in std_logic_vector(3 downto 0); --rightmost digit

 blank3: in std_logic; --Turn on/off leftmost digit
 blank2: in std_logic; --Turn on/off 2nd from left digit
 blank1: in std_logic; --Turn on/off 2nd from right digit
 blank0: in std_logic; --Turn on/off rightmost digit

 sevenSegs: out std_logic_vector(6 downto 0); --MSB=a, LSB=g
 anodes: out std_logic_vector(3 downto 0) --MSB=leftmost digit
 );
 end component;

begin
 --============================================================================
 -- Port map of the Two_Player_Race.vhd
 --============================================================================
 MY_SEGMENTS: SevenSegmentDriver port map (
 reset => DISABLE_RESET, --reset is disabled with '0'
 clock => clk, --clk(input) is connected to clock
 digit3 => digit3_value, --connected to digit3_value signal
 digit2 => digit2_value, --connected to digit2_value signal
 digit1 => digit1_value, --connected to digit1_value signal
 digit0 => digit0_value, --connected to digit0_value signal
 blank3 => digit3_blank, --connected to digit3_blank signal
 blank2 => digit2_blank, --connected to digit2_blank signal
 blank1 => digit1_blank, --connected to digit1_blank signal
 blank0 => digit0_blank, --connected to digit0_blank signal
 sevenSegs => seg, --sevenSegs is connected to seg(output)
 anodes => an --anodes is connected to an (output)
 );

 --============================================================================
 -- STATE_REGISTER: process(reset, clk)
 -- This process will register the state machine and also reset the current
 -- state to IDLE when the reset button is activated.
 --============================================================================
 STATE_REGISTER: process(reset, clk)
 begin
 if (reset = ACTIVE) then
 Current_State <= IDLE;
 elsif (rising_edge(clk)) then
 Current_State <= Next_State;
 end if;
 end process STATE_REGISTER;

 --============================================================================
 -- STATE_TRANSITION: process(Current_State)
 -- This process will transition the Current_State with the Next_State based on
 -- the action that triggers the state to transition. This process is necessary 
 -- to detech the input of the button to trigger the Lit to appear randomly.
 --============================================================================
 STATE_TRANSITION: process(Current_State, ButtonSync, P1_Score, P2_Score,
SwitchSync)
 begin
 case Current_State is
 when IDLE =>
 P1_CountActive <= not ACTIVE;
 P2_CountActive <= not ACTIVE;
 if (ButtonSync = ACTIVE) then
 Next_State <= STAND_BY;
 else
 Next_State <= IDLE;
 end if;
 when STAND_BY =>
 P1_CountActive <= not ACTIVE;
 P2_CountActive <= not ACTIVE;
 if (ButtonSync = not ACTIVE) then
 Next_State <= PLAYING;
 else
 Next_State <= STAND_BY;
 end if;
 when PLAYING =>
 P1_CountActive <= ACTIVE;
 P2_CountActive <= ACTIVE;
 if (P1_Score = ACTIVE) then
 Next_State <= P1_HITLit;
 elsif (P2_Score = ACTIVE) then
 Next_State <= P2_HITLit;
 else
 Next_State <= PLAYING;
 end if;
 when P1_HITLit =>
 P1_CountActive <= not ACTIVE;
 P2_CountActive <= ACTIVE;
 if (SwitchSync (6 downto 0) = CLEAR) then
 Next_State <= PLAYING;
 elsif (P2_Score = ACTIVE) then
 Next_State <= BOTH_HITLit;
 else
 Next_State <= P1_HITLit;
 end if;
 when P2_HITLit =>
 P1_CountActive <= ACTIVE;
 P2_CountActive <= not ACTIVE;
 if (SwitchSync (15 downto 9) = CLEAR) then
 Next_State <= PLAYING;
 elsif (P1_Score = ACTIVE) then
 Next_State <= BOTH_HITLit;
 else
 Next_State <= P2_HITLit;
 end if;
 when BOTH_HITLit =>
 P1_CountActive <= not ACTIVE;
 P2_CountActive <= not ACTIVE;
 if (SwitchSync (6 downto 0) = CLEAR) then
 Next_State <= P2_HITLit;
 elsif (SwitchSync (15 downto 9) = CLEAR) then
 Next_State <= P1_HITLit;
 else
 Next_State <= BOTH_HITLit;
 end if;
 end case;
 end process STATE_TRANSITION;

 --============================================================================
 -- BUTTON_SYNC: process(reset, clk)
 -- This process will sync the button input to with the clock. This process will
 -- also generate the appropriate signal for the input to start the ball to
 -- move to the left.
 --============================================================================
 BUTTON_SYNC: process(reset, clk)
 begin
 if (reset = ACTIVE) then
 ButtonSync <= not ACTIVE;
 elsif (rising_edge(clk)) then
 ButtonSync <= Button;
 end if;
 end process BUTTON_SYNC;

 --============================================================================
 -- SWITCH_SYNC: process(reset, clk)
 -- This process will sync the switch input to with the clock. This process will
 -- also generate the appropriate signal for the switches to bounce the ball.
 --============================================================================
 SWITCH_SYNC: process(reset, clk)
 begin
 if (reset = ACTIVE) then
 SwitchSync <= NO_PATTERN;
 elsif (rising_edge(clk)) then
 SwitchSync <= switch;
 end if;
 end process SWITCH_SYNC;

 --============================================================================
 -- P1_COUNTER: process(reset, clk)
 -- This process will generate a pulse every second, but only if P1_CountActive
 -- is ACTIVE. If it is not ACTIVE, it will stop counting and resume once it is
 -- ACTIVE again to generate P1_Count pulse.
 --============================================================================
 P1_COUNTER: process(reset, clk)
 variable count: integer range 0 to 99999999;
 begin
 P1_Count <= '0';
 if (reset = ACTIVE) then
 count := 0;
 elsif (rising_edge(clk)) then
 if (P1_CountActive = ACTIVE) then
 if (count = 99999999) then
 P1_Count <= not P1_Count;
 count := 0;
 else
 count := count + 1;
 end if;
 else
 P1_Count <= P1_Count; 
 end if;
 end if;
 end process P1_COUNTER;

 --============================================================================
 -- P2_COUNTER: process(reset, clk)
 -- This process will generate a pulse every second, but only if P2_CountActive
 -- is ACTIVE. If it is not ACTIVE, it will stop counting and resume once it is
 -- ACTIVE again to generate P2_Count pulse.
 --============================================================================
 P2_COUNTER: process(reset, clk)
 variable count: integer range 0 to 99999999;
 begin
 P2_Count <= '0';
 if (reset = ACTIVE) then
 count := 0;
 elsif (rising_edge(clk)) then
 if (P2_CountActive = ACTIVE) then
 if (count = 99999999) then
 P2_Count <= not P2_Count;
 count := 0;
 else
 count := count + 1;
 end if;
 else
 P2_Count <= P2_Count;
 end if;
 end if;
 end process P2_COUNTER;

 --============================================================================
 -- P1_RANDOM_NUMBER_GENERATOR: process(reset, clk, P1_CountActive, P1_Count)
 -- This process will generate a random number 0 to 6. This process has a counter
 -- that counts 0 to 6 and once it reaches 6 it will reset back to 0 on the next
 -- clock cycle. If the P1_Count signal is activated, then the value of
 -- random will be sent off to a signal called P1_Shift.
 --============================================================================
 P1_RANDOM_NUMBER_GENERATOR: process(reset, clk, P1_CountActive, P1_Count)
 variable random: integer range 0 to 6;
 begin
 if (reset = ACTIVE) then
 random := 0;
 elsif (rising_edge(clk)) then
 if (P1_CountActive = ACTIVE) then
 if (random = 6) then
 random := 0;
 else
 random := random + 1;
 end if;
 end if;
 if (P1_Count = ACTIVE) then
 P1_Shift <= random;
 end if;
 end if;
 end process P1_RANDOM_NUMBER_GENERATOR;

 --============================================================================
 -- P2_RANDOM_NUMBER_GENERATOR: process(reset, clk, P2_CountActive, P2_Count) 
 -- This process will generate a random number 0 to 6. This process has a counter
 -- that counts 0 to 6 and once it reaches 6 it will reset back to 0 on the next
 -- clock cycle. If the P2_Count signal is activated, then the value of
 -- random will be sent off to a signal called P2_Shift.
 --============================================================================
 P2_RANDOM_NUMBER_GENERATOR: process(reset, clk, P2_CountActive, P2_Count)
 variable random: integer range 0 to 6;
 begin
 if (reset = ACTIVE) then
 random := 3;
 elsif (rising_edge(clk)) then
 if (P2_CountActive = ACTIVE) then
 if (random = 6) then
 random := 0;
 else
 random := random + 1;
 end if;
 end if;
 if (P2_Count = ACTIVE) then
 P2_Shift <= random;
 end if;
 end if;
 end process P2_RANDOM_NUMBER_GENERATOR;

 --============================================================================
 -- P1_Lit_GENERATOR: process(reset, clk, P1_Shift)
 -- This process will receive the P1_Shift signal from the process above called
 -- P1_RANDOM_NUMBER_GENERATOR. Since the P1_Shift signal is an integer
 -- ranging 0 to 6, it will shift equal to that value into the P1_Lit
 -- std_logic_vector once the P1_Count pulse is generated.
 --==========================================================================
 P1_Lit_GENERATOR: process(reset, clk, P1_Shift)
 variable Lit_Init: unsigned (6 downto 0);
 variable P1_shifter: integer range 0 to 6;
 begin
 if (reset = ACTIVE) then
 P1_shifter := 0;
 elsif (rising_edge(clk)) then
 if (P1_Count = ACTIVE) then
 Lit_Init := unsigned(PATTERN_AT_START);
 P1_shifter := P1_Shift;
 Lit_Init := Lit_Init sll P1_shifter;
 P1_Lit <= std_logic_vector(Lit_Init);
 end if;
 end if;
 end process P1_Lit_GENERATOR;

 --============================================================================
 -- P2_Lit_GENERATOR: process(reset, clk, P2_Shift)
 -- This process will receive the P2_Shift signal from the process above called
 -- P2_RANDOM_NUMBER_GENERATOR. Since the P2_Shift signal is an integer
 -- ranging 0 to 6, it will shift equal to that value into the P2_Lit
 -- std_logic_vector once the P2_Count pulse is generated.
 --==========================================================================
 P2_Lit_GENERATOR: process(reset, clk, P2_Shift)
 variable Lit_Init: unsigned (6 downto 0);
 variable P2_shifter: integer range 0 to 6;
 begin 
 if (reset = ACTIVE) then
 P2_shifter := 0;
 elsif (rising_edge(clk)) then
 if (P2_Count = ACTIVE) then
 Lit_Init := unsigned(PATTERN_AT_START);
 P2_shifter := P2_Shift;
 Lit_Init := Lit_Init sll P2_shifter;
 P2_Lit <= std_logic_vector(Lit_Init);
 end if;
 end if;
 end process P2_Lit_GENERATOR;

 --============================================================================
 -- INSERT_Lit: process(reset, clk, HitLit)
 -- This process will receive the P1_Lit and P2_Lit signal and concatenate
 -- the 2 signal into 16 big std_logic_vector. It will go through OR operation
 -- to add on to the it once time P1_Count or P2_Count signal is generated.
 -- This will also receive the HitLit signal to concurrently update the
 -- LitFinal. If there was a change in P2_Lit, P2_Score signal will be
 -- activated and if P1_Lit is changed, P1_Score will activated.
 --============================================================================
 INSERT_Lit: process(reset, clk, HitLit)
 variable finalLit: std_logic_vector (15 downto 0);
 begin
 P1_Score <= not ACTIVE;
 P2_Score <= not ACTIVE;
 if (reset = ACTIVE) then
 LitFinal <= NO_PATTERN;
 elsif (rising_edge(clk)) then
 if (P1_Count = ACTIVE) then
 finalLit := "000000000" & P1_Lit(6 downto 0);
 LitFinal <= LitFinal or finalLit;
 elsif (P2_Count = ACTIVE) then
 finalLit := P2_Lit(6 downto 0) & "000000000";
 LitFinal <= LitFinal or finalLit;
 end if;
 if (HitLit(15 downto 9) /= LitFinal(15 downto 9)) then
 LitFinal(15 downto 9) <= HitLit(15 downto 9);
 P2_Score <= not P2_Score;
 elsif (HitLit(6 downto 0) /= LitFinal(6 downto 0)) then
 LitFinal(6 downto 0) <= HitLit(6 downto 0);
 P1_Score <= not P1_Score;
 end if;
 end if;
 end process INSERT_Lit;

 --============================================================================
 -- Lit_HIT: process(reset, clk, LitFinal, SwitchSync)
 -- After using the truth table, the boolean expression for turning off the LED
 -- with a switch ON was LitFinal and (not(SwitchSync)). This will send off
 -- a signal that is 16 bits. This signal will be used on INSERT_Lit process.
 --============================================================================
 Lit_HIT: process(reset, clk, LitFinal, SwitchSync)
 variable HitTest: std_logic_vector(15 downto 0);
 begin
 HitLit <= LitFinal and (not(SwitchSync));
 end process Lit_HIT;
 
 --============================================================================
 -- VICTORY_COUNTER: process(clk, reset)
 -- This process generates signal pulse every 0.2 second. If P1_Victory_Init is
 -- ACTIVE then it will generate a signal to start the victory lap for P1,
 -- If P2_Victory_Init is ACTIVE, then it will generate a signal to start
 -- the victory lap for P2.
 --============================================================================
 VICTORY_COUNTER: process(clk, reset)
 variable count: integer range 0 to 20000000;
 begin
 P1_Victory_Lap <= '0';
 P2_Victory_Lap <= '0';
 if(reset= ACTIVE) then
 count := 0;
 elsif(rising_edge(clk)) then
 if(P1_Victory_Init = ACTIVE) then
 if(count = 20000000) then
 P1_Victory_Lap <= not P1_Victory_Lap;
count := 0;
 else
 count := count + 1;
 end if;
 end if;
 if(P2_Victory_Init = ACTIVE) then
 if(count = 20000000) then
 P2_Victory_Lap <= not P2_Victory_Lap;
count := 0;
 else
 count := count + 1;
 end if;
 end if;
 else
 Victory_Lap <= Victory_Lap;
 end if;
 end process VICTORY_COUNTER;

 --============================================================================
 -- P1_VICTORY_COUNT: process(clk, reset)
 -- This process receive signal pulse from VICTORY_COUNTER every 0.2 second.
 -- If P1_Victory_Init is ACTIVE then it decrement the P1_Count variable by 1.
 -- The variable will be feed into the P1_victory signal for victory lap.
 --============================================================================
 P1_VICTORY_COUNT: process(clk, reset)
 variable P1_Count: integer range 0 to 9;
 begin
 if(reset= ACTIVE) then
 P1_Count := 9;
 elsif(rising_edge(clk)) then
 if(P1_Count > 0) then
 if(P1_Victory_Lap = ACTIVE) then
 P1_Count := P1_Count -1;
P1_victory <= P1_Count;
 else
 P1_victory <= P1_Count;
 end if;
 else
 P1_Count := 9;
 end if;
 end if;
 end process P1_VICTORY_COUNT;

 --============================================================================
 -- P2_VICTORY_COUNT: process(clk, reset)
 -- This process receive signal pulse from VICTORY_COUNTER every 0.2 second.
 -- If P2_Victory_Init is ACTIVE then it decrement the P2_Count variable by 1.
 -- The variable will be feed into the P2_victory signal for victory lap.
 --============================================================================
 P2_VICTORY_COUNT: process(clk, reset)
 variable P2_Count: integer range 0 to 9;
 begin
 if(reset= ACTIVE) then
 P2_Count := 9;
 elsif(rising_edge(clk)) then
 if (P2_Count > 0) then
 if(P2_Victory_Lap = ACTIVE) then
 P2_Count := P2_Count -1;
P2_victory <= P2_Count;
 else
 P2_victory <= P2_Count;
 end if;
 else
 P2_Count := 9;
 end if;
 end if;
 end process P2_VICTORY_COUNT;

 --============================================================================
 -- SCORE_COUNT: process(reset, clk, P1_Score, P2_Score)
 -- This process will receive the P1_Score and P2_Score signal and actively
 -- count the score for player 1 and 2 and send the integer off as a signal
 -- for the DECODER process to decode and display into the seven segment display.
 -- Once the P1_Victory_Lap is activated, P2_ScoreCount will become 0 to forbid
 -- P2 to have victory lap. Same goes for P2_Victory_Lap to prevent P1 to have
 -- victory lap once the game is over.
 --============================================================================
 SCORE_COUNT: process(reset, clk, P1_Score, P2_Score, P1_Victory_Lap,
P2_Victory_Lap)
 variable P1_ScoreCount: integer range 0 to 100;
 variable P2_ScoreCount: integer range 0 to 100;
 begin
 if (reset = ACTIVE) then
 P1_ScoreCount := 0;
 P2_ScoreCount := 0;
 elsif (rising_edge(clk)) then
 if (P1_Victory_Lap = ACTIVE) then
 P2_ScoreCount := 0;
 end if;
 If (P2_Victory_Lap = ACTIVE) then
 P1_ScoreCount := 0;
 end if;
 if (P1_Score = ACTIVE) then
 P1_ScoreCount := P1_ScoreCount + 5;
 else
 P1_ScoreCount := P1_ScoreCount;
 end if;
 if (P2_Score = ACTIVE) then 
 P2_ScoreCount := P2_ScoreCount + 5;
 else
 P2_ScoreCount := P2_ScoreCount;
 end if;
 P1_Decode <= P1_ScoreCount;
 P2_Decode <= P2_ScoreCount;
 end if;
 end process SCORE_COUNT;

 --============================================================================
 -- DECODER: process(P1_Decode, P2_Decode)
 -- This process will receive the P1_Decode and P2_Decode signal and actively
 -- display the score of the players into the seven segment display. Once the
 -- P1_Decode or P2_Decode reaches 100, it will start the victory lap.
 --============================================================================
 DECODER: process(P1_Decode, P2_Decode, P1_victory, P2_victory)
 variable digitValue0: integer range 0 to 9;
 variable digitValue1: integer range 0 to 9;
 variable digitValue2: integer range 0 to 9;
 variable digitValue3: integer range 0 to 9;
 begin
 digitValue0 := P1_Decode mod 10;
 digitValue1 := P1_Decode /10;
 digitValue2 := P2_Decode mod 10;
 digitValue3 := P2_Decode /10;

 digit3_blank <= ENABLE_DIGIT;
 digit2_blank <= ENABLE_DIGIT;
 digit1_blank <= ENABLE_DIGIT;
 digit0_blank <= ENABLE_DIGIT;

 case (digitValue0) is
 when 0 =>
 digit0_value <= ZERO_7SEG;
 when 1 =>
 digit0_value <= ONE_7SEG;
 when 2 =>
 digit0_value <= TWO_7SEG;
 when 3 =>
 digit0_value <= THREE_7SEG;
 when 4 =>
 digit0_value <= FOUR_7SEG;
 when 5 =>
 digit0_value <= FIVE_7SEG;
 when 6 =>
 digit0_value <= SIX_7SEG;
 when 7 =>
 digit0_value <= SEVEN_7SEG;
 when 8 =>
 digit0_value <= EIGHT_7SEG;
 when others =>
 digit0_value <= NINE_7SEG;
 end case;

 case (digitValue1) is
 when 0 =>
 digit1_value <= ZERO_7SEG;
 when 1 => 
 digit1_value <= ONE_7SEG;
 when 2 =>
 digit1_value <= TWO_7SEG;
 when 3 =>
 digit1_value <= THREE_7SEG;
 when 4 =>
 digit1_value <= FOUR_7SEG;
 when 5 =>
 digit1_value <= FIVE_7SEG;
 when 6 =>
 digit1_value <= SIX_7SEG;
 when 7 =>
 digit1_value <= SEVEN_7SEG;
 when 8 =>
 digit1_value <= EIGHT_7SEG;
 when 9 =>
 digit1_value <= NINE_7SEG;
 when others =>
 digit1_value <= ZERO_7SEG;
 end case;

 case (digitValue2) is
 when 0 =>
 digit2_value <= ZERO_7SEG;
 when 1 =>
 digit2_value <= ONE_7SEG;
 when 2 =>
 digit2_value <= TWO_7SEG;
 when 3 =>
 digit2_value <= THREE_7SEG;
 when 4 =>
 digit2_value <= FOUR_7SEG;
 when 5 =>
 digit2_value <= FIVE_7SEG;
 when 6 =>
 digit2_value <= SIX_7SEG;
 when 7 =>
 digit2_value <= SEVEN_7SEG;
 when 8 =>
 digit2_value <= EIGHT_7SEG;
 when others =>
 digit2_value <= NINE_7SEG;
 end case;

 case (digitValue3) is
 when 0 =>
 digit3_value <= ZERO_7SEG;
 when 1 =>
 digit3_value <= ONE_7SEG;
 when 2 =>
 digit3_value <= TWO_7SEG;
 when 3 =>
 digit3_value <= THREE_7SEG;
 when 4 =>
 digit3_value <= FOUR_7SEG;
 when 5 =>
 digit3_value <= FIVE_7SEG;
 when 6 => 
 digit3_value <= SIX_7SEG;
 when 7 =>
 digit3_value <= SEVEN_7SEG;
 when 8 =>
 digit3_value <= EIGHT_7SEG;
 when 9 =>
 digit3_value <= NINE_7SEG;
 when others =>
 digit3_value <= ZERO_7SEG;
 end case;

 case (P2_victory) is
 when 9 =>
 digit3_blank <= ENABLE_DIGIT;
digit2_blank <= ENABLE_DIGIT;
 when 8 =>
 digit3_blank <= ENABLE_DIGIT;
digit3_value <= A_7SEG;
 when 7 =>
 digit2_blank <= ENABLE_DIGIT;
digit2_value <= A_7SEG;
 when 6 =>
 digit2_blank <= ENABLE_DIGIT;
 digit2_value <= B_7SEG;
 when 5 =>
 digit2_blank <= ENABLE_DIGIT;
digit2_value <= C_7SEG;
 when 4 =>
 digit2_blank <= ENABLE_DIGIT;
digit2_value <= D_7SEG;
 when 3 =>
 digit3_blank <= ENABLE_DIGIT;
digit3_value <= D_7SEG;
 when 2 =>
 digit3_blank <= ENABLE_DIGIT;
digit3_value <= E_7SEG;
 when 1 =>
 digit3_blank <= ENABLE_DIGIT;
digit3_value <= F_7SEG;
 when others =>
 digit0_blank <= DISABLE_DIGIT;
digit1_blank <= DISABLE_DIGIT;
digit2_blank <= DISABLE_DIGIT;
digit3_blank <= DISABLE_DIGIT;
 end case;

 case (P1_victory) is
 when 9 =>
 digit1_blank <= ENABLE_DIGIT;
digit0_blank <= ENABLE_DIGIT;
 when 8 =>
 digit1_blank <= ENABLE_DIGIT;
 digit1_value <= A_7SEG;
 when 7 =>
 digit0_blank <= ENABLE_DIGIT;
digit0_value <= A_7SEG;
 when 6 =>
 digit0_blank <= ENABLE_DIGIT; 
 digit0_value <= B_7SEG;
 when 5 =>
 digit0_blank <= ENABLE_DIGIT;
digit0_value <= C_7SEG;
 when 4 =>
 digit0_blank <= ENABLE_DIGIT;
digit0_value <= D_7SEG;
 when 3 =>
 digit1_blank <= ENABLE_DIGIT;
digit1_value <= D_7SEG;
 when 2 =>
 digit1_blank <= ENABLE_DIGIT;
digit1_value <= E_7SEG;
 when 1 =>
 digit1_blank <= ENABLE_DIGIT;
digit1_value <= F_7SEG;
 when others =>
 digit0_blank <= DISABLE_DIGIT;
digit1_blank <= DISABLE_DIGIT;
digit2_blank <= DISABLE_DIGIT;
digit3_blank <= DISABLE_DIGIT;
 end case;

 end process DECODER;

 --============================================================================
 -- Assigning our ports to our signals
 --============================================================================
 reset <= btnD;
 Button <= btnC;
 switch <= sw;
 led <= HitLit;
 P1_Victory_Init <= PASSIVE when (P1_decode < 99) else
 ACTIVE when (P1_decode > 99);
 P2_Victory_Init <= PASSIVE when (P2_decode < 99) else
 ACTIVE when (P2_decode > 99);

 end Two_Player_Race_ARCH; 
