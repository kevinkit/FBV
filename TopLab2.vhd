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

--Auf das Taktnetz hochgeführte Komponente
signal sysclk_buf : std_logic := '0';

--200 Mhz abgeleiteter Takt
signal idelay_clk : std_logic := '0';

--Takt vom Bildsensor abgeleitet
signal iserdes_clk: std_logic := '0';

signal rst_buff : std_logic := '0';
signal locked_buff   : std_logic := '0';
signal nlocked_buff   : std_logic := '0';

signal idelay_rdy_buff : std_logic := '0';
signal nidelay_rdy_buff : std_logic := '0';


signal idelay_cnt_out : std_logic_vector (4 downto 0) := (others => '0');
signal idelay_cnt_in : std_logic_vector (4 downto 0) := (others => '0');

signal idelay_data_out : std_logic := '0';
signal idelay_data_in : std_logic := '0';
signal idelay_i_data : std_logic := '0';

signal idelay_ld : std_logic := '0';

begin
Aufgabe1i: block
    begin
  
    --Überführen in ein globales Taknetz
    IBUF_inst : IBUF
    generic map (
      IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD => "DEFAULT")
    port map (
      O => sysclk_buf,     -- Buffer output
      I => sysclk      -- Buffer input (connect directly to top-level port)
    );
    
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
end block Aufgabe1i;

Aufgabe1ii: block
begin
   IBUFDS_CLK : IBUFDS
   generic map (
      DIFF_TERM => FALSE, -- Differential Termination 
      IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
      IOSTANDARD => "DEFAULT")
   port map (
      O => idelay_clk,  -- Buffer output
      I => dclk_n,  -- Diff_p buffer input (connect directly to top-level port)
      IB => dclk_n -- Diff_n buffer input (connect directly to top-level port)
   );  
end block Aufgabe1ii;

Aufgabe2i: block
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
end block Aufgabe2i; 

Aufgabe2ii: block
begin

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
      CE => '0',                   -- 1-bit input: Active high enable increment/decrement input -> muss nicht getan werden (?)
      CINVCTRL => '0',       -- 1-bit input: Dynamic clock inversion input
      CNTVALUEIN => idelay_cnt_in,   -- 5-bit input: Counter value input
      DATAIN => idelay_i_data,           -- 1-bit input: Internal delay data input
      IDATAIN => idelay_data_in,         -- 1-bit input: Data input from the I/O
      INC => '0',                 -- 1-bit input: Increment / Decrement tap delay input
      LD => '0',                   -- 1-bit input: Load IDELAY_VALUE input
      LDPIPEEN => idelay_ld,              -- 1-bit input: Enable PIPELINE register to load data input
      REGRST => nidelay_rdy_buff    -- 1-bit input: Active-high reset tap-delay input //einer sendet ein "READY" also muss für ein RESET negiert werden 
   );


end block Aufgabe2ii;

end Behavioral;
