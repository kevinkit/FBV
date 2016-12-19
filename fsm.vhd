----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.12.2016 00:03:23
-- Design Name: 
-- Module Name: FSM - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--werden für dynamische berechnung benötigt
use IEEE.math_real."ceil";
use IEEE.math_real."log2";
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FSM is
    generic(
        trainings_pattern : std_logic_vector := x"5c";
        limit : std_logic_vector := x"4"
        
    );
    Port ( sysclk : in STD_LOGIC;
           pix_clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           resync : in STD_LOGIC;
           
           --interne FPGA Signale die von außen rein kommen
           idelay_ctrl_rdy : in STD_LOGIC;
           idelay2_tab_preset : out STD_LOGIC_VECTOR(4 downto 0);
           
           idelay2_cnt_out : in std_logic_vector(4 downto 0);
           
           idelay2_ld : out STD_LOGIC; --das muss von der STAB CHECK FSM dann ausgegeben werden!
           iserdese2_bitslip : out STD_LOGIC;
           
           
          
           data : in STD_LOGIC_VECTOR(7 downto 0);
           ce : out std_logic;
           o_done : out STD_LOGIC;
           o_err : out STD_LOGIC;
           o_locked : out STD_LOGIC);
end FSM;

architecture Behavioral of FSM is
type FSM_MAIN is(
                    RESET, --nicht rückgesetzt
                    CHECK1STABLE,  
                    CHECK2UNSTABLE,
                    CHECK3STABLE, 
                    ERROR,
                    STAB_DONE,
                    WAITFOR1,
                    WD_ALIGN1,
                    DONE
                    );
signal STATE_MAIN : FSM_MAIN := RESET; --Initialwert

type FSM_STAB is(
                RESET,
                CHECK_START,
                SUCCESS,
                CHECK,
                WAITFOR,
                ERROR);
signal STATE_FSM : FSM_STAB :=  RESET;
                 
                 
type FSM_WORD is(
    RESET,
    CHECK,
    ERROR,
    DONE,
    INCR,
    WAIT1
 --   WAIT2,
 --   WAIT3
);         


           
SIGNAL STATE_WORD : FSM_WORD := RESET;        
 
signal data_buf : std_logic_vector(data'left downto 0) := (others => '0');                 
                 
signal word_pending : std_logic := '0';                 
signal bitslip_buf : std_logic := '0';                 
signal word_ack : std_logic := '0';
signal word_err : std_logic := '0';

signal wd_count : std_logic_vector(integer(ceil(log2(real(data'left)))) downto 0) := (others => '0');
--signal max_wd_count : std_logic_vector(integer(ceil(log2(real(data'left)))) downto 0) := std_logic_vector(unsigned(data'left));
--constant wd_zeros : std_logic_vector(
                     
signal idelay_ld : std_logic := '0'; --init

signal stab_pending : std_logic := '0'; --0 --> init
signal stab_ack : std_logic := '0';
signal stab_err: std_logic := '0';



signal o_locked_buf1 : std_logic := '0';
signal o_locked_buf2 : std_logic := '0';
signal o_locked_buf3 : std_logic := '0';



signal counter : std_logic_vector(3 downto 0) := (others=>'0');
--signal limit : std_logic_vector(3 downto 0) := "0100";

signal idelay_limit : std_logic_vector(idelay2_tab_preset'left downto 0) := (others => '1');

signal counteridelay : std_logic_vector(idelay2_tab_preset'left downto 0) := (others => '0');

signal data_s : std_logic_vector(data'left downto 0) := (others=>'0');
signal data_w : std_logic_vector(data'left downto 0) := (others => '0');

signal idelay_ld_buf : std_logic := '0';
signal ce_buf : std_logic := '0';
signal idelay2_cnt_out_buf : std_logic_vector(idelay2_cnt_out'left downto 0) := (others => '0');
signal first_save: std_logic_vector(idelay2_cnt_out'left downto 0) := (others => '0');
signal second_save: std_logic_vector(idelay2_cnt_out'left downto 0) := (others => '0');



signal first_unstable : std_logic_vector(4 downto 0) := (others => '0');
signal zeros : std_logic_vector(4 downto 0) := (others => '0');

signal lastbit_old : std_logic := '0';
signal lastbit_new : std_logic := '0';
signal idelay_ctrl_rdy_buf : std_logic := '0';

signal fatal_error : std_logic := '0';

begin


iserdese2_bitslip <= bitslip_buf;
idelay2_cnt_out_buf <= idelay2_cnt_out;
--Controller, der dann in die jeweiligen anderen Zustandsautomaten springt 
FSM_MAIN_PROC: process(sysclk)
variable sum : std_logic_vector(idelay2_cnt_out'left + 1 downto 0) := (others => '0');
variable dif: std_logic_vector(idelay2_cnt_out'left downto 0) := (others => '0');
begin
    if rising_edge(sysclk) then
        if rst = '1' then
            --wenn geresetet wird
            STATE_MAIN <= RESET; --Anfangszustand
        else
            case STATE_MAIN is
                when RESET =>
                     o_err <= '0';
                     o_done <= '0';
                     idelay_ld_buf <= '0';
                     stab_pending <= '0';
                    --Stabilitäts Check wird angefragt
                     --Muss hier unten stehen für die höhere Priorisierung! 
                     if idelay_ctrl_rdy = '1' and resync = '1' then
                         STATE_MAIN <= CHECK1STABLE;
                         --Benachrichtigung an andere FSM geben
                         stab_pending <= '1';
                         idelay_ld_buf <= '1';
                         counteridelay <= (others => '0');
                     end if;
                     o_locked_buf1 <= '1';
                --@Zustand: Checkt solange bis Unstabil     
                when CHECK1STABLE =>
                    o_locked_buf1 <= '0';
                    --solange bis unstabil
                    idelay_ld_buf <= '0';
                    --solange bis wieder unstabil
                    if stab_err = '1'  then
                        --_____
                        --_____ first_unstable_X...
                     
                        STATE_MAIN <= CHECK2UNSTABLE;
                        first_unstable <= idelay2_cnt_out_buf;
                    --Kann unstabilen zustand nicht finden in dieser richtung 
                    --FEHLER!
                    elsif idelay2_cnt_out_buf = idelay_limit then
                        STATE_MAIN <= ERROR;
                    end if;

                    if fatal_error = '1' then
                        STATE_MAIN <= ERROR;
                    end if;
                --@Zustand Checkt solange bis Stabil    
                when CHECK2UNSTABLE =>
                --    stab_pending <= '1';
                    idelay_ld_buf <= '0';
                    --solange bis wieder stabil                  
                    --ce_buf <= stab_ack;
                    if stab_err = '0' then 
                    --_____                                  __
                    --_____ first_unstable_XXXXXXX_first_save__
                                
                        STATE_MAIN <= CHECK3STABLE;
                        first_save <= std_logic_vector(unsigned(idelay2_cnt_out_buf)); --what an ugly horrible hack...
                    end if;
                    
                    if first_unstable = zeros and idelay2_cnt_out_buf = idelay_limit then
                        STATE_MAIN <= ERROR; --war von anfang im XXX drin und ist nie raus gekommen!
                        fatal_error <= '1';
                    elsif idelay2_cnt_out_buf = idelay_limit then
                        --war am anfang stabil kommt aber nie aus dem unstabilen zustand raus
                        first_save <= (others => '0');
                        second_save <= (others => '0');
                        STATE_MAIN <= STAB_DONE;
                    end if;
                    
                --@Zustand Checkt solange bis UnStabil  
                when CHECK3STABLE =>
                    --solange bis wieder unstabil
                    if stab_err = '1'  then
                        STATE_MAIN <= STAB_DONE;
                        idelay_ld_buf <= '1';
                    else
                        second_save <= std_logic_vector(unsigned(idelay2_cnt_out_buf) - 1);
                    end if;
                    
                 --   ce_buf <= stab_ack;
                    --falls hier nicht mehr erreicht wird -> größeren der beiden bereiche verwenden
                    if idelay2_cnt_out_buf = idelay_limit then
                        dif := std_logic_vector(unsigned(idelay_limit) - unsigned(first_save));
                        if first_unstable > dif then
                            --erster bereich ist größer als der aktuelle
                            -- _____                   ___  
                            --0_____FIRST_UNSTABLE_XXXX___
                            first_save <= (others => '0');
                            second_save <= first_unstable;
                        else
                            -- ____                             _____________________
                            --0____FIRST_UNSTABLE_XXXX_first_save____________________idelay_limit
                            second_save <= idelay_limit;
                        end if;
                    end if;
                    
               when ERROR =>
                    o_err <= '1';
                   if rst = '1' then
                    STATE_MAIN <= RESET;
                   end if;
               
                
                   if idelay_ctrl_rdy = '1' and resync = '1' then
                       STATE_MAIN <= CHECK1STABLE;
                       --Benachrichtigung an andere FSM geben
                       stab_pending <= '1';
                       idelay_ld_buf <= '1';
                   end if;
               when STAB_DONE =>
                   --sum := std_logic_vector(unsigned(second_save) + unsigned(first_save));
                   sum := std_logic_vector(unsigned('0' & second_save) + unsigned('0' & first_save));
                                    
                   counteridelay <= sum(sum'left downto 1);
                   idelay_ld_buf <= '1';
                   stab_pending <= '0';
                   if idelay_ctrl_rdy_buf = '1' then
                    STATE_MAIN <= WAITFOR1;
                   end if;
              --Verzögerung einführen
              when WAITFOR1 =>
                STATE_MAIN <= WD_ALIGN1;
                idelay_ld_buf <= '0';
                               
              when WD_ALIGN1 => 
               word_pending <= '1';
               if word_ack = '1' then
                word_pending <= '0';
                STATE_MAIN <= DONE;
                if word_err = '1' then
                    STATE_MAIN <= ERROR;
                end if;
               end if;
               
               when DONE =>
                o_done <= '1';
                STATE_MAIN <= RESET;
               
            end case;
            
        end if;
    end if;
end process FSM_MAIN_PROC;

idelay2_tab_preset <= counteridelay;
idelay2_ld <= idelay_ld_buf;
ce <= ce_buf;
idelay_ctrl_rdy_buf <= idelay_ctrl_rdy;
o_locked <= o_locked_buf1 and o_locked_buf2 and o_locked_buf3;


--stability check 
--Muss mit dem Pixeltakt getaktet werden (?)
--Checkt ob der ABSTASTZEITPUNKT korrekt ist
FSM_STAB_CHK: process(pix_clk)
begin
if rising_edge(pix_clk) then
    case STATE_FSM is
        when RESET =>
            o_locked_buf2 <= '1';
            counter <= (others => '0');
            data_s <= (others => '0');
            if stab_pending = '1' then
                STATE_FSM <= CHECK_START;
            end if;
            stab_ack <= '0';
        when CHECK_START => 
            STATE_FSM <= CHECK;
            data_s <= data;
          --  stab_ack <= '1';
        when CHECK =>
            --wenn Daten aus dem letzten Takt ungleich 
            o_locked_buf2 <= '0';
            stab_ack <= '0';
            if counter /= limit then
                if data_s = data then
                counter <= std_logic_vector(unsigned(counter) + 1);
                    data_s <= data;
                else
                    STATE_FSM <= ERROR;
                    counter <= (others=>'0');
                    stab_ack <= '1';
                    stab_err <= '1';
                end if;
            else
                STATE_FSM <= SUCCESS;
                counter <= (others=>'0');
                --überschreibt stack_ack
                stab_ack <= '1';
                stab_err <= '0';
                data_s <= data;
            end if;
            
        when SUCCESS =>
            data_s <= data;
            counter <= (others => '0');

            STATE_FSM <= WAITFOR;
            stab_err <= '0';
        when ERROR => 
            --counter <= (others=>'0');
           
           counter <= (others => '0');
           data_s <= data;
           --counter <= std_logic_vector(unsigned(counter) + 1);
            stab_err <= '1';
            STATE_FSM <= WAITFOR;
        when WAITFOR =>
            lastbit_old <= lastbit_new;
            lastbit_new <= idelay2_cnt_out_buf(0);
            ce_buf <= '1';
            --nur wenn hochgezählt wurde darf weiter gecheckt werden
            if (lastbit_old xor lastbit_new) = '1' then
                STATE_FSM <= CHECK;
                ce_buf <= '0';
            end if;
            if stab_pending = '0' then
                STATE_FSM <= RESET;
                ce_buf <= '0';
            end if;            
    end case;
end if;
end process FSM_STAB_CHK;


--wolrd alignment check
FSM_WORD_ALIGN: process(pix_clk)
begin
if rising_edge(pix_clk) then
    case STATE_WORD is 
        when RESET =>
            o_locked_buf3 <= '1';
             word_ack <= '0';
            word_err <= '0';
            wd_count(0) <= '1';
     --       wd_count <= (others => '0');
            if word_pending = '1' then
                STATE_WORD <= WAIT1;
                word_ack <= '0';
                word_err <= '0';
            end if;
        when CHECK =>
            o_locked_buf3 <= '0';
            if data = trainings_pattern then
                --Erfolg :)
                STATE_WORD <= DONE;
                word_ack <= '1';
                word_err <= '0';
                
            elsif wd_count = (wd_count'range => '0') then
                STATE_WORD <= ERROR;
                
                word_ack <= '1';
                word_err <= '1';
                
            else
                STATE_WORD <= INCR;
                wd_count <= std_logic_vector(unsigned(wd_count) + 1);
                bitslip_buf <= '1';
                data_w <= data;
            end if;
            
            
        when INCR =>
            bitslip_buf <= '0';
            STATE_WORD <= WAIT1;
        when WAIT1 =>
         --   bitslip_buf <= '0';
            if data /= data_w then
                STATE_WORD <= CHECK;
            end if;
    --    when WAIT2 =>    
    --        STATE_WORD <= WAIT3;
    --    when WAIT3 =>    
    --            STATE_WORD <= CHECK;
        when ERROR =>
            word_ack <= '1';
            word_err <= '1';
            STATE_WORD <= RESET;
            wd_count <= (others => '0');
        when DONE =>    
            word_ack <= '1';
            word_err <= '0';
            
            if word_pending = '1' then
                STATE_WORD <= CHECK;
            else
                STATE_WORD <= RESET;
            end if;
            
   
            wd_count <= (others => '0');
        end case;

end if;
end process FSM_WORD_ALIGN;
end Behavioral;
