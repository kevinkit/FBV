----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.11.2016 01:38:01
-- Design Name: 
-- Module Name: TOPlab2 - Behavioral
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



Library UNISIM;
use UNISIM.vcomponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TOPlab2 is
    Port ( dclk_n : in STD_LOGIC;
           dclk_p : in STD_LOGIC;
           i_DATA_n : in STD_LOGIC;
           i_DATA_p : in STD_LOGIC;
           resync : in STD_LOGIC;
           rst : in STD_LOGIC;
           sysclk : in STD_LOGIC;
           o_data : out STD_LOGIC_VECTOR (7 downto 0);
           o_done : out STD_LOGIC;
           o_err : out STD_LOGIC;
           o_locked : out STD_LOGIC);
end TOPlab2;
		
architecture Behavioral of TOPlab2 is

component FSM is
    Port ( sysclk : in STD_LOGIC;
       pix_clk : in STD_LOGIC;
       rst : in STD_LOGIC;
       resync : in STD_LOGIC;
       
       --interne FPGA Signale die von außen rein kommen
       idelay_ctrl_rdy : in STD_LOGIC;
       idelay2_tab_preset : out STD_LOGIC_VECTOR(4 downto 0);
       idelay2_cnt_out : in std_logic_vector(4 downto 0);
       idelay2_ld : out STD_LOGIC; --das muss von der STAB CHECK FSM dann ausgegeben werden!
       iserdese2_bitslip : out STD_LOGIC;
       data : in STD_LOGIC_VECTOR(7 downto 0);
       ce : out std_logic;
       o_done : out STD_LOGIC;
       o_err : out STD_LOGIC;
       
       o_locked : out STD_LOGIC);
end component FSM;






component clk_wiz_0
port
 (-- Clock in ports
  clk_in1           : in     std_logic;
  -- Clock out ports
  clk_out1          : out    std_logic;
  -- Status and control signals
  reset             : in     std_logic;
  locked            : out    std_logic
 );
end component;

--Auf das Taktnetz hochgeführte Komponente
signal sysclk_buf : std_logic := '0';

signal sens_clk : std_logic := '0';
signal sens_clk_clkNet : std_logic := '0';
signal nsens_clk_clkNet: std_logic := '1';

signal PIXEL_CLK : std_logic := '0';


--Takt vom Bildsensor abgeleitet
signal iserdes_clk: std_logic := '0';

signal rst_buff : std_logic := '0';
signal locked_buff   : std_logic := '0';
signal nlocked_buff   : std_logic := '1';

--Idelay signals
signal idelay_rdy_buff : std_logic := '0';
signal nidelay_rdy_buff : std_logic := '1';
signal idelay_cnt_out : std_logic_vector (4 downto 0) := (others => '0');
signal idelay_cnt_in : std_logic_vector (4 downto 0) := (others => '0');
signal idelay_data_out : std_logic := '0';
signal idelay_data_in : std_logic := '0';
signal idelay_i_data : std_logic := '0';
signal idelay_ld : std_logic := '0';
signal idelay_clk : std_logic := '0';

--Iserdes
signal o_iserdes : std_logic_vector(7 downto 0) := (others => '0'); 
signal i_bitslip : std_logic := '0';


--rst
signal rst_buf : std_logic := '0';



--FSM
signal ce_buf : std_logic := '0';








begin
reset_sync_process: process(sysclk_buf)
begin
if rising_edge(sysclk_buf) then
    rst_buf <= rst;
end if;

end process reset_sync_process; 




--von Differential zu Normal
D2N: block
begin
    --Fuer Sensor CLK
    IBUFDS_CLK : IBUFDS
    generic map (
       DIFF_TERM => FALSE, -- Differential Termination 
       IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
       IOSTANDARD => "DEFAULT")
    port map (
       O => sens_clk,  -- Buffer output
       I => dclk_p,  -- Diff_p buffer input (connect directly to top-level port)
       IB => dclk_n -- Diff_n buffer input (connect directly to top-level port)
    );  
    
    --Fuer Daten
    IBUFDS_DATA : IBUFDS
    generic map (
       DIFF_TERM => FALSE, -- Differential Termination 
       IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
       IOSTANDARD => "DEFAULT")
    port map (
       O => idelay_data_in ,  -- Buffer output
       I => i_DATA_p,  -- Diff_p buffer input (connect directly to top-level port)
       IB =>  i_DATA_n-- Diff_n buffer input (connect directly to top-level port)
    );  
end block D2N;

CLK: block
begin
    --Überführen des SysClks in ein globales Taknetz
    IBUF_inst : IBUFG
    port map (
      O => sysclk_buf,     
      I => sysclk      
    );

    --Sensor Clock in Globales Taktnet 
    BUFIO_SENS_CLK_inst : BUFIO
    port map (
     I => sens_clk,        -- 1-bit input: Clock input (connect to an IBUF or BUFMR).  
     O => sens_clk_clkNet  -- 1-bit output: Clock output (connect to I/O clock loads).
    );    
   
    --Takteiler für spätere Verwendung 
    BUFR_inst : BUFR
    generic map (
      BUFR_DIVIDE => "BYPASS",   -- Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
      SIM_DEVICE => "7SERIES"  -- Must be set to "7SERIES" 
    )
    port map (
      O => PIXEL_CLK,     -- 1-bit output: Clock output port
      CE => '1',   -- 1-bit input: Active high, clock enable (Divided modes only)
      CLR => rst_buf, -- 1-bit input: Active high, asynchronous clear (Divided modes only)
      I => sens_clk_clkNet      -- 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
    );
end block CLK;

nsens_clk_clkNet <= not sens_clk_clkNet;
CLK_WIZ: block
    begin
    
    --200 Mhz Takt ableiten
    your_instance_name : clk_wiz_0 --wie kann ich dme hier einen besseren Namne geben? ACK fragen!
       port map ( 
        -- Clock in ports
       clk_in1 =>  sysclk_buf,
      -- Clock out ports  
       clk_out1 => idelay_clk,
      -- Status and control signals                
       reset => rst_buff,
       locked => locked_buff            
     );
    
     nlocked_buff <= not locked_buff;
end block CLK_WIZ;



IDelay: block
begin
    --IDELAY_CTRL
    IDELAYCTRL_inst : IDELAYCTRL
    port map (
        RDY => idelay_rdy_buff,       -- 1-bit output: Ready output
        REFCLK => idelay_clk, -- 1-bit input: Reference clock input
        RST => nlocked_buff        -- 1-bit input: Active high reset input --> Wenn die 200 MHZ "richtig" sind aus dem RST raus (siehe aufgabe 2i)
    );
    
    --Rausschreiben
    o_locked <= idelay_rdy_buff;
    nidelay_rdy_buff <= not idelay_rdy_buff;
    
    
     IDELAYE2_inst : IDELAYE2
    generic map (
       CINVCTRL_SEL => "FALSE",          -- Enable dynamic clock inversion (FALSE, TRUE)
       DELAY_SRC => "IDATAIN",           -- Delay input (IDATAIN, DATAIN)
       HIGH_PERFORMANCE_MODE => "TRUE", -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
       IDELAY_TYPE => "VAR_LOAD",           -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
       IDELAY_VALUE => 0,                -- Input delay tap setting (0-31)
       PIPE_SEL => "FALSE",              -- Select pipelined mode, FALSE, TRUE
       REFCLK_FREQUENCY => 200.0,        -- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
       SIGNAL_PATTERN => "DATA"          -- DATA, CLOCK input signal
    )
    port map (
       CNTVALUEOUT => idelay_cnt_out, -- 5-bit output: Counter value output x
       DATAOUT => idelay_data_out,     -- 1-bit output: Delayed data output x
       C => sysclk_buf,               -- 1-bit input: Clock input x
       CE => ce_buf,                   -- 1-bit input: Active high enable increment/decrement input -> muss nicht getan werden (?)
       CINVCTRL => '0',       -- 1-bit input: Dynamic clock inversion input
       CNTVALUEIN => idelay_cnt_in,   -- 5-bit input: Counter value input
       DATAIN => idelay_i_data,           -- 1-bit input: Internal delay data input
       IDATAIN => idelay_data_in,         -- 1-bit input: Data input from the I/O
       INC => ce_buf,                 -- 1-bit input: Increment / Decrement tap delay input
       LD => idelay_ld,                   -- 1-bit input: Load IDELAY_VALUE input
       LDPIPEEN => '0',              -- 1-bit input: Enable PIPELINE register to load data input
       REGRST => nidelay_rdy_buff    -- 1-bit input: Active-high reset tap-delay input //einer sendet ein "READY" also muss für ein RESET negiert werden 
    );    
    

end block IDelay; 




ISERDES: block
begin
   ISERDESE2_inst : ISERDESE2
   generic map (
      DATA_RATE => "DDR",           -- DDR, SDR
      DATA_WIDTH => 8,              -- Parallel data width (2-8,10,14) //o_data ist 8 lang
      DYN_CLKDIV_INV_EN => "FALSE", -- Enable DYNCLKDIVINVSEL inversion (FALSE, TRUE)
      DYN_CLK_INV_EN => "FALSE",    -- Enable DYNCLKINVSEL inversion (FALSE, TRUE)
      -- INIT_Q1 - INIT_Q4: Initial value on the Q outputs (0/1)
      INIT_Q1 => '0',
      INIT_Q2 => '0',
      INIT_Q3 => '0',
      INIT_Q4 => '0',
      INTERFACE_TYPE => "NETWORKING",   -- MEMORY, MEMORY_DDR3, MEMORY_QDR, NETWORKING, OVERSAMPLE
      IOBDELAY => "IFD",           -- NONE, BOTH, IBUF, IFD
      NUM_CE => 2,                  -- Number of clock enables (1,2)
      OFB_USED => "FALSE",          -- Select OFB path (FALSE, TRUE)
      SERDES_MODE => "MASTER",      -- MASTER, SLAVE
      -- SRVAL_Q1 - SRVAL_Q4: Q output values when SR is used (0/1)
      SRVAL_Q1 => '0',
      SRVAL_Q2 => '0',
      SRVAL_Q3 => '0',
      SRVAL_Q4 => '0' 
   )
   port map (
      O => open,                       -- 1-bit output: Combinatorial output
      -- Q1 - Q8: 1-bit (each) output: Registered data outputs
      Q1 => o_iserdes(0),
      Q2 => o_iserdes(1),
      Q3 => o_iserdes(2),
      Q4 => o_iserdes(3),
      Q5 => o_iserdes(4),
      Q6 => o_iserdes(5),
      Q7 => o_iserdes(6),
      Q8 => o_iserdes(7),
   --unnütz? --> auf open  oder auskommentieren?
   -- SHIFTOUT1, SHIFTOUT2: 1-bit (each) output: Data width expansion output ports
   --   SHIFTOUT1 => SHIFTOUT1,
   --   SHIFTOUT2 => SHIFTOUT2,
      BITSLIP => i_bitslip,           -- 1-bit input: The BITSLIP pin performs a Bitslip operation synchronous to
                                    -- CLKDIV when asserted (active High). Subsequently, the data seen on the
                                    -- Q1 to Q8 output ports will shift, as in a barrel-shifter operation, one
                                    -- position every time Bitslip is invoked (DDR operation is different from
                                    -- SDR).

      -- CE1, CE2: 1-bit (each) input: Data register clock enable inputs
      CE1 => '1', --brauche beiden Datenregister(?)
      CE2 => '1',
      CLKDIVP => '0',           -- 1-bit input: TBD --keine clkdivision
      
      
      -- Clocks: 1-bit (each) input: ISERDESE2 clock input ports
      CLK => sens_clk_clkNet,                   -- 1-bit input: High-speed clock
      CLKB => nsens_clk_clkNet,                 -- 1-bit input: High-speed secondary clock
      CLKDIV => PIXEL_CLK,             -- 1-bit input: Divided clock --von den Pixeln her geteilt
      OCLK => '0',                 -- 1-bit input: High speed output clock used when INTERFACE_TYPE="MEMORY"  ist aber DDR
      -- Dynamic Clock Inversions: 1-bit (each) input: Dynamic clock inversion pins to switch clock polarity
      DYNCLKDIVSEL => '0', -- 1-bit input: Dynamic CLKDIV inversion
      DYNCLKSEL => '0',       -- 1-bit input: Dynamic CLK/CLKB inversion
      -- Input Data: 1-bit (each) input: ISERDESE2 data input ports
      D => '0',                       -- 1-bit input: Data input
      DDLY => idelay_data_out,                 -- 1-bit input: Serial data from IDELAYE2
      OFB => '0',                   -- 1-bit input: Data feedback from OSERDESE2
      OCLKB => '0',               -- 1-bit input: High speed negative edge output clock
      RST => nidelay_rdy_buff,                   -- 1-bit input: Active high asynchronous reset
      -- SHIFTIN1, SHIFTIN2: 1-bit (each) input: Data width expansion input ports
      SHIFTIN1 => '0', -- geraten
      SHIFTIN2 => '0' 
   );
   
   o_data <= o_iserdes; 

   -- End of ISERDESE2_inst instantiation
    
        FSM_MODULE_INST:FSM
   Port map( 
              sysclk              =>  sysclk_buf,
              pix_clk              =>  PIXEL_CLK,          
              rst                  =>  rst_buf,
              resync               =>  resync,
              
              -- internal fpg logic signals
              idelay_ctrl_rdy      =>  idelay_rdy_buff,
              idelay2_tab_preset  =>  idelay_cnt_in,
              idelay2_ld          =>  idelay_ld,
              iserdese2_bitslip    =>  i_bitslip,
              data                 =>  o_iserdes,
              idelay2_cnt_out => idelay_cnt_out,
              ce => ce_buf,
              -- external signals
              o_done               =>  o_done,
              o_err                =>  o_err,
              
             o_locked             =>  o_locked
              );


end block ISERDES;

end Behavioral;
