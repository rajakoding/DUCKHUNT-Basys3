library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; 
 
entity vga_640x480 is 
    port ( 
        clk25    : in std_logic; 
        rst      : in std_logic; 
        hsync    : out std_logic; 
        vsync    : out std_logic; 
        video_on : out std_logic; 
        pixel_x  : out unsigned(9 downto 0); 
        pixel_y  : out unsigned(8 downto 0) 
    ); 
end entity; 
 
architecture rtl of vga_640x480 is 
    constant H_TOTAL : integer := 800; 
    constant V_TOTAL : integer := 525; 
    signal hcount : integer range 0 to H_TOTAL - 1 := 0; 
    signal vcount : integer range 0 to V_TOTAL - 1 := 0; 
begin 
    process(clk25) 
    begin 
        if rising_edge(clk25) then 
            if rst = '1' then 
                hcount <= 0; vcount <= 0; 
            else 
                if hcount = H_TOTAL - 1 then 
                    hcount <= 0; 
                    if vcount = V_TOTAL - 1 then vcount <= 0; else vcount <= 
vcount + 1; end if; 
                else 
                    hcount <= hcount + 1; 
                end if; 
            end if; 
        end if; 
    end process; 
 
    hsync <= '0' when (hcount >= 656 and hcount < 752) else '1'; 
    vsync <= '0' when (vcount >= 490 and vcount < 492) else '1'; 
    video_on <= '1' when (hcount < 640 and vcount < 480) else '0'; 
    pixel_x <= to_unsigned(hcount, pixel_x'length); 
    pixel_y <= to_unsigned(vcount, pixel_y'length); 
end architecture;
