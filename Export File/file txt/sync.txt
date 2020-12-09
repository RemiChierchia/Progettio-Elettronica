library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sync is
	port(
	    clk : in std_logic;
		vga_clk : in std_logic;
		hsync,vsync : out std_logic;
		R,G,B : out std_logic_vector (3 downto 0);
		puntatore_x : in std_logic_vector (10 downto 0); --640
		puntatore_y : in std_logic_vector (10 downto 0); --480
		new_data : in std_logic;
		keyR : in std_logic;
		keyL : in std_logic
	);
end sync;

architecture Behavioral of sync is
	
	signal RGB : std_logic_vector (2 downto 0);
	signal draw : std_logic;
	signal hpos : integer range 0 to 800 := 0;--640x480
	signal vpos : integer range 0 to 521 := 0;--ma servono piu pixel per scrivere quelli per la sincronizzazione
	
begin

	process(vga_clk) is begin
	
		if rising_edge(vga_clk) then
		--scrivi sul display
			if draw = '1' then
				R <= RGB(2) & RGB(2) & RGB(2) & RGB(2);
				G <= RGB(1) & RGB(1) & RGB(1) & RGB(1);
				B <= RGB(0) & RGB(0) & RGB(0) & RGB(0);
			else
				R <= (others => '0');
				G <= (others => '0');
				B <= (others => '0');
			end if;
			
			if hpos < 800 then
				hpos <= hpos + 1;
			else
				hpos <= 0;
				if vpos < 521 then
					vpos <= vpos + 1;
				else
					vpos <= 0;
				end if;
			end if;
			
			if hpos >= 0 and hpos < 96 then--deve stare a 0 per Tpw
                hsync <= '0';
            else
                hsync <= '1';
            end if;
            if vpos >= 0 and vpos < 2 then--deve stare a 0 per Tpw
                vsync <= '0';
            else
                vsync <= '1';
            end if;
            
            if (hpos >= 0 and hpos < 144) or (vpos >= 0 and vpos < 31) then--deve essere tutto spento perche non sono i pixel del display
            R <= (others => '0');                                        --pulse width + back porch
            G <= (others => '0');
            B <= (others => '0');
            end if;
            if (hpos >= 784 and hpos < 800) or (vpos >= 511 and vpos < 521) then--deve essere tutto spento perche non sono i pixel del display
            R <= (others => '0');											  --front porch
            G <= (others => '0');
            B <= (others => '0');
            end if;
            
		end if;
		
	end process;
	
	puntatore : entity work.puntatore(Behavioral) 
        port map(
            vga_clk => vga_clk,
            Xcur => hpos,
            Ycur => vpos,
            puntatore_x => puntatore_x,
            puntatore_y => puntatore_y,
            RGB => RGB,
            draw => draw,
            new_data => new_data,
            keyR => keyR,
            keyL => keyL
        );
	
end Behavioral;