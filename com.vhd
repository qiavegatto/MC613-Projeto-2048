library ieee;
use ieee.std_logic_1164.all;
use ieee.std_numeric.all;

package com is
  type direction is (void, up, down, left, right);
  type addr_bitmap_ram is natural 0 to 2**17 -1;

  constant SCREEN_W : integer := 640;
  constant SCREEN_H : integer := 480;

  -- 0 to F, empty, 2 to 2048, win, lose, restart
  constant N_BITMAPS : integer := 31;

  type score_t is unsigned(15 downto 0);

  type partialpos_t is array(15 downto 0) of integer range 0 to 3;
  type moving_t is array(15 downto 0) of direction;
  type board_t is array(15 downto 0) of integer 0 to 11;
end package;
