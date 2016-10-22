library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;


package fbv_pkg is
    subtype Positive is Integer range 1 to Integer'high;
    function DIG_GAIN (iData, Factor:std_logic_vector; Decimals, res_width: Positiv ) return std_logic_vector;
    procedure DIG_OFFSET (signal iDATA, Offset : in  std_logic_vector;
                          signal Result        : out std_logic_vector);
end fbv_pgk;


package body fbv_pkg is
    function DIG_GAIN (iData, Factor:std_logic_vector; Decimals, res_width: POSITIVE ) return std_logic_vector is
    begin    
        --Function must be declared here
        
    end function DIG_GAIN;
    
    
    
    --Result = iData + Offset
    --Problem: 1) Offset negativ -> Wie kann ich unterscheiden ob er negativ ist? -> Was muss ich anders machen wenn negativ?
    --         2) Wenn Offset + iData größer ist als das maximum -> maximum Wert anehmen
    --            -> Wenn -Ofsset + iData kleiner 0 sind muss der Wert auf 0 gesetzt werden
    procedure DIG_OFFSET (signal iDATA, Offset : in  std_logic_vector;
                          signal Result        : out std_logic_vector) is
                          variable ONES_OUT : std_logic_vector(iData'range +1) := (others=>'1'); --mit 0 initialisieren (wenn Wert dann negativ, kann dieser gleich verwendet werden(?)
                          variable Offset_resized : std_logic_vector(iData'range) := (others=>'1');
                          variable INVERTER    : std_logic_vector(iData'range +1) := (others=>'1');
                          variable temp_result : std_logic_vector(iData'range +1) := (others=>'0');
    begin
           --Vorzeichenbit übertragen
           Offset_resized'high <= Offset'high;
           
           --Nachdem das Vorzeichen übertragen würde, die Daten an die "richtige" Stelle übertragen
           Offset_resized(Offset'range) <= Offset; --Ob das funktioniert?
           
           
           --Checken ob iData und Offset jeweils um die Häflte größer sind als ONES_OUT --> wenn ja muss die Additon nicht durchgeführt werden
           --stattedessen einfach den maximal wert ausgeben!
           
           
           
           temp_result <= iData + signed(Offset_resized);
           
           if temp_result < signed(0) then
                Result <= ZERO_OUT xor INVERTER;
           end if;
           --Result <= signed_idat + 
           --Procedure must be declared here   
           --Check if negative
           case Offset'high is
                when 1 =>
                    --Result = not(ZERO_OUT);
                when 0 =>
            end case;
           
           
           
    end DIG_OFFSET;       
end fbv_pkg;
