-- Quartus Prime VHDL Template
-- Single port RAM with single read/write Addressess 

library ieee;
use ieee.std_logic_1164.all;

entity ram_block is
  generic 
  (
    DATA_WIDTH : natural := 8;
    Address_WIDTH : natural := 17
  );

  port 
  (
    Clock : in std_logic;
    Address : in natural range 0 to 2**Address_WIDTH - 1;
    Data  : in std_logic_vector((DATA_WIDTH-1) downto 0);
    Q   : out std_logic_vector((DATA_WIDTH -1) downto 0)
  );

end entity;

architecture rtl of ram_block is

  -- Build a 2-D array type for the RAM
  subtype word_t is std_logic_vector((DATA_WIDTH-1) downto 0);
  type memory_t is array(2**Address_WIDTH-1 downto 0) of word_t;

  -- Declare the RAM signal.  
  signal ram : memory_t;

  -- Register to hold the Addressess 
  signal Address_reg : natural range 0 to 2**Address_WIDTH-1;

  attribute ram_init_file : string;
  attribute ram_init_file of ram : signal is "bmap_mem.mif";
begin

  p_rb: process(Clock, Data, Address)
  begin
    if(rising_edge(Clock)) then 
      Address_reg <= Address;
    end if;
  end process p_rb;

  Q <= ram(Address_reg);

end rtl;
