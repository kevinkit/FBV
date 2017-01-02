----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.12.2016 17:09:27
-- Design Name: 
-- Module Name: Top3 - Behavioral
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
  addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
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


--zwei register um die erste zeile solange zwischen zu speichern bis sie benötigt wird 
signal reg1 : std_logic_vector(i_video'left downto 0) := (others => '0');
signal reg2 : std_logic_vector(i_video'left downto 0) := (others => '0');

--Fifo 2
signal wr_en_fifo2 : std_logic := '0';
signal rd_en_fifo2 : std_logic := '0';
signal data_fifo2  : std_logic_vector(i_video'left downto 0) := (others => '0');


signal lval_buffer : std_logic := '0';
--
signal fifo1_full : std_logic := '0';

signal edge_detected   : std_logic_vector(7 downto 0)   := (others => '0');
signal sqrt_addr       : std_logic_vector(15 downto 0) := (others => '0');

signal i_video_d1 : std_logic_vector(i_video'left downto 0) := (others => '0');
signal i_video_d2 : std_logic_vector(i_video'left downto 0) := (others => '0');
signal i_video_d3 : std_logic_vector(i_video'left downto 0) := (others => '0');

signal fifo1_d : std_logic_vector(i'video_left downto 0) := (others => '0');
signal fifo2_d : std_logic_vector(i'video_left downto 0) := (others => '0');

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
    end if;

end if;
end process EDGE_DETECTION;

DELAY : process(clk)
begin
if rising_edge(clk) then
    --Es müssen die lval und framevalids verzögert werden - eigentlich um 2 Takte ? 
    
    
    --Pro Zeile 1 mal
    i_video_d1 <= i_video; 
    i_video_d2 <= i_video_d1;
    i_video_d3 <= i_video_d3;
    
    fifo1_d <= data_fifo1;
    fifo2_d <= data_fifo2;
    
end if;
end process DELAY;


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
