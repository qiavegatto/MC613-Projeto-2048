library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.com.all;

entity input_reg is
 port(
    ps2_data, ps2_clk : inout std_logic;
    reset, clock: in std_logic;
    input: out direction;
    reset_key: out std_logic
  );
end input_reg;

architecture rtl of input_reg is
  component kbdex_ctrl is
    generic(
      clkfreq : integer
    );
    port (
      ps2_data : inout std_logic;
      ps2_clk : inout std_logic;
      clk :	in std_logic;
      en : in std_logic;
      resetn : in std_logic;
      lights : in std_logic_vector(2 downto 0);
      key_on : out std_logic_vector(2 downto 0);
      key_code : out std_logic_vector(47 downto 0)
    );
  end component;
  
  signal key_on : std_logic_vector(2 downto 0);
  signal key_code : std_logic_vector(47 downto 0);
  signal inp : direction;
  signal inpv : direction;
  signal rel : std_logic := '1';

  signal reset_k0, reset_k1 : std_logic;
begin

  kbdex_ctrl_inst : kbdex_ctrl
    generic map (
      clkfreq => 50000
    )
    port map (
      ps2_data => ps2_data,
      ps2_clk => ps2_clk,
      clk => clock,
      en => '1',
      resetn => '1',
      lights => "000",
      key_on => key_on,
      key_code => key_code
    );

  with key_code(15 downto 0) select inp <=
    up when x"e075",
    down when x"e072",
    left when x"e06b",
    right when x"e074",
    void when others;
  
  reset_k0 <= '1' when key_code(7 downto 0) = x"2d" else
	      '1' when key_code(15 downto 8) = x"2d" else
	      '0';
  
  p_resetk: process (reset_k0, clock)
  begin
    if rising_edge(clock) then
      reset_k1 <= reset_k0;
      reset_key <= reset_k0 and not reset_k1;
    end if;
  end process p_resetk; 

  preg: process (clock, reset, key_code) begin
    if reset = '1' then
	    inpv <= void;
	    rel <= '0';
    elsif rising_edge(clock) then
      if inp = void then
        rel <= '1';
      elsif inpv = void and rel = '1' then
	      inpv <= inp;
      end if;
    end if;
  end process preg;

  input <= inpv(0);
end rtl;
