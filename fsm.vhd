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
                    MAIN_RST --nicht rückgesetzt
                    MAIN_STAB_CHK_REQ  --bester abtastatpunkt (von außen angefragt)
                    MAIN_WD_ALIGN_CHECK_REQ --word alginment  (von außen angefragt)
                    MAIN_ERROR
                    MAIN_DONE);
signal STATE_MAIN : FSM_MAIN := MAIN_RST; --Initialwert
                    

begin


FSM_MAIN: process(sysclk)
begin
if rising_edge(sysclk)
    if resync = '1' then
    
    
    
end if;

end Behavioral;
