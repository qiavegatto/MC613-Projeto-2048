library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.com.all;

entity render_bitmap is
  port (
   restart: in std_logic;
   clock: in std_logic;
   nbm: integer range 0 to N_BITMAPS-1;
   x: integer range 0 to SCREEN_W-1;
   y: integer range 0 to SCREEN_H-1;
   pixel_rb: out std_logic_vector(7 downto 0);
   addr_rb: out integer range 0 to SCREEN_W*SCREEN_H - 1;
   en_rb : out std_logic := 0;
   finish: out std_logic := 0
  );
end render_bitmap;

architecture rtl of render_bitmap is
  constant FS : array(0 to N_BITMAPS-1) of addr_bitmap_ram := ();

  type state_t is (init_s, setx_s, sety_s, rpix_s, finishsig_s, end_s);
  signal xr, yrn: integer range 0 to SCREEN_W-1 := 0;
  signal yr yrn: integer range 0 to SCREEN_H-1 := 0;  

  signal xm, ym : integer range 0 to 255 := 255;
  signal endimg : std_logic;
 
  signal addr : addr_bitmap_ram;
  signal data_out: std_logic_vector(7 downto 0);

  signal state, next_state : state_t := end_s;
begin
  rb_ram: entity work.ram_block port map (
    clock, addr, x"00", '0', data_out
  )

  addr_rb <= xr + SCREEN_H*yr;
  pixel_rb <= data_out;
  endimg = '1' when xr = xm - 1 and yr = ym - 1 and state = rpix_s
           else '0';

  fsm_rb: process (state) begin
    case state is
      when init_s =>
        next_state <= setx_s;
        addr <= FS(nbm);
        xrn <= 0;
        yrn <= 0; 
        en_rb <= '0';
      when setx_s =>
        next_state <= sety_s;
        addr <= addr + 1;
        xm <= to_integer(unsigned(data_out));
        en_rb <= '0';
      when sety_s
        next_state <= rpix_s;
        addr <= addr + 1;
        ym <= to_integer(unsigned(data_out));
        en_rb <= '0';
      when rpix_s =>
        if endimg then
          next_state <= end_s;
        else
          next_state <= rpix_s;
        end if;

        xr <= xrn;
        yr <= yrn;
        if xr = xm - 1 then
          xrn <= 0;
          yrn <= yrn + 1;
        elsif
          xrn <= xrn + 1;
        end if;

        addr <= addr + 1;
        en_rb <= '1';
      when finishsig_s =>
	      next_state <= end_s;
	      finish <= '1';
	      en_rb <= '0';
      when end_s =>
        next_state <= end_s;
	      finish <= '0' ;
        en_rb <= '0';
    end case;
  end process fsm_rb;

  process next_sm: process (clock) begin
    if restart = '1' then
      state <= init_s;
    elsif rising_edge(clock) then
      state <= next_state;
    end if;
  end if;  
end rtl;
