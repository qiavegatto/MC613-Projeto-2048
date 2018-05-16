library ieee;
use ieee.std_logic_1164.all;

entity proj is
 port (
  CLOCK_50: in std_logic;
  PS2_DAT: inout std_logic;
  PS2_CLK: inout std_logic;
  VGA_R, VGA_G, VGA_B : out std_logic_vector(7 downto 0);
  VGA_HS, VGA_VS : out std_logic;
  VGA_BLANK_N, VGA_SYBC_N : out std_logic;
  VGA_CLK : out std_logic
 );
end proj;

use work.com.all;

architecture rtl of proj is
  signal partialpos : partialpos_t := (
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0
  );
  signal control_partialpos : partialpos_t;

  signal moving : moving_t := (
    void, void, void, void,
    void, void, void, void,
    void, void, void, void,
    void, void, void, void
   );
  signal control_moving : moving_t;

  signal board : board_t := (
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0
  );
  signal control_board : board_t;

  signal ireg_reset : std_logic := '0';
  signal reset_key : std_logic := '0';

  signal lfsr_en : std_logic := '0';
  signal rand_out : std_logic_vector(15 downto 0);

  signal render_restart : std_logic := '0';

  constant CYCLES_COUNT : integer := 1250000;
  signal EN_40HZ : std_logic := '0';
  signal count : integer range 0 to CYCLES_COUNT - 1;
begin
  inputreg: entity work.input_reg port map (
    PS2_DAT, PS2_CLK, ireg_reset, CLOCK_50, reset_key
  );
  rand: entity work.lfsr port map (CLOCK_50, lfsr_en, rand_out);
  regconds: entity work.reg_conditions port map (CLOCK_50, reset_key);

  -- read/writes partialpos, moving, board
  partialpos <= control_partialpos;
  moving <= control_moving;
  board <= control_board;
  control: entity work.control_sm port map (CLOCK_50);

  -- VGA signals, partialpos, board
  render: entity work.render port map (CLOCK_50);

  clock_divider_count: process (CLOCK_50)
  begin
    if rising_edge(CLOCK_50) then
      if count = CYCLES_COUNT - 1 then
        count <= 0;
      else
        count <= count + 1;
      end if;
    end if;
  end process clock_divider_count;

  clock_divider: process (count)
  begin
    if count = CYCLES_COUNT - 1 then
      EN_40HZ <= '1';
    else
      EN_40HZ <= '0';
    end if;
  end process clock_divider;
end rtl;


