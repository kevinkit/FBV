-- _                   ____     ____    _____      __ 
--| |          /\     |  _ \   / __ \  |  __ \    /_ |
--| |         /  \    | |_) | | |  | | | |__) |    | |
--| |        / /\ \   |  _ <  | |  | | |  _  /     | |
--| |____   / ____ \  | |_) | | |__| | | | \ \     | |
--|______| /_/    \_\ |____/   \____/  |_|  \_\    |_|
                                                   
-- 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_unsigned.all;

package fbv_pkg is
    --subtype Positive is Integer range 1 to Integer'high;
    function DIG_GAIN (iData, Factor:std_logic_vector; Decimals, res_width: POSITIVE ) return std_logic_vector;
    procedure DIG_OFFSET (signal iDATA, Offset : in  std_logic_vector;
                          signal Result        : out std_logic_vector);
end fbv_pkg;


package body fbv_pkg is
    --returns iData * Factor



function DIG_GAIN (iData, Factor:std_logic_vector; Decimals, res_width: POSITIVE ) return std_logic_vector is
    variable zero_dec : std_logic_vector (Decimals-1 downto 0) := (others => '0');
  --  variable Resultat_Gleitkomma : std_logic_Vector(iData'left + Decimals + Factor'left +1 downto 0)  := (others=>'0');
    
    
    variable Resultat_Gleitkomma : std_logic_Vector(iData'left + Factor'left +1 downto 0)  := (others=>'0');
    variable max : std_logic_Vector (res_width downto 0) := (others => '1');
begin    
    --Resultat_Gleitkomma := (iData & zero_dec) *Factor;
    Resultat_Gleitkomma := iData*Factor;
    if Resultat_Gleitkomma(Resultat_Gleitkomma'left downto (res_width + Decimals)) > 0 then
        --Überlauf!
        return max;
    else
        return Resultat_Gleitkomma(res_width + Decimals downto Decimals);
    end if;

end DIG_GAIN;
    
    
    
    --Result = iData + Offset
    --Problem: 1) Offset negativ -> Wie kann ich unterscheiden ob er negativ ist? -> Was muss ich anders machen wenn negativ?
    --         2) Wenn Offset + iData größer ist als das maximum -> maximum Wert anehmen
    --            -> Wenn -Ofsset + iData kleiner 0 sind muss der Wert auf 0 gesetzt werden
    procedure DIG_OFFSET (signal iDATA, Offset : in  std_logic_vector;
                          signal Result        : out std_logic_vector) is           
                          variable Offset_resized : std_logic_vector((iData'left+1) downto iData'right) := (others=>'0');
                          variable temp_result : std_logic_vector((iData'left +1) downto iData'right) := (others=>'0');
                          variable f_result : std_logic_vector((iData'left +1) downto iData'right) := (others =>'1');
    begin

           --negativer Offset          
           if Offset(Offset'left) = '1' then
            Offset_resized := (others=>'1');
            Offset_resized((Offset'left) downto 0) := '1' & Offset(Offset'left -1 downto 0);          
            f_result := (others=>'0');
           else
            --Positiver Offset
            Offset_resized(Offset'left downto 0) := '0' & Offset(Offset'left-1 downto 0);
            
            
            --01111.... <- maximaler POSITIVER Wert
            f_result := '0' & f_result(f_result'left - 1 downto f_result'right);
           end if;

           --Berechnung
           temp_result := ('0' & iData) + Offset_resized; 
           
           if temp_result(temp_result'left) ='0' then --00 bedeutet, dass es weder eine Bereichsunter oder überschreitung gab
                Result <= temp_result;
           else
                Result <= f_result;
           end if;

    end DIG_OFFSET;       
end fbv_pkg;
