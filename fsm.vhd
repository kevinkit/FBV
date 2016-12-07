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
--use IEEE.NUMERIC_STD.ALL;

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
           idelay2_tab_preset : out STD_LOGIC;
           idelay2_ld : out STD_LOGIC;
           iserdese2_bitslip : out STD_LOGIC;
           data : out STD_LOGIC;
           o_done : in STD_LOGIC;
           o_err : in STD_LOGIC;
           o_locked : in STD_LOGIC);
end FSM;

architecture Behavioral of FSM is
type FSM_MAIN is(
                    MAIN_RST, --nicht rückgesetzt
                    MAIN_STAB_CHK_REQ,  --bester abtastatpunkt (von außen angefragt)
                    MAIN_WD_ALIGN_CHECK_REQ, --word alginment  (von außen angefragt)
                    MAIN_ERROR,
                    MAIN_DONE);
signal STATE_MAIN : FSM_MAIN := MAIN_RST; --Initialwert
                    


signal stab_pending : std_logic := '0'; --0 --> init
signal stab_ack : std_logic := '0';


signal word_pending : std_logic := '0';
signal word_ack : std_logic := '0';

begin

--Controller, der dann in die jeweiligen anderen Zustandsautomaten springt 
FSM_MAIN: process(sysclk)-
begin
    if rising_edge(sysclk) then
        if rst = '1' then
            --wenn geresetet wird
            STATE_MAIN <= MAIN_RST; --Anfangszustand
        else
            case STATE_MAIN is
                when MAIN_RST =>
                    --Stabilitäts Check wird angefragt
                    if idelay_ctr_rdy = '1' and resync = '1' then
                        STATE_MAIN <= MAIN_STAB_CHECK_REQ;
                    end if;
                   
                    --im reset, heisst kein Fehler, aber auch nicht done
                    o_err <= '0';
                    o_done <= '0';
                when MAIN_STAB_CHECK_REQ =>
                    if stab_ack = '1' then
                        STATE_MAIN <= MAIN_WD_ALIGN_CHECK_REQ;
                        stab_pending <= '0';
                    elsif stab_err = '1' then
                        STATE_MAIN <= MAIN_ERROR;
                        stab_pending <= '0';
                    end if;
                    
                    --Anfrage stellen , dass jetzt die neue Zustandsmaschine aufgerufen wird
                   stab_pending <= '1';
 
 
                when MAIN_WD_ALIGN_CHECK_REQ =>
                
                
                    word_pending <= '1';
                    
                when MAIN_ERROR =>
                when MAIN_DONE =>
            end case;
            
        end if;
    end if;
end process FSM_MAIN;

--stability check 
--Muss mit dem Pixeltakt getaktet werden (?)
--Checkt ob der ABSTASTZEITPUNKT korrekt ist
FSM_STAB_CHK: process(pix_clk)
begin


end process FSM_STAB_CHK;


--wolrd alignment check
FSM_WORD_ALIGN: process(pix_clk)
begin

end process FSM_WORD_ALIGN;
end Behavioral;
