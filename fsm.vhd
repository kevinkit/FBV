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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FSM is
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
           o_err : out STD_LOGIC);
       --    o_locked : out STD_LOGIC);
end FSM;

architecture Behavioral of FSM is
type FSM_MAIN is(
                    RESET, --nicht rückgesetzt
                    CHECK1STABLE,  
                    CHECK2UNSTABLE,
                    CHECK3STABLE, 
                    ERROR,
                    STAB_DONE,
                    WD_ALIGN1
                    );
signal STATE_MAIN : FSM_MAIN := RESET; --Initialwert

type FSM_STAB is(
                RESET,
                CHECK_START,
                SUCCESS,
                CHECK,
                ERROR);
signal STATE_FSM : FSM_STAB :=  RESET;
                 
                 
type FSM_WORD is(
    RESET,
    CHECK,
    ERROR
);                    
SIGNAL STATE_WORD : FSM_WORD := RESET;        
                 
                 
signal word_pending : std_logic := '0';                 
signal bitslip_buf : std_logic := '0';                 
                 
                 
                 
                 
                     
signal idelay_ld : std_logic := '0'; --init

signal stab_pending : std_logic := '0'; --0 --> init
signal stab_ack : std_logic := '0';
signal stab_err: std_logic := '0';


signal word_ack : std_logic := '0';

signal counter : std_logic_vector(3 downto 0) := (others=>'0');
signal limit : std_logic_vector(3 downto 0) := "0100";

signal idelay_limit : std_logic_vector(idelay2_tab_preset'left downto 0) := (others => '1');

signal counteridelay : std_logic_vector(idelay2_tab_preset'left downto 0) := (others => '0');

signal data_s : std_logic_vector(data'left downto 0) := (others=>'0');


signal idelay_ld_buf : std_logic := '0';
signal ce_buf : std_logic := '0';
signal idelay2_cnt_out_buf : std_logic_vector(idelay2_cnt_out'left downto 0) := (others => '0');
signal first_save: std_logic_vector(idelay2_cnt_out'left downto 0) := (others => '0');
signal second_save: std_logic_vector(idelay2_cnt_out'left downto 0) := (others => '0');



signal first_unstable : std_logic_vector(4 downto 0) := (others => '0');
signal zeros : std_logic_vector(4 downto 0) := (others => '0');
begin


iserdese2_bitslip <= bitslip_buf;
idelay2_cnt_out_buf <= idelay2_cnt_out;
--Controller, der dann in die jeweiligen anderen Zustandsautomaten springt 
FSM_MAIN_PROC: process(sysclk)
variable sum : std_logic_vector(idelay2_cnt_out'left downto 0) := (others => '0');
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
                     ce_buf <= '0';
                    --Stabilitäts Check wird angefragt
                     --Muss hier unten stehen für die höhere Priorisierung! 
                     if idelay_ctrl_rdy = '1' and resync = '1' then
                         STATE_MAIN <= CHECK1STABLE;
                         --Benachrichtigung an andere FSM geben
                         stab_pending <= '1';
                         idelay_ld_buf <= '1';
                     end if;
                     
                     
                --@Zustand: Checkt solange bis Unstabil     
                when CHECK1STABLE =>
                    --solange bis unstabil
                    idelay_ld_buf <= '0';
                    ce_buf <= stab_ack;
               --     ce_buf <= '1';
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

                --@Zustand Checkt solange bis Stabil    
                when CHECK2UNSTABLE =>
                    stab_pending <= '1';
                    idelay_ld_buf <= '0';
                    --solange bis wieder stabil                  
                    ce_buf <= stab_ack;
                    if stab_err = '0' then 
                    --_____                                  __
                    --_____ first_unstable_XXXXXXX_first_save__
                                
                        STATE_MAIN <= CHECK3STABLE;
                        first_save <= std_logic_vector(unsigned(idelay2_cnt_out_buf)); --what an ugly horrible hack...
                    end if;
                    
                    if first_unstable = zeros and idelay2_cnt_out_buf = idelay_limit then
                        STATE_MAIN <= ERROR; --war von anfang im XXX drin und ist nie raus gekommen!
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
                    
                    ce_buf <= stab_ack;
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
               
               when STAB_DONE =>
                   sum := std_logic_vector(unsigned(second_save) + unsigned(first_save));
                   counteridelay <= '0' & sum(sum'left downto 1);
                   STATE_MAIN <= WD_ALIGN1;
                   idelay_ld_buf <= '1';
                   stab_pending <= '0';
              
              
              when WD_ALIGN1 => 
               
            end case;
            
        end if;
    end if;
end process FSM_MAIN_PROC;
idelay2_tab_preset <= counteridelay;
idelay2_ld <= idelay_ld_buf;
ce <= ce_buf;
--stability check 
--Muss mit dem Pixeltakt getaktet werden (?)
--Checkt ob der ABSTASTZEITPUNKT korrekt ist
FSM_STAB_CHK: process(pix_clk)
begin
if rising_edge(pix_clk) then
    case STATE_FSM is
        when RESET =>
            data_s <= data;
            counter <= "0001";
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
            
            if stab_pending = '0' then
                STATE_FSM <= RESET;
            end if;
            

        when SUCCESS =>
            data_s <= data;
            counter <= std_logic_vector(unsigned(counter) + 1);
       --     stab_ack <= '1';
       --     stab_err <= '0';
            STATE_FSM <= CHECK;
    --        data_s <= data;
            if stab_pending = '1' then
                STATE_FSM <= CHECK;
            else
                STATE_FSM <= RESET;
             end if;
            
        when ERROR => 
            --counter <= (others=>'0');
           
           counter <= (others => '0');
           
           data_s <= data;
           counter <= std_logic_vector(unsigned(counter) + 1);
           
           -- stab_ack <= '1';
            --stab_err <= '1';
            if stab_pending = '1' then
                STATE_FSM <= CHECK;
                data_s <= data;
            else
                STATE_FSM <= RESET;       
            end if;
    end case;
end if;
end process FSM_STAB_CHK;


--wolrd alignment check
FSM_WORD_ALIGN: process(pix_clk)
begin
if rising_edge(pix_clk) then

end if;
end process FSM_WORD_ALIGN;
end Behavioral;
