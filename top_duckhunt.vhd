library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 
 
entity top_duckhunt is 
    Port ( 
        CLK100MHZ : in STD_LOGIC; 
        BTNC      : in STD_LOGIC; 
        PS2_CLK   : in STD_LOGIC; 
        PS2_DATA  : in STD_LOGIC; 
        LED       : out STD_LOGIC_VECTOR(15 downto 0); 
        SEG       : out STD_LOGIC_VECTOR(6 downto 0); 
        AN        : out STD_LOGIC_VECTOR(3 downto 0); 
        VGA_R     : out STD_LOGIC_VECTOR(3 downto 0); 
        VGA_G     : out STD_LOGIC_VECTOR(3 downto 0); 
        VGA_B     : out STD_LOGIC_VECTOR(3 downto 0); 
        VGA_HS    : out STD_LOGIC; 
        VGA_VS    : out STD_LOGIC 
    ); 
end top_duckhunt; 
 
architecture Behavioral of top_duckhunt is 
    component vga_640x480 is port (clk25, rst: in std_logic; hsync, vsync, 
video_on: out std_logic; pixel_x, pixel_y: out unsigned); end component; 
    component ps2_keyboard is port (clk, rst, ps2_clk, ps2_data: in std_logic; 
btn_w, btn_a, btn_s, btn_d, btn_space, btn_esc: out std_logic); end component; 
    component seven_segment is port (clk, rst: in std_logic; score_in: in 
integer; seg: out std_logic_vector; an: out std_logic_vector); end component; 
 
    -- HAPUS SEMUA INISIALISASI (:= ...) UNTUK MENGHINDARI SYNTH ERROR 
    signal clk25, rst, video_on : std_logic; 
    signal clk_counter : unsigned(1 downto 0); 
    signal pixel_x_raw : unsigned(9 downto 0); signal pixel_y_raw : unsigned(8 
downto 0); 
    signal px, py : integer; 
     
    signal k_w, k_a, k_s, k_d, k_sp, k_esc : std_logic; 
    signal k_sp_prev, shoot_pulse, k_esc_prev, pause_pulse : std_logic; 
     
    signal cursor_x, cursor_y : integer; 
    constant CURSOR_SPEED : integer := 6; 
    signal duck_x, duck_y, duck_vx, duck_vy : integer; 
    signal duck_alive : std_logic; 
     
    type state_t is (PLAY, OVER, PAUSED);  
    signal game_state : state_t; 
     
    signal score, lives, level : integer; 
     
    signal tick_cnt : integer;  
    signal move_tick : std_logic; 
    signal anim_cnt, wing_frame, respawn_timer : integer; 
    signal lfsr : std_logic_vector(15 downto 0);  
    signal current_speed, bg_stage : integer; 
    signal rand_coord : integer; 
 
    -- Flags 
    signal is_cursor, is_duck, is_wing, is_life : std_logic; 
    signal is_sun, is_cloud, is_grass, is_grass_light, is_flower, is_stem : 
std_logic; 
    signal txt_main : std_logic; 
 
begin 
    -- 1. SYSTEM SETUP 
    process(CLK100MHZ) begin if rising_edge(CLK100MHZ) then clk_counter <= 
clk_counter + 1; end if; end process; 
    clk25 <= clk_counter(1); rst <= BTNC; 
 
    vga_inst: vga_640x480 port map (clk25, rst, VGA_HS, VGA_VS, video_on, 
pixel_x_raw, pixel_y_raw); 
    key_inst: ps2_keyboard port map (CLK100MHZ, rst, PS2_CLK, PS2_DATA, k_w, 
k_a, k_s, k_d, k_sp, k_esc); 
    seg_inst: seven_segment port map (CLK100MHZ, rst, score, SEG, AN); 
 
    px <= to_integer(pixel_x_raw); py <= to_integer(pixel_y_raw); 
 
    process(CLK100MHZ) begin if rising_edge(CLK100MHZ) then  
        k_sp_prev <= k_sp;  
        if k_sp='1' and k_sp_prev='0' then shoot_pulse <= '1'; else shoot_pulse 
<= '0'; end if; 
        k_esc_prev <= k_esc;  
        if k_esc='1' and k_esc_prev='0' then pause_pulse <= '1'; else 
pause_pulse <= '0'; end if; 
    end if; end process; 
 
    -- 2. GAME LOGIC 
    process(CLK100MHZ) 
        variable dx, dy : integer; 
    begin 
        if rising_edge(CLK100MHZ) then 
            if rst = '1' then 
                -- INITIALIZATION (RESET) 
                game_state <= PLAY; score <= 0; lives <= 3; level <= 1; 
                duck_x <= 50; duck_y <= 200; duck_alive <= '1'; duck_vx <= 2; 
duck_vy <= 1; 
                cursor_x <= 320; cursor_y <= 240;  
                lfsr <= x"ACE1"; current_speed <= 2; 
                tick_cnt <= 0; move_tick <= '0'; anim_cnt <= 0; wing_frame <= 0; 
respawn_timer <= 0; 
            else 
                lfsr <= lfsr(14 downto 0) & (lfsr(15) xor lfsr(13) xor lfsr(12) 
xor lfsr(10)); 
                 
                if pause_pulse = '1' then 
                    if game_state = PLAY then game_state <= PAUSED; 
                    elsif game_state = PAUSED then game_state <= PLAY; end if; 
                end if; 
 
                if game_state = PLAY then 
                    bg_stage <= (score / 10) mod 4;  
                     
                    -- UPDATE LEVEL TIAP 5 POINT 
                    level <= 1 + (score / 5); 
                     
                    -- UPDATE SPEED 
                    if level > 10 then current_speed <= 10; else current_speed 
<= 2 + level; end if; 
 
                    tick_cnt <= tick_cnt + 1; 
                    if tick_cnt = 1666666 then tick_cnt <= 0; move_tick <= '1'; 
anim_cnt <= anim_cnt + 1; 
                        if anim_cnt = 5 then wing_frame <= (wing_frame + 1) mod 
4; anim_cnt <= 0; end if; 
                    else move_tick <= '0'; end if; 
                end if; 
 
                if move_tick = '1' and game_state = PLAY then 
                    if k_w='1' and cursor_y > 25 then cursor_y <= cursor_y - 
CURSOR_SPEED; end if; 
                    if k_s='1' and cursor_y < 455 then cursor_y <= cursor_y + 
CURSOR_SPEED; end if; 
                    if k_a='1' and cursor_x > 25 then cursor_x <= cursor_x - 
CURSOR_SPEED; end if; 
                    if k_d='1' and cursor_x < 615 then cursor_x <= cursor_x + 
CURSOR_SPEED; end if; 
 
                    if duck_alive = '1' then 
                        duck_x <= duck_x + duck_vx; duck_y <= duck_y + duck_vy; 
                        if duck_y < 50 then duck_vy <= abs(duck_vy); elsif 
duck_y > 380 then duck_vy <= -abs(duck_vy); end if; 
                        if duck_x < -60 or duck_x > 700 then 
                            if lives > 0 then lives <= lives - 1; duck_alive <= 
'0'; else game_state <= OVER; end if; 
                        end if; 
                    else 
                        if respawn_timer < 30 then respawn_timer <= 
respawn_timer + 1; 
                        else  
                            respawn_timer <= 0; duck_alive <= '1'; 
                            rand_coord <= 50 + (to_integer(unsigned(lfsr(9 
downto 1))) mod 300); 
                            if lfsr(0) = '0' then duck_x <= -40; duck_y <= 
rand_coord; duck_vx <= current_speed; duck_vy <= 1; 
                            else duck_x <= 680; duck_y <= rand_coord; duck_vx <= 
-current_speed; duck_vy <= -1; end if; 
                        end if; 
                    end if; 
                end if; 
 
                if shoot_pulse = '1' then 
                    if game_state = PLAY and duck_alive = '1' then 
                        dx := cursor_x - (duck_x + 16); dy := cursor_y - (duck_y 
+ 16); 
                        if (dx*dx + dy*dy) < (45 * 45) then duck_alive <= '0'; 
score <= score + 1; respawn_timer <= 0; end if; 
                    elsif game_state = OVER then 
                        game_state <= PLAY; score <= 0; lives <= 3; duck_alive 
<= '0'; respawn_timer <= 20; 
                    end if; 
                end if; 
            end if; 
        end if; 
    end process; 
    LED <= std_logic_vector(to_unsigned(score, 16)); 
 
    -- ================= 3. VISUAL PROCESSING (MANUAL PIXELS) ================= 
    process(px, py, cursor_x, cursor_y, duck_x, duck_y, duck_alive, wing_frame, 
lives, game_state, level, bg_stage) 
        variable tx, ty : integer; 
        variable active_char : integer;  
        variable char_pixel : boolean; 
    begin 
        is_cursor<='0'; is_duck<='0'; is_wing<='0'; is_life<='0'; 
        is_sun<='0'; is_cloud<='0'; is_grass<='0'; is_grass_light<='0'; 
is_flower<='0'; is_stem<='0'; 
        txt_main<='0'; 
 
        -- Objects 
        if ((px>=cursor_x-25 and px<=cursor_x+25) and (py=cursor_y-25 or 
py=cursor_y+25)) or ((py>=cursor_y-25 and py<=cursor_y+25) and (px=cursor_x-25 
or px=cursor_x+25)) or ((px=cursor_x) and (py>=cursor_y-5 and py<=cursor_y+5)) 
then is_cursor <= '1'; end if; 
        if (duck_alive='1' and ((px-(duck_x+16))*(px-(duck_x+16)) + 
(py-(duck_y+16))*(py-(duck_y+16)) < 256)) then is_duck<='1'; end if; 
        if (duck_alive='1' and wing_frame>1 and (py<duck_y+10 or px<duck_x+10)) 
then is_wing<='1'; end if; 
        if (py>20 and py<40) then if ((lives>=1 and px>20 and px<40) or 
(lives>=2 and px>50 and px<70) or (lives>=3 and px>80 and px<100)) then 
is_life<='1'; end if; end if; 
 
        -- Scenery 
        if ((px-550)*(px-550) + (py-80)*(py-80) < 1600) then is_sun<='1'; end 
if; 
        if (((px-150)*(px-150) + (py-80)*(py-80) < 900) or (((px-180)*(px-180) + 
(py-80)*(py-80)) < 900) or (((px-400)*(px-400) + (py-100)*(py-100)) < 900) or 
(((px-440)*(px-440) + (py-100)*(py-100)) < 900)) then is_cloud <= '1'; end if; 
        if py > 400 then is_grass <= '1'; end if; 
        if py > 400 and ((px + py) mod 20 < 10) then is_grass_light <= '1'; end 
if; 
        if py>415 and py<435 then 
             if ((px=55 or px=155 or px=255 or px=355 or px=455) and py>425) 
then is_stem<='1'; end if; 
             if ( ((px-55)*(px-55)+(py-420)*(py-420)<20) or 
((px-155)*(px-155)+(py-420)*(py-420)<20) or 
((px-255)*(px-255)+(py-420)*(py-420)<20) or 
((px-355)*(px-355)+(py-420)*(py-420)<20) ) then is_flower<='1'; end if; 
        end if; 
 
        -- TEXT RENDERER 
        active_char := 0; tx := 0; ty := 0; 
 
        if game_state = OVER then 
            -- GAME OVER (Font Size: 20x30) 
            if py>=200 and py<=230 then 
                if px>=180 and px<=200 then active_char:=1; tx:=px-180; 
ty:=py-200; end if; -- G 
                if px>=210 and px<=230 then active_char:=2; tx:=px-210; 
ty:=py-200; end if; -- A 
                if px>=240 and px<=260 then active_char:=3; tx:=px-240; 
ty:=py-200; end if; -- M 
                if px>=270 and px<=290 then active_char:=4; tx:=px-270; 
ty:=py-200; end if; -- E 
                if px>=330 and px<=350 then active_char:=5; tx:=px-330; 
ty:=py-200; end if; -- O 
                if px>=360 and px<=380 then active_char:=6; tx:=px-360; 
ty:=py-200; end if; -- V 
                if px>=390 and px<=410 then active_char:=4; tx:=px-390; 
ty:=py-200; end if; -- E 
                if px>=420 and px<=440 then active_char:=7; tx:=px-420; 
ty:=py-200; end if; -- R 
            end if; 
             
            -- PRESS SPACE 
            if py>=300 and py<=330 then 
                if px>=200 and px<=220 then active_char:=8; tx:=px-200; 
ty:=py-300; end if; -- P 
                if px>=230 and px<=250 then active_char:=7; tx:=px-230; 
ty:=py-300; end if; -- R 
                if px>=260 and px<=280 then active_char:=4; tx:=px-260; 
ty:=py-300; end if; -- E 
                if px>=290 and px<=310 then active_char:=9; tx:=px-290; 
ty:=py-300; end if; -- S 
                if px>=320 and px<=340 then active_char:=9; tx:=px-320; 
ty:=py-300; end if; -- S 
                 
                if px>=370 and px<=390 then active_char:=9; tx:=px-370; 
ty:=py-300; end if; -- S 
                if px>=400 and px<=420 then active_char:=8; tx:=px-400; 
ty:=py-300; end if; -- P 
                if px>=430 and px<=450 then active_char:=2; tx:=px-430; 
ty:=py-300; end if; -- A 
                if px>=460 and px<=480 then active_char:=10; tx:=px-460; 
ty:=py-300; end if; -- C 
                if px>=490 and px<=510 then active_char:=4; tx:=px-490; 
ty:=py-300; end if; -- E 
            end if; 
             
        elsif game_state = PAUSED then 
            if py>=200 and py<=230 then 
                if px>=260 and px<=280 then active_char:=8; tx:=px-260; 
ty:=py-200; end if; -- P 
                if px>=290 and px<=310 then active_char:=2; tx:=px-290; 
ty:=py-200; end if; -- A 
                if px>=320 and px<=340 then active_char:=11; tx:=px-320; 
ty:=py-200; end if; -- U 
                if px>=350 and px<=370 then active_char:=9; tx:=px-350; 
ty:=py-200; end if; -- S 
                if px>=380 and px<=400 then active_char:=4; tx:=px-380; 
ty:=py-200; end if; -- E 
                if px>=410 and px<=430 then active_char:=12; tx:=px-410; 
ty:=py-200; end if; -- D 
            end if; 
        end if; 
 
        -- LEVEL DISPLAY (Kanan Bawah) 
        if py>=440 and py<=470 then 
            if px>=530 and px<=550 then active_char:=13; tx:=px-530; ty:=py-440; 
end if; -- L 
            if px>=560 and px<=580 then active_char:=6; tx:=px-560; ty:=py-440; 
end if; -- V 
            if px>=590 and px<=610 then active_char:=13; tx:=px-590; ty:=py-440; 
end if; -- L 
             
            if level >= 10 then 
                if px>=620 and px<=640 then active_char:=15; tx:=px-620; 
ty:=py-440; end if; -- 1 
                if px>=650 and px<=670 then active_char:=14; tx:=px-650; 
ty:=py-440; end if; -- 0 
            else  
                if px>=620 and px<=640 then  
                     -- Mapping Level 1-9 
                     if level=1 then active_char:=15; tx:=px-620; ty:=py-440;  
                     elsif level=2 then active_char:=16; tx:=px-620; ty:=py-440;  
                     elsif level=3 then active_char:=17; tx:=px-620; ty:=py-440;  
                     elsif level=4 then active_char:=18; tx:=px-620; ty:=py-440;  
                     elsif level=5 then active_char:=19; tx:=px-620; ty:=py-440;  
                     elsif level=6 then active_char:=20; tx:=px-620; ty:=py-440;  
                     elsif level=7 then active_char:=21; tx:=px-620; ty:=py-440;  
                     elsif level=8 then active_char:=22; tx:=px-620; ty:=py-440;  
                     elsif level=9 then active_char:=23; tx:=px-620; ty:=py-440;  
                     end if; 
                end if; 
            end if; 
        end if; 
 
        char_pixel := false; 
        if active_char > 0 then 
            case active_char is 
                when 1 => if (ty<=5 or ty>=25 or tx<=5 or (tx>=10 and ty>=15 and 
ty<=25)) then char_pixel:=true; end if; -- G 
                when 2 => if (ty<=5 or tx<=5 or tx>=15 or ty=15) then 
char_pixel:=true; end if; -- A 
                when 3 => if (tx<=5 or tx>=15 or (ty<=15 and tx>=8 and tx<=12)) 
then char_pixel:=true; end if; -- M 
                when 4 => if (tx<=5 or ty<=5 or ty>=25 or ty=15) then 
char_pixel:=true; end if; -- E 
                when 5 => if (tx<=5 or tx>=15 or ty<=5 or ty>=25) then 
char_pixel:=true; end if; -- O 
                when 6 => if ((tx<=5 and ty<=20) or (tx>=15 and ty<=20) or 
(ty>=20 and tx>=5 and tx<=15)) then char_pixel:=true; end if; -- V 
                when 7 => if (tx<=5 or ty<=5 or (tx>=15 and ty<=15) or ty=15 or 
(tx>=10 and ty>=15 and tx=ty-15+10)) then char_pixel:=true; end if; -- R 
                when 8 => if (tx<=5 or ty<=5 or (tx>=15 and ty<=15) or ty=15) 
then char_pixel:=true; end if; -- P 
                when 9 => if (ty<=5 or ty>=25 or ty=15 or (tx<=5 and ty<=15) or 
(tx>=15 and ty>=15)) then char_pixel:=true; end if; -- S 
                when 10=> if (ty<=5 or ty>=25 or tx<=5) then char_pixel:=true; 
end if; -- C 
                when 11=> if (tx<=5 or tx>=15 or ty>=25) then char_pixel:=true; 
end if; -- U 
                when 12=> if (tx<=5 or ty<=5 or ty>=25 or (tx>=15 and ty>=5 and 
ty<=25)) then char_pixel:=true; end if; -- D 
                when 13=> if (tx<=5 or ty>=25) then char_pixel:=true; end if; -- 
L 
                when 14=> if (tx<=5 or tx>=15 or ty<=5 or ty>=25) then 
char_pixel:=true; end if; -- 0 
                when 15=> if (tx>=8 and tx<=12) then char_pixel:=true; end if; -- 1 
                 
                -- Number 2-9 Logic (Added to fix Level 8->1 bug) 
                when 16=> if (ty<=5 or ty>=25 or ty=15 or (ty<15 and tx>=15) or 
(ty>15 and tx<=5)) then char_pixel:=true; end if; -- 2 
                when 17=> if (ty<=5 or ty>=25 or ty=15 or tx>=15) then 
char_pixel:=true; end if; -- 3 
                when 18=> if (tx>=15 or ty=15 or (tx<=5 and ty<15)) then 
char_pixel:=true; end if; -- 4 
                when 19=> if (ty<=5 or ty>=25 or ty=15 or (ty<15 and tx<=5) or 
(ty>15 and tx>=15)) then char_pixel:=true; end if; -- 5 
                when 20=> if (ty<=5 or ty>=25 or ty=15 or tx<=5 or (ty>15 and 
tx>=15)) then char_pixel:=true; end if; -- 6 
                when 21=> if (ty<=5 or tx>=15) then char_pixel:=true; end if; -- 
7 
                when 22=> if (tx<=5 or tx>=15 or ty<=5 or ty>=25 or ty=15) then 
char_pixel:=true; end if; -- 8 
                when 23=> if (tx<=5 or tx>=15 or ty<=5 or ty>=25 or ty=15 or 
(ty<15 and tx<=5)) then char_pixel:=true; end if; -- 9 (FIXED) 
                when others => null; 
            end case; 
        end if; 
        if char_pixel then txt_main <= '1'; end if; 
    end process; 
 
    -- COLOR MUX 
    process(video_on, game_state, is_cursor, is_duck, is_wing, is_life, is_sun, 
is_cloud, is_grass, is_grass_light, is_flower, is_stem, txt_main, py, bg_stage) 
    begin 
        if video_on = '1' then 
            if game_state = PAUSED then 
                if txt_main='1' then VGA_R<="1111"; VGA_G<="1111"; 
VGA_B<="1111"; 
                else VGA_R<="0000"; VGA_G<="0000"; VGA_B<="0010"; end if;  
            elsif game_state = OVER then 
                if txt_main='1' then VGA_R<="1111"; VGA_G<="1111"; 
VGA_B<="1111";  
                else VGA_R<="1000"; VGA_G<="0000"; VGA_B<="0000"; end if; 
            else 
                if txt_main='1' then VGA_R<="1111"; VGA_G<="1111"; 
VGA_B<="1111"; -- Level Text 
                elsif is_cursor='1' then VGA_R<="1111"; VGA_G<="1111"; 
VGA_B<="0000"; 
                elsif is_duck='1' then 
                    if is_wing='1' then VGA_R<="1111"; VGA_G<="1111"; 
VGA_B<="1111"; else VGA_R<="0000"; VGA_G<="1111"; VGA_B<="0000"; end if; 
                elsif is_life='1' then VGA_R<="1111"; VGA_G<="0000"; 
VGA_B<="0000"; 
                elsif is_flower='1' then VGA_R<="1111"; VGA_G<="0000"; 
VGA_B<="1111"; 
                elsif is_stem='1' then VGA_R<="0000"; VGA_G<="1000"; 
VGA_B<="0000"; 
                elsif is_grass='1' then  
                    if is_grass_light='1' then VGA_R<="0010"; VGA_G<="1100"; 
VGA_B<="0010"; else VGA_R<="0000"; VGA_G<="1000"; VGA_B<="0010"; end if; 
                elsif is_sun='1' and bg_stage < 2 then VGA_R<="1111"; 
VGA_G<="1111"; VGA_B<="0000"; 
                elsif is_cloud='1' then VGA_R<="1111"; VGA_G<="1111"; 
VGA_B<="1111"; 
                else 
                    case bg_stage is 
                        when 0 => VGA_R<="0000"; VGA_G<="1000"; VGA_B<="1111";  
                        when 1 => VGA_R<="1000"; VGA_G<="0111"; VGA_B<="0000";  
                        when 2 => VGA_R<="0000"; VGA_G<="0000"; VGA_B<="0100";  
                        when others => VGA_R<="0000"; VGA_G<="1000"; 
VGA_B<="1111"; 
                    end case; 
                end if; 
            end if; 
        else VGA_R<="0000"; VGA_G<="0000"; VGA_B<="0000"; end if; 
    end process; 
end Behavioral;
