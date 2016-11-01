-- _                   ____     ____    _____      __ 
--| |          /\     |  _ \   / __ \  |  __ \    /_ |
--| |         /  \    | |_) | | |  | | | |__) |    | |
--| |        / /\ \   |  _ <  | |  | | |  _  /     | |
--| |____   / ____ \  | |_) | | |__| | | | \ \     | |
--|______| /_/    \_\ |____/   \____/  |_|  \_\    |_|
                                                   
-- 
library ieee;
use ieee.std_logic_1164.all;
use STD.textio.all;
use IEEE.numeric_std.all;

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
    signal TbClock : std_logic := '1';

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
     file infile: text open read_mode is "C:\Users\Kevin\OneDrive\Master2\FBV\Labore\lena_sw.txt";
     file outfile: text open write_mode is "myfile.txt";
     
     
     variable Lines: integer;
     variable Rows: integer;
     variable Channels: integer;
     
     variable rd_int: integer;
     variable rd_vect: std_logic_vector(7 downto 0);
     variable rdline: LINE;
     variable wrLine: LINE;
    begin
       readline(infile, rdline);
       read(rdline,Lines);     
       write(wrLine, Lines);
       write(wrLine, ' ' );
       read(rdLine,Rows);
       write(wrLine, Rows);
       write(wrLine, ' ' );
       read(rdLine,Channels);
       write(wrLine,Channels);
       write(wrLine, ' ' );
       writeline(outfile,wrLine);
       
       report("Width, Height, Channels: " & integer'image(Lines) & " " & integer'image(Rows) & " " & integer'image(Channels));
       
       i_dig_gain <= "00001000"; --2.5
       i_dig_offset <= "00000100"; --4
      -- i_dig_offset <= "01100111"; --1
       i_fval <= '0';
       i_lval <= '0';
       while not (endfile(infile)) loop
            for I in 0 to Lines-1 loop
                readline(infile, rdline);
                report("----------NEW LINE------");
                for J in 0 to Rows loop

                
                    wait until TbClock'event and TbClock='1';

                    read(rdline, rd_int);

                    report("Wert: " & integer'image(rd_int));
                    i_video <= std_logic_vector(to_unsigned(rd_int,i_video'length));
                   -- i_lval <= '0';
                    --i_fval <= '0';
                    
                    if J > 0 then
                        write(wrLine, to_integer(unsigned(o_video)));
                        write(wrLine, ' ');
                    end if;
                    
                    i_lval <= '1';
                    i_fval <= '1';  
                    
                    
                    --Setz es früh genug um
                    
                    if I = Lines-1  and J = Rows -1 then
                        i_fval <= '0';
                        i_lval <= '0';
                    elsif J = Rows and I /= Lines -1 then
                        i_lval <= '0';
                        wait for 200 ns;
                        i_lval <= '1';
                    end if;   
               end loop;
                   
               writeline(outfile,wrLine);
                    
            end loop;
            
           --Sorg dafür das es auch "unten" bleibt
           i_fval <= '0';
           i_lval <= '0';

      end loop;
      file_close(infile);
      file_close(outfile);
      wait;
      

    end process;

end tb;

configuration cfg_tb_top of tb_top is
    for tb
    end for;
end cfg_tb_top;
