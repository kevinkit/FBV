library ieee;
use ieee.std_logic_1164.all;
use STD.textio.all;
use IEEE.numeric_std.all;
entity tb_Top3 is
end tb_Top3;

architecture tb of tb_Top3 is

    component Top3
        port (i_bin_thresh : in std_logic_vector (7 downto 0);
              i_video      : in std_logic_vector (7 downto 0);
              clk          : in std_logic;
              i_bin_en     : in std_logic;
              i_fval       : in std_logic;
              i_lval       : in std_logic;
              rst          : in std_logic;
              o_video      : out std_logic_vector (7 downto 0);
              o_fval       : out std_logic;
              o_lval       : out std_logic);
    end component;

    signal i_bin_thresh : std_logic_vector (7 downto 0);
    signal i_video      : std_logic_vector (7 downto 0);
    signal clk          : std_logic;
    signal i_bin_en     : std_logic;
    signal i_fval       : std_logic;
    signal i_lval       : std_logic;
    signal rst          : std_logic;
    signal o_video      : std_logic_vector (7 downto 0);
    signal o_fval       : std_logic;
    signal o_lval       : std_logic;

    constant TbPeriod : time := 5 ns; -- EDIT put right period here
    signal TbClock : std_logic := '0';

begin

    dut : Top3
    port map (i_bin_thresh => i_bin_thresh,
              i_video      => i_video,
              clk          => clk,
              i_bin_en     => i_bin_en,
              i_fval       => i_fval,
              i_lval       => i_lval,
              rst          => rst,
              o_video      => o_video,
              o_fval       => o_fval,
              o_lval       => o_lval);

    TbClock <= not TbClock after TbPeriod/2;

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process

    file infile: text open read_mode is "C:\Users\Kevin\OneDrive\Master2\FBV\Labore\lenac.txt";
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
          read(rdLine,Rows)   ;
          write(wrLine, Rows);
          write(wrLine, ' ' );
 
 
 
 
          read(rdline,Lines);     
          write(wrLine, Lines);
          write(wrLine, ' ' );
        
        
               
        
          read(rdLine,Channels);
          write(wrLine,Channels);
          write(wrLine, ' ' );
          writeline(outfile,wrLine);
          
          report("Width, Height, Channels: " & integer'image(Lines) & " " & integer'image(Rows) & " " & integer'image(Channels));
          
         -- i_dig_offset <= "01100111"; --1
          i_fval <= '0';
          i_lval <= '0';
          rst <= '1';
          i_bin_en <= '1';
          i_bin_en <= '0';
          i_bin_thresh <= (others => '0');
          while not (endfile(infile)) loop
          --     for I in 0 to Rows loop
                   readline(infile, rdline);
                   report("----------NEW LINE------");
                   for J in 0 to Rows loop
                       rst <= '0';
                   
                       wait until TbClock'event and TbClock='1';
   
                       read(rdline, rd_int);
   
                       report("Wert: " & integer'image(rd_int));
                       i_video <= std_logic_vector(to_unsigned(rd_int,i_video'length));
                      -- i_lval <= '0';
                       --i_fval <= '0';
                       
                       --if J > 0 then
                       write(wrLine, to_integer(unsigned(o_video))); 
                        write(wrLine, ' ');
                       --end if;
      
  --                     i_lval <= '1';
  --                     i_fval <= '1';  
                                              
                       --Setz es früh genug um
  --                     if I = Lines-1  and J = Rows -1 then
 --                          i_fval <= '0';
  --                         i_lval <= '0';
  --                     elsif J = Rows and I /= Lines -1 then
  --                         i_lval <= '0';
  --                         wait for 200 ns;
  --                         i_lval <= '1';
  --                     end if;   
    
    

                  end loop;
                      
                  report("Wert: " & integer'image(Rows));
                  writeline(outfile,wrLine);
                       
               end loop;
               
              --Sorg dafür das es auch "unten" bleibt
              i_fval <= '0';
              i_lval <= '0';
   
    --     end loop;
         file_close(infile);
         file_close(outfile);
        wait;
    end process;

end tb;

configuration cfg_tb_Top3 of tb_Top3 is
    for tb
    end for;
end cfg_tb_Top3;
