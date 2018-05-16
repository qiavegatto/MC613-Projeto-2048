library ieee;
use ieee.std_logic_1164;

use work.com.all;

entity control_sm is
  port (
    reset, clock: in std_logic;
    lfsr_en: out std_logic;
    lfsr_out: in std_logic_vector(15 downto 0);
    initgame_en: out std_logic;
    initgame: in std_logic; initgame_in: out std_logic;
    endgame_en: out std_logic;
    endgame: in std_logic; endgame_in: out std_logic;
    score_en: out std_logic;
    score: in score_t; score_in: out score_t;
    input: in direction; input_reset: out std_logic;
    control_partialpos: out partialpos_t;
    control_moving: out moving_t;
    control_board: out board_t;
    render_finish: in std_logic;
    render_restart: out std_logic
  );
end control_sm;

architecture rtl of control_sm is
  type control_s is (init, continue, genblock, setblock, render_restart,
                     render, resetinp, getinput, progmove, endanimate, move);
  
  signal state, next_state: control_s := init;

  signal end_gen, end_animation : std_logic;

  signal sig_partialpos: partialpos_t := (
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0
  );

  signal sig_moving: moving_t := (
    void, void, void, void,
    void, void, void, void,
    void, void, void, void,
    void, void, void, void
  );
 
  signal sig_board: board_t := (
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0
  );

  signal movable, m_l, m_u, m_d, m_r: std_logic_vector(15 downto 0);

  signal lfsr_p1, lfsr_p2: integer range 0 to 15;
  signal lfsr_copy: std_logic_vector(15 downto 0);
begin
  lfsr_p1 <= to_integer(unsigned(lfsr_out(7 downto 4)));
  lfsr_p2 <= to_integer(unsigned(lfsr_out(3 downto 0)));

  control_partialpos <= sig_partialpos;
  control_moving <= sig_moving;
  control_board <= sig_board;

  with input select movable <=
    '0' when void,
    m_l when left,
    m_u when up,
    m_d when down,
    m_r when right;

  gmovables: for i in 0 to 3 generate
    m_l(4*i) <= '0';
    m_l(4*i+1) <= '1' when sig_board(4*i) = sig_board(4*i+1) else
                  '1' when sig_board(4*i) = 0 else
                  '0';
    m_l(4*i+2) <= '1' when m_l(4*i+1) = '1' else
                  '1' when sig_board(4*i+1) = sig_board(4*i+2) else
                  '1' when sig_board(4*i+1) = 0 else
                  '0'; 
    m_l(4*i+3) <= '1' when m_l(4*i+2) = '1' else
                 '1' when sig_board(4*i+2) = sig_board(4*i+3) else
                 '1' when sig_board(4*i+2) = 0 else
                 '0';

    m_r(4*i+3) <= '0';
    m_r(4*i+2) <= '1' when sig_board(4*i+3) = sig_board(4*i+2) else
                  '1' when sig_board(4*i+3) = 0 else
                  '0';
    m_r(4*i+1) <= '1' when m_r(4*i+2) = '1' else
                  '1' when sig_board(4*i+2) = sig_board(4*i+1) else
                  '1' when sig_board(4*i+2) = 0 else
                  '0'; 
    m_r(4*i) <= '1' when m_r(4*i+1) = '1' else
                 '1' when sig_board(4*i+1) = sig_board(4*i) else
                 '1' when sig_board(4*i+1) = 0 else
                 '0';

    m_u(i) <= '0';
    m_u(4+i) <= '1' when sig_board(i) = sig_board(4+i) else
                  '1' when sig_board(i) = 0 else
                  '0';
    m_u(8+i) <= '1' when m_u(4+i) = '1' else
                  '1' when sig_board(4+i) = sig_board(8+i) else
                  '1' when sig_board(4+i) = 0 else
                  '0'; 
    m_u(12+i) <= '1' when m_u(8+i) = '1' else
                 '1' when sig_board(8+i) = sig_board(12+i) else
                 '1' when sig_board(8+i) = 0 else
                 '0';
 
    m_d(12+i) <= '0';
    m_d(8+i) <= '1' when sig_board(12+i) = sig_board(8+i) else
                  '1' when sig_board(12+i) = 0 else
                  '0';
    m_d(4+i) <= '1' when m_d(8+i) = '1' else
                  '1' when sig_board(8+i) = sig_board(4+i) else
                  '1' when sig_board(8+i) = 0 else
                  '0'; 
    m_d(i) <= '1' when m_d(4+i) = '1' else
                 '1' when sig_board(4+i) = sig_board(i) else
                 '1' when sig_board(4+i) = 0 else
                 '0';
  end generate;

  endgen <=
      '1' when initgame = '1' and board(lfsr_p2) = '0' and 
                                      board(lfsr_p1) = '0' else
      '1' when initgame = '0' and board(lfsr_p1) = '0' else
      '0';

  p_sm: process (state, input, render_finish) begin
    case state is
    when init =>
      next_state <= continue;

      sig_partialpos <= (0, 0, 0, 0, 0, 0, 0, 0,
                             0, 0, 0, 0, 0, 0, 0, 0);
      sig_moving <= (void, void, void, void, void, void, void, void,
                         void, void, void, void, void, void, void, void);
      sig_board <= (0, 0, 0, 0, 0, 0, 0, 0,
                        0, 0, 0, 0, 0, 0, 0, 0);

      lfsr_en <= '0';
      initgame_in <= '1';
      initgame_en <= '1';
      endgame_in <= '0';
      endgame_en <= '1';
      score_in <= x"0000";
      score_en <= '1';

      end_animation <= '1';
    when continue =>
      if endgame = '1' then
        next_state <= continue;
      elsif end_animation = '1' then
        next_state <= genblock;
      else
        next_state <= progmove;
      end if;

      lfsr_en <= '1';
      initgame_in <= '0';
      initgame_en <= '0';
      endgame_in <= '0';
      endgame_en <= '0';
      score_in <= x"0000";
      score_en <= '0';
    when genblock =>
      if score_en = '1' and endgen = '1' then
        lfsr_copy <= lfsr_out;
        next_state <= setblock;
      else
        next_state <= genblock;
      end if;
      
      lfsr_en <= '1';
      initgame_in <= '0';
      initgame_en <= '0';
      endgame_in <= '0';
      endgame_en <= '0';
      score_in <= x"0000";
      score_en <= '0';
    when setblock =>
      next_state <= render_restart;

      if init_game = '1' then
        sig_board(
          to_integer(unsigned(lfsr_out(3 downto 0)))
        ) <= '1';
        sig_board(
          to_integer(unsigned(lfsr_out(3 downto 0)))
        ) <= '2' when lfsr(5 downto 4) = "11" else '1';
      else 
        sig_board(
          to_integer(unsigned(lfsr_out(3 downto 0))
        ) <= '2' when lfsr(5 downto 4) = "11" else '1';
      end if;

      lfsr_en <= '0';
      initgame_in <= '0';
      initgame_en <= '0';
      endgame_in <= '0';
      endgame_en <= '0';
      score_in <= x"0000";
      score_en <= '0';  
    when render_restart =>
      next_state <= render;

      lfsr_en <= '0';
      initgame_in <= '0';
      initgame_en <= '0';
      endgame_in <= '0';
      endgame_en <= '0';
      score_in <= x"0000";
      score_en <= '0';

      render_restart <= '1';
   when render =>
      if render_finish = '1' and end_animation = '1' then
        next_state <= resetinp;
      elsif render_finish = '1' then
        next_state <= progmove;
      else
        next_state <= render;
      end if;
      
      lfsr_en <= '0';
      initgame_in <= '0';
      initgame_en <= '0';
      endgame_in <= '0';
      endgame_en <= '0';
      score_in <= x"0000";
      score_en <= '0';

      render_restart <= '0';
    when resetinp =>
      next_state <= getinput;
     
      lfsr_en <= '0';
      initgame_in <= '0';
      initgame_en <= '0';
      endgame_in <= '0';
      endgame_en <= '0';
      score_in <= x"0000";
      score_en <= '0';

      input_reset <= '1';
    when getinput =>
      if input = void then
        next_state <= getinput;
      elsif movable /= x"00" then
        next_state <= progmove; 
      end if;

      lfsr_en <= '0';
      initgame_in <= '0';
      initgame_en <= '0';
      endgame_in <= '0';
      endgame_en <= '0';
      score_in <= x"0000";
      score_en <= '0';

      input_reset <= '0';
    when progmove =>
      next_state <= endanimate;

      sig_moving <= movable;
      for i in 0 to 15 loop
        sig_partialpos(i) <=
          sig_partialpos(i) + 1 when movable(i) = '1' else
          sig_partialpos(i);
      end loop;

      lfsr_en <= '0';
      initgame_in <= '0';
      initgame_en <= '0';
      endgame_in <= '0';
      endgame_en <= '0';
      score_in <= x"0000";
      score_en <= '0';

      end_animation <= '0';
    when endanimate =>
      next_state <= move;

      end_animation <= '1' when sig_partialpos = (0,0,0,0,0,0,0,0,
                                                      0,0,0,0,0,0,0,0) else
                       '0';

      lfsr_en <= '0';
      initgame_in <= '0';
      initgame_en <= '0';
      endgame_in <= '0';
      endgame_en <= '0';
      score_in <= x"0000";
      score_en <= '0';
   when move =>
      next_state <= continue;

      for i in 0 to 3 loop
         case input is
          when left =>
            if sig_partialpos(1) = '0' and sig_moving(i) = '0'
            control(3*i) <= control(3*i+1);
            control(3*i+1) <= control(3*i+2);
            control(3*i+2) <= control(3*i+3);
            control(3*i+3) <= '0'; 
          when right =>
          when up =>
          when down =>
        end case;
      end loop;

      lfsr_en <= '0';
      initgame_in <= '0';
      initgame_en <= '0';
      endgame_in <= '0';
      endgame_en <= '0';
      score_in <= x"0000";
      score_en <= '0'; 
  end case;
  end process p_sm;

  p_next_state: process (clock) begin
    if reset = '1' then
      state <= init;
    elsif rising_edge(clock) then
      state <= next_state;
    end if;
  end process p_next_state;
end rtl;
