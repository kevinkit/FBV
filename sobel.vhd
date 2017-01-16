

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Top3 is
    Port ( i_bin_thresh : in STD_LOGIC_VECTOR (7 downto 0);
           i_video : in STD_LOGIC_VECTOR (7 downto 0);
           clk : in STD_LOGIC;
           i_bin_en : in STD_LOGIC;
           i_fval : in STD_LOGIC;
           i_lval : in STD_LOGIC;
           rst : in STD_LOGIC;
           o_video : out STD_LOGIC_VECTOR (7 downto 0);
           o_fval : out STD_LOGIC;
           o_lval : out STD_LOGIC);
end Top3;

architecture Behavioral of Top3 is


component fifo_generator_0 IS
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END component fifo_generator_0;

component blk_mem_gen_0 IS
  PORT (
    clka : IN STD_LOGIC;
  ena : IN STD_LOGIC;
  addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
  douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END component blk_mem_gen_0;

signal rst_buff : std_logic := '0';
signal rst_sync : std_logic := '0';

--Fifo 1
signal wr_en_fifo1 : std_logic := '0';
signal rd_en_fifo1 : std_logic := '0';
signal rd_en_fifo1_buf  : std_logic := '0';
signal data_fifo1  : std_logic_vector(i_video'left downto 0) := (others => '0');




--Fifo 2
signal wr_en_fifo2 : std_logic := '0';
signal rd_en_fifo2 : std_logic := '0';
signal data_fifo2  : std_logic_vector(i_video'left downto 0) := (others => '0');


signal lval_buffer : std_logic := '0';
--
signal fifo1_full : std_logic := '0';

signal edge_detected   : std_logic_vector(7 downto 0)   := (others => '0');
signal sqrt_addr       : std_logic_vector(10 downto 0) := (others => '0');

signal i_video_d1 : std_logic_vector(i_video'left downto 0) := (others => '0');
signal i_video_d2 : std_logic_vector(i_video'left downto 0) := (others => '0');
signal i_video_d3 : std_logic_vector(i_video'left downto 0) := (others => '0');

signal fifo1_d : std_logic_vector(i_video'left downto 0) := (others => '0');
signal fifo2_d : std_logic_vector(i_video'left downto 0) := (others => '0');

signal reg1 : std_logic_vector(i_video'left downto 0) := (others => '0');
signal reg2 : std_logic_vector(i_video'left downto 0) := (others => '0');

signal dx : std_logic_vector(i_video'left downto 0) := (others => '0');
signal dx_s : std_logic_vector((i_video'left*2) +1 downto 0) := (others => '0');
signal dy : std_logic_vector(i_video'left downto 0) := (others => '0');
signal dy_s : std_logic_vector((i_video'left*2) +1 downto 0) := (others => '0');

signal sum : std_logic_vector((i_video'left*2) + 2 downto 0) := (others => '0');
signal sum_c : std_logic_vector((i_video'left*2) + 1 downto 0) := (others => '0');

signal fval_buf : std_logic := '0';

signal fval_shift_reg : std_logic_vector(8 downto 0) := (others => '0');
signal lval_shift_reg : std_logic_vector(8 downto 0) := (others => '0');


begin

--in den ersten FIFO soll immer die aktuelle Line rein 
wr_en_fifo1 <= i_lval; 



--Um Metastabilitäten zu vermeiden
SINGLE_SYNCHRONIZER: process(clk)
begin
if rising_edge(clk) then
    rst_buff <= rst;
    rst_sync <= rst_buff;
end if;
end  process SINGLE_SYNCHRONIZER;



--Prozess um das Line Valid für den zweiten FIFO zu buffern
--der Line Valid darf erst an den zweiten Line Buffer übergeben werden
--wenn eine komplette line auch im FIFO drin steht
EDGE_DETECTION : process(clk)
begin
if rising_edge(clk) then
    --Frame nicht mehr valide oder Reset --> sobald frame nicht mehr valide auch keine Line mehr da ! 
    if rst_sync = '1' or i_fval = '0' then
        lval_buffer <= '0';
        fifo1_full <= '0';
    end if;

    --einmal verzögern, so dass bei der ersten Linie eben noch nicht etwas
    --in das zweite Line FIFO geschrieben wird
    if i_lval = '1' then 
        lval_buffer <= '1';
    end if;
    
    --Kantendetektor auf fallende Flanke
    if i_lval = '0' and lval_buffer = '1' then
           fifo1_full <= '1';
           fval_buf <= '1';
   end if;

end if;
end process EDGE_DETECTION;

DELAY : process(clk)
begin
if rising_edge(clk) then
    --Es müssen die lval und framevalids verzögert werden - eigentlich um 9 Takte ? 
    
    
    i_video_d1 <= i_video; 
    i_video_d2 <= i_video_d1;
    
    i_video_d3 <= i_video_d2;
    
    
       
  --  fifo1_d <= data_fifo1;
    fifo2_d <= data_fifo2;
    
    
    --pixel delay
    reg1 <= data_fifo1;
    reg2 <= reg1;
    
    
    
    
      fval_shift_reg <= fval_shift_reg(fval_shift_reg'left - 1 downto 0) & i_fval;
      lval_shift_reg <= lval_shift_reg(lval_shift_reg'left - 1 downto 0) & i_lval;
    
    
      o_fval <= fval_shift_reg(fval_shift_reg'left);
      o_lval <= lval_shift_reg(lval_shift_reg'left);
    
    
end if;
end process DELAY;

PREWITT_PROC: process(clk) 
begin
if rising_edge(clk) then
    
    --Erstes "minus" --> Problem: Was ist wenn der Minuend größer ist als der subtrahend
    --es muss nur dafür gesorgt werden dass kein Overflow / Underflow geschieht -
    --in x Richtung ableiten ! (Dx)
    --https://en.wikipedia.org/wiki/Prewitt_operator#Formulation
   if reg2 > data_fifo1 then
        dx <= std_logic_vector(unsigned(reg2) - unsigned(data_fifo1)); 
    else
        dx <= std_logic_vector(unsigned(data_fifo1) - unsigned(reg2));
    end if;
    
    --Quadrat bilden (in x richtung)
    dx_s <= std_logic_vector(unsigned(dx) * unsigned (dx)) ;
    
    --in y Ricthung ableiten (Dy)
  --  if i_video_d1 > fifo2_d then
  --      dy <= std_logic_vector(unsigned(i_video_d1) - unsigned(fifo2_d)); 
  --  else
  --      dy <= std_logic_vector(unsigned(fifo2_d) - unsigned(i_video_d1));
  --  end if;
    
    
    if i_video_d3 > data_fifo2 then
        dy <= std_logic_vector(unsigned(i_video_d3) - unsigned(data_fifo2)); 
    else
        dy <= std_logic_vector(unsigned(data_fifo2) - unsigned(i_video_d3));
    end if;
    
    
    dy_s <= std_logic_vector(unsigned(dy) * unsigned(dy));
   
    
    sum <= std_logic_vector(unsigned('0' & dx_s) + unsigned('0' & dy_s));
    
    if sum(16) = '1' then
        sum_c <= (others => '1');
    else
        sum_c <= sum(15 downto 0);
    end if;
    
    --Was passiert wenn 10 downto 0 ? -- Ameisenkampf (gleichverteiltes Rauschen!) 
    sqrt_addr <= sum_c(15 downto 5);
 --   sqrt_addr(0) <= sum_c(0);
end if;
end process PREWITT_PROC;


BINARYISE_PROC: process(clk)
begin
if rising_edge(clk) then
    if i_bin_en = '1' then
        if edge_detected >= i_bin_thresh then
            o_video <= (others => '1');
        else
            o_video <= (others => '0');
        end if; 
    else
        o_video <= edge_detected; --kommt von SQRT LUT
     --   o_video <= i_video;
    end if;
    
end if;
end process BINARYISE_PROC;

--Read Enable, wenn fifo = full
rd_en_fifo1 <= i_lval when fifo1_full = '1' else '0';


--Die FIFOS wurde über den IP-Catalog eingefügt
--Dort kann man bestimmen wie groß sie sein soll 
--Dabei wurde eine Tiefe von 2048 und eine Width von 8 Bit angegeben
LINE_FIFO_INST1 : fifo_generator_0
PORT MAP(
    clk => clk,
    srst => rst_sync,
    din => i_video,
    wr_en => wr_en_fifo1,
    rd_en => rd_en_fifo1,
    dout => data_fifo1,
    full => open
);

LINE_FIFO_INST2 : fifo_generator_0
PORT MAP(
    clk => clk,
    srst => rst_sync,
    din => data_fifo1,
    wr_en => wr_en_fifo1,
    rd_en => rd_en_fifo1,
    dout => data_fifo2,
    full => open
);


SQRT_LUT: blk_mem_gen_0
PORT MAP(
   clka => clk,
   ena => '1',
   addra => sqrt_addr,
   douta => edge_detected
);



end Behavioral;
