library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity puntatore is
	port( --simile ad una funzione ma puo fornire piu di un uscita e assegnare ilmodo out in piu
	    vga_clk : in std_logic;
		Xcur,Ycur : in integer; 	
        puntatore_x : in std_logic_vector (10 downto 0); --640
		puntatore_y : in std_logic_vector (10 downto 0); --480
		RGB : out std_logic_vector (2 downto 0);
		draw : out std_logic;
		new_data : in std_logic;
		keyR : in std_logic;
		keyL : in std_logic
		);
end puntatore;

architecture Behavioral of puntatore is

    signal Xpos : std_logic_vector (10 downto 0); --640
	signal Ypos : std_logic_vector (10 downto 0); --480
	signal keys : std_logic_vector (1 downto 0) := (OTHERS => '0');
	
begin
    Xpos <= 144 + puntatore_x;
    Ypos <= 31 + puntatore_y;
    process (vga_clk) is begin
            
        if rising_edge(vga_clk) then
            if keyL = '1' then
                keys(1) <= not keys(1);
            end if;
            if keyR = '1' then
                keys(0) <= not keys(0);
            end if;
            
            if Xcur > 143 and Xcur < 785 and Ycur > 30 and Ycur < 512 then --Se sono nella zona del display --anticipato di un pixel 
                draw <= '1';
                if Xcur > (Xpos) and Xcur < (Xpos+4) and Ycur > (Ypos) and Ycur < (Ypos+4) then --se sono nella zona del puntatore
                    RGB <= not keys(1) & '1' & not keys(0) ;--puntatore a colori                                                                                                                                                                  -- 0-640 e 0-480
                else
                    RGB <= "000";--tutto nero
                end if;
            else
                draw <= '0'; --tutto nero
            end if;
		end if;
    end process;
    
end Behavioral;