library ieee;
use ieee.std_logic_1164.all;

entity lfsr is
  port (
   clk: in std_logic;
   en: in std_logic;
   data_out: out std_logic_vector(15 downto 0)
  );
end lfsr;

architecture rtl of lfsr is
  signal data: std_logic_vector(15 downto 0);
begin
  data_out <= data;

  lfsr_p: process (clk) begin
    if rising_edge(clk) then
      if (enable = '1') then
        data(15) <= data(0);
        data(14) <= data(15);
        data(13) <= data(12) xor data(0);
        data(12) <= data(13) xor data(0);
        data(11) <= data(12);
        data(10) <= data(11) xor data(0);
        gd: for i in 9 downto 0 generate
         data(i) <= data(i+1);
        end generate;
      end if;
    end if;
  end process lfsr_p;
end rtl;
