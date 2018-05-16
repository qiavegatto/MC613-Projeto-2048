library ieee;
use ieee.std_logic_1164.all;

use work.com.all;

entity reg_conditions
  port (
    clock, reset: in std_logic;
    initgame_en: in std_logic;
    initgame: out std_logic; initgame_in: in std_logic;
    endgame_en: in std_logic;
    endgame: out std_logic; endgame_in: in std_logic;
    won_en: in std_logic;
    won: out std_logic; won_in: in std_logic;
    score_en: in std_logic;
    score: out score_t; score_in: in score_t;
  );
end reg_conditions;

architecture rtl of reg_conditions
begin
  if reset = '1' then
    initgame <= '0';
    endgame <= '0';
    score <= 0;
  elsif rising_edge(clock) then
    if initgame_en then
      initgame <= initgame_in;
    end if;
    if endgame_en then
      endgame <= endgame_in;
    end if;
    if won_en then
      won <= won_in;
    end if;
    if score_en then
      score <= score_in;
    end if;
  end if;
end rtl;
