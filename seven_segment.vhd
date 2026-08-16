library IEEE; 
use IEEE.STD_LOGIC_1164.ALL; 
use IEEE.NUMERIC_STD.ALL; 
 
entity seven_segment is 
    Port ( 
        clk      : in STD_LOGIC; 
        rst      : in STD_LOGIC; 
        score_in : in integer; 
        seg      : out STD_LOGIC_VECTOR (6 downto 0); 
        an       : out STD_LOGIC_VECTOR (3 downto 0) 
    ); 
end seven_segment; 
 
architecture Behavioral of seven_segment is 
    signal refresh_counter : unsigned(19 downto 0) := (others => '0'); 
    signal sel : std_logic_vector(1 downto 0); 
    signal num : integer range 0 to 9; 
     
    -- Variabel pemisah angka 
    signal dig0, dig1, dig2, dig3 : integer range 0 to 9; 
 
begin 
    -- Pemisahan Digit (Ribuan, Ratusan, Puluhan, Satuan) 
    dig0 <= score_in mod 10;                -- Satuan 
    dig1 <= (score_in / 10) mod 10;         -- Puluhan 
    dig2 <= (score_in / 100) mod 10;        -- Ratusan 
    dig3 <= (score_in / 1000) mod 10;       -- Ribuan 
 
    -- Refresh Clock 
    process(clk) 
    begin 
        if rising_edge(clk) then 
            refresh_counter <= refresh_counter + 1; 
        end if; 
    end process; 
    sel <= std_logic_vector(refresh_counter(19 downto 18)); 
 
    -- Multiplexer Anode (Active Low: 0 = Nyala) 
    process(sel, dig0, dig1, dig2, dig3) 
    begin 
        case sel is 
            when "00" => 
                an <= "1110"; -- Digit Kanan (Satuan) 
                num <= dig0; 
            when "01" => 
                an <= "1101"; -- Digit Kedua (Puluhan) 
                num <= dig1; 
            when "10" => 
                an <= "1011"; -- Digit Ketiga (Ratusan) 
                num <= dig2; 
            when "11" => 
                an <= "0111"; -- Digit Kiri (Ribuan) 
                num <= dig3; 
            when others => 
                an <= "1111"; num <= 0; 
        end case; 
    end process; 
 
    -- Decoder Angka (Active Low: 0 = Nyala) 
    process(num) 
    begin 
        case num is 
            when 0 => seg <= "1000000"; -- 0 
            when 1 => seg <= "1111001"; -- 1 
            when 2 => seg <= "0100100"; -- 2 
            when 3 => seg <= "0110000"; -- 3 
            when 4 => seg <= "0011001"; -- 4 
            when 5 => seg <= "0010010"; -- 5 
            when 6 => seg <= "0000010"; -- 6 
            when 7 => seg <= "1111000"; -- 7 
            when 8 => seg <= "0000000"; -- 8 
            when 9 => seg <= "0010000"; -- 9 
            when others => seg <= "1111111"; -- Mati 
        end case; 
    end process; 
 
end Behavioral; 
