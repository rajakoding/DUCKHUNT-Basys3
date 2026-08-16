library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; 
 
entity ps2_keyboard is 
    port ( 
        clk          : in std_logic; 
        rst          : in std_logic; 
        ps2_clk      : in std_logic; 
        ps2_data     : in std_logic; 
        btn_w        : out std_logic; 
        btn_a        : out std_logic; 
        btn_s        : out std_logic; 
        btn_d        : out std_logic; 
        btn_space    : out std_logic; 
        btn_esc      : out std_logic -- Tambahan tombol ESC 
    ); 
end entity; 
 
architecture rtl of ps2_keyboard is 
    signal ps2_clk_sync : std_logic_vector(1 downto 0); 
    signal ps2_clk_fall : std_logic; 
    signal shift_reg : std_logic_vector(10 downto 0) := (others => '0'); 
    signal bit_count : integer range 0 to 15 := 0; 
     
    signal w, a, s, d, sp, esc : std_logic := '0'; 
    signal key_break : std_logic := '0'; 
     
    -- Startup Timer (Tunggu 500ms agar keyboard stabil) 
    signal startup_timer : integer range 0 to 50000000 := 0;  
    signal ready : std_logic := '0'; 
 
begin 
    process(clk) 
    begin 
        if rising_edge(clk) then 
            ps2_clk_sync <= ps2_clk_sync(0) & ps2_clk; 
             
            -- Logic Startup Delay 
            if startup_timer < 50000000 then 
                startup_timer <= startup_timer + 1; 
                ready <= '0'; 
            else 
                ready <= '1'; 
            end if; 
        end if; 
    end process; 
 
    ps2_clk_fall <= '1' when (ps2_clk_sync = "10") else '0'; 
 
    process(clk) 
    begin 
        if rising_edge(clk) then 
            if rst = '1' then 
                bit_count <= 0; key_break <= '0'; 
                w <= '0'; a <= '0'; s <= '0'; d <= '0'; sp <= '0'; esc <= '0'; 
            elsif ready = '1' and ps2_clk_fall = '1' then 
                shift_reg <= ps2_data & shift_reg(10 downto 1); 
                bit_count <= bit_count + 1; 
            end if; 
 
            if bit_count = 11 then 
                bit_count <= 0; 
                if shift_reg(8 downto 1) = x"F0" then 
                    key_break <= '1'; 
                else 
                    if key_break = '1' then 
                        -- LEPAS 
                        if shift_reg(8 downto 1) = x"1D" then w <= '0'; end if; 
                        if shift_reg(8 downto 1) = x"1C" then a <= '0'; end if; 
                        if shift_reg(8 downto 1) = x"1B" then s <= '0'; end if; 
                        if shift_reg(8 downto 1) = x"23" then d <= '0'; end if; 
                        if shift_reg(8 downto 1) = x"29" then sp <= '0'; end if; 
                        if shift_reg(8 downto 1) = x"76" then esc <= '0'; end 
if; -- ESC Code 
                        key_break <= '0'; 
                    else 
                        -- TEKAN 
                        if shift_reg(8 downto 1) = x"1D" then w <= '1'; end if; 
                        if shift_reg(8 downto 1) = x"1C" then a <= '1'; end if; 
                        if shift_reg(8 downto 1) = x"1B" then s <= '1'; end if; 
                        if shift_reg(8 downto 1) = x"23" then d <= '1'; end if; 
                        if shift_reg(8 downto 1) = x"29" then sp <= '1'; end if; 
                        if shift_reg(8 downto 1) = x"76" then esc <= '1'; end 
if; 
                    end if; 
                end if; 
            end if; 
        end if; 
    end process; 
 
    btn_w <= w; btn_a <= a; btn_s <= s; btn_d <= d; btn_space <= sp; btn_esc <= 
esc; 
 
end architecture;
