----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.10.2016 23:19:05
-- Design Name: 
-- _                   ____     ____    _____      __ 
--| |          /\     |  _ \   / __ \  |  __ \    /_ |
--| |         /  \    | |_) | | |  | | | |__) |    | |
--| |        / /\ \   |  _ <  | |  | | |  _  /     | |
--| |____   / ____ \  | |_) | | |__| | | | \ \     | |
--|______| /_/    \_\ |____/   \____/  |_|  \_\    |_|
                                                   
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
use work.fbv_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;



entity top is
    Port ( i_dig_gain : in STD_LOGIC_VECTOR (7 downto 0);
           i_dig_offset : in STD_LOGIC_VECTOR (7 downto 0);
           i_video : in STD_LOGIC_VECTOR (7 downto 0);
           i_clk : in STD_LOGIC;
           i_fval : in STD_LOGIC;
           i_lval : in STD_LOGIC;
           o_video : out STD_LOGIC_VECTOR (7 downto 0);
           o_fval : out STD_LOGIC;
           o_lval : out STD_LOGIC);
end top;

architecture Behavioral of top is

signal VALID_PIC : std_logic;
signal some_buf : std_logic_vector(i_video'left + 1 downto 0) := (others=>'0');
signal offset_buf : std_logic_vector (i_video'left + 1 downto 0) := (others => '0');

signal semaphor : std_logic := '1';

constant DEC: POSITIVE  := 4;
constant res_width: POSITIVE := i_video'left +1;
constant zero_int : std_logic_vector (i_dig_offset'left downto DEC) := (others=>'0');

begin
    process (i_clk) 
    --variable offset_buf : std_logic_vector (i_video'left + 1 downto 0);
    variable gain_buf : std_logic_vector(i_video'left + 1 downto 0) := (others=>'0');
    --variable res_width: POSITIVE := gain_buf'left;
    begin 
        if rising_edge(i_clk) then
             if (i_lval and i_fval) = '1' then
                 if semaphor = '1' then             
                    DIG_OFFSET(i_video,i_dig_offset,offset_buf);
                    semaphor <= '0';
                 else
                  if offset_buf(offset_buf'left) = '1' and i_dig_gain(i_dig_gain'left downto DEC) = zero_int then
                    o_video <= offset_buf(o_video'left downto 0);
                  else
                    gain_buf := DIG_GAIN(offset_buf,i_dig_gain,DEC, res_width);
                    some_buf <= gain_buf;
                    o_video <= gain_buf(o_video'left downto 0);
                  end if;
                  semaphor <= '1';
                end if;
             else
                  o_video <= some_buf(o_video'left downto 0);
             end if;
             o_fval <= i_fval;
             o_lval <= i_lval;
         end if;
    end process;
end Behavioral;
