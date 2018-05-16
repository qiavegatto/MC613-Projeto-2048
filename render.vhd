library ieee;
use ieee.std_logic_1164.all;
use ieee.std_numeric.all;
use ieee.std_logic_unsigned.all;

use work.com.all;

entity render is
  port (
    clock, EN_40HZ: in std_logic;
    render_restart: in std_logic;
    render_finish: out std_logic;
    VGA_R, VGA_G, VGA_B: in std_logic_vector(7 downto 0);
    VGA_HS, VGA_VS: out std_logic;
    VGA_BLANK_N, VGA_SYNC_N: out std_logic;
    VGA_CLK: out std_logic;
    initgame, endgame: in std_logic
  );
end render;

architecture rtl of render is
  type render_s is (init_s, prog_clearblock, prog_block, prog_resetmsg,
                    prog_scoredigit, prog_win, prog_lose, restart_rb_s,
                    oper_rb, fsig_s, end_s);
  signal state, next_state, next_prog: render_s := end_s;

  signal sync, blank: std_logic;

  signal rb_x: integer range 0 to SCREEN_W-1;
  signal rb_y: integer range 0 to SCREEN_H-1;
  signal pixel_rb: std_logic_vector(7 downto 0);
  signal en_rb, rb_restart, rb_finish: std_logic := 0;
  signal addr_rb: integer range 0 to SCREEN_W*SCREEN_H-1;

  signal count: integer range 0 to 15 := 0;
  signal c_resetn: std_logic := '0';
  signal c_inc: std_logic := '0';
begin
  vgac: entity work.vgacon port map (
    clk50M       => clock,
    rstn         => '1',
    red          => VGA_R,
    green        => VGA_G,
    blue         => VGA_B,
    hsync        => VGA_HS,
    vsync        => VGA_VS,
    write_clk    => CLOCK_50,
    write_enable => en_rb,
    write_addr   => addr_rb,
    data_in      => pixel_rb,
    vga_clk      => VGA_CLK,
    sync         => sync,
    blank        => blank
  );
  VGA_SYNC_N <= NOT sync;
  VGA_BLANK_N <= NOT blank;

  rb: entity work.render_bitmap port map (rb_restart, clock, rb_nbm,
                    rb_x, rb_y, pixel_rb, addr_rb, en_rb, rb_finish);

  pcounter: process (state)
  begin
    if c_resetn = '0' then
      count <= 0;
    elsif c_inc = '1' then
      if count = 15 then
        count <= 0;
      else
        count <= count + 1;
      end if;
    end if;
  end process pcounter;

  render_sm: process (state, EN_40HZ, finish_rb)
    var blocki: integer range 0 to 15 := 0;
  begin
    case state is
      when init_s =>
        if EN_40HZ = '1' then
          next_state <= prog_block;
        else
          next_state <= init_s;
        end if;

        c_resetn <= '0';
        c_inc <= '0';
      when prog_clearblock =>
        next_state <= restart_rb_s;
        next_prog <= prog_block when count = 15 else prog_clearblock;

        rb_nbm <= 0;
        rb_x <= 120 + 60*(count rem 4);
        rb_y <= 120 + 60*(count / 4);

        c_resetn <= '1';
        c_inc <= '1';
      when prog_block =>
        next_state <= restart_rb_s;
        next_prog <= prog_scoredigit when count = 15 else prog_block;

        rb_nbm <= board(i);

        with moving select rb_x <=
          120 + 60*(count mod 4) - 15 * partial_pos(i) when left;
          120 + 60*(count mod 4) + 15 * partial_pos(i) when right;
          120 + 60*(count mod 4) when others;

        with moving select rb_y <=
          120 + 60*(count / 4) - 15 * partial_pos(i) when up;
          120 + 60*(count / 4) + 15 * partial_pos(i) when down;
          120 + 60*(count / 4) when others;

        c_resetn <= '1';
        c_inc <= '1';
      when prog_scoredigit =>
        next_state <= restart_rb_s;
        next_prog <= prog_resetmsg when count = 3 else prog_scoredigit;

        rb_nbm <= to_integer(score(4*count+3 downto 4*count) + x"A");
        rb_x <= 200+count*26;
        rb_y <= 365;

        c_resetn <= '0' if count = 3 else '1';
        c_inc <= '1';
      when prog_resetmsg =>
        next_state <= restart_rb_s;

        if endgame = '1' and won = '1' then
          next_prog <= prog_win;
        elsif endgame = '1' then
          next_prog <= prog_lose;
        else
          next_prog <= fsig_s; -- exceptional
        end if;

        rb_nbm <= ;
        rb_x <= 320;
        rb_y <= 365;

        c_resetn <= '1';
        c_inc <= '0';
     when prog_win =>
        next_state <= restart_rb_s;
        next_prog <= fsig_s; -- exceptional

        rb_nbm <= ;
        rb_x <= 180;
        rb_y <= 5;

        c_resetn <= '1';
        c_inc <= '0';
     when prog_lose =>
        next_state <= restart_rb_s;
        next_prog <= fsig_s; -- exceptional

        rb_nbm <= ;
        rb_x <= 180;
        rb_y <= 5;

        c_resetn <= '1';
        c_inc <= '0';
    when restart_rb_s =>
        next_state <= oper_rb;
        rb_restart <= '1';
      when oper_rb =>
        if finish_rb = '1' then
          next_state <= next_prog;
        else
          next_state <= oper_rb;
        end if;
        
        rb_restart <= '0';
      when fsig_s =>
        next_state <= end_s;

        rb_restart <= '0';

        render_finish <= '1';
 
        c_resetn <= '1';
        c_inc <= '0';
     when end_s =>
        next_state <= end_s;

        rb_restart <= '0';

        render_finish <= '0';
 
        c_resetn <= '1';
        c_inc <= '0';
    end case;
  end process render_sm; 

  next_sm: process (clock, reset) begin
    if render_restart = '1' then
      state <= init;
    elsif rising_edge(clock)
      state <= next_state;
    end if;
  end process next_sm;
end rtl;
