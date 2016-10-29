-- _                   ____     ____    _____      __ 
--| |          /\     |  _ \   / __ \  |  __ \    /_ |
--| |         /  \    | |_) | | |  | | | |__) |    | |
--| |        / /\ \   |  _ <  | |  | | |  _  /     | |
--| |____   / ____ \  | |_) | | |__| | | | \ \     | |
--|______| /_/    \_\ |____/   \____/  |_|  \_\    |_|
                                                   
-- 
library ieee;
use ieee.std_logic_1164.all;

entity tb_top is
end tb_top;

architecture tb of tb_top is

    component top
        port (i_dig_gain   : in std_logic_vector (7 downto 0);
              i_dig_offset : in std_logic_vector (7 downto 0);
              i_video      : in std_logic_vector (7 downto 0);
              i_clk        : in std_logic;
              i_fval       : in std_logic;
              i_lval       : in std_logic;
              o_video      : out std_logic_vector (7 downto 0);
              o_fval       : out std_logic;
              o_lval       : out std_logic);
    end component;

    signal i_dig_gain   : std_logic_vector (7 downto 0);
    signal i_dig_offset : std_logic_vector (7 downto 0);
    signal i_video      : std_logic_vector (7 downto 0);
    signal i_clk        : std_logic;
    signal i_fval       : std_logic;
    signal i_lval       : std_logic;
    signal o_video      : std_logic_vector (7 downto 0);
    signal o_fval       : std_logic;
    signal o_lval       : std_logic;

    constant TbPeriod : time := 10 ns; -- EDIT put right period here
    signal TbClock : std_logic := '0';

begin

    dut : top
    port map (i_dig_gain   => i_dig_gain,
              i_dig_offset => i_dig_offset,
              i_video      => i_video,
              i_clk        => i_clk,
              i_fval       => i_fval,
              i_lval       => i_lval,
              o_video      => o_video,
              o_fval       => o_fval,
              o_lval       => o_lval);

    TbClock <= not TbClock after TbPeriod/2;

    --  EDIT: Replace YOURCLOCKSIGNAL below by the name of your clock
    i_clk <= TbClock;

    stimuli : process
    begin
       -- if rising_edge(TbClock) then
            i_fval <= '1';
            i_lval <= '1';
        
            i_video <= "00000001";
            i_dig_gain <= "00100000";
            i_dig_offset <= "00000001";
        
            
            
            
            
            
            wait for 2*TbPeriod;
            
            i_video <= "01110000";
            i_dig_gain <= "00100010";
            i_dig_offset <= "00001111";
                    
            wait;
            
       -- end if;        
       -- wait;
    end process;
    --wait;
end tb;

configuration cfg_tb_top of tb_top is
    for tb
    end for;
end cfg_tb_top;
