library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vga is
	port(
	    reset: in std_logic;
        clk : in std_logic;
        VGA_R,VGA_G,VGA_B : out std_logic_vector (3 downto 0);  --colore da rappresentare
        VGA_HS,VGA_VS : out std_logic;                          --segnali di sincronizzazione orizzontale e verticale
        vga_clk : in std_logic;                                 --clk per la VGA (25Mhz)
        x_direction : in std_logic_vector (7 downto 0);         --
		y_direction : in std_logic_vector (7 downto 0);         --
		xo : in std_logic;                                      --è avvenuto un overflow lungo X 
        yo : in std_logic;                                      --è avvenuto un overflow lungo y
        segno_x : in std_logic;                                 --movimento di X positivo o negativo
        segno_y : in std_logic;                                 --movimento di Y positivo o negativo
        new_data : in std_logic;                                 --il mouse ha un nuovo dato pronto
        keyR : in std_logic;
        keyL : in std_logic
	);
end vga;

architecture Behavioral of vga is

    signal puntatore_x : std_logic_vector (10 downto 0) := (others => '0');     --640
    signal puntatore_y : std_logic_vector (10 downto 0) := (others => '0');     --480
    signal contatore_x : std_logic_vector (10 downto 0) := (others => '0');
    signal contatore_y : std_logic_vector (10 downto 0) := (others => '0');
    
begin

    process(clk) is
        variable del_x_sign : signed (10 downto 0) := (others => '0');
        variable del_y_sign : signed (10 downto 0) := (others => '0');
        variable pos_x_sign : signed (10 downto 0) := (others => '0');
        variable pos_y_sign : signed (10 downto 0) := (others => '0');
    begin
        if rising_edge(clk) then
            if(reset = '0') then
                pos_x_sign := to_signed(0,11);
                pos_y_sign := to_signed(0,11);
            end if;
            
            if new_data = '1' then                              --ho un dato pronto dal mouse  
                
                if xo = '1' then
                    if segno_x = '0' then
                        del_x_sign := to_signed(127 , 11);
                    else
                        del_x_sign := to_signed(-127 , 11);
                    end if;
                else
                    del_x_sign := to_signed( to_integer(  signed(x_direction) ), 11);
                end if;
                
                if yo = '1' then
                    if segno_y = '0' then
                        del_y_sign := to_signed(127 , 11);
                    else
                        del_y_sign := to_signed(-127 , 11);
                    end if;
                else
                    del_y_sign := to_signed( to_integer(  -signed(y_direction) ), 11);
                end if;
                
                -------
                ---X---
                -------
                
                if (pos_x_sign + del_x_sign > to_signed(640,11)) then --se supero il limite dello schermo (640)
                    pos_x_sign := to_signed(640,11);                --posiziono il puntatore a 640
                
                elsif (pos_x_sign + del_x_sign < to_signed(0,11)) then
                    pos_x_sign := to_signed(0,11);
                
                else
                    pos_x_sign := pos_x_sign + del_x_sign;
                end if;
                              
                -------
                ---Y---
                -------
                
                if(pos_y_sign + del_y_sign > to_signed(480,11)) then --se supero il limite dello schermo (640)
                    pos_y_sign := to_signed(480,11);                --posiziono il puntatore a 640
                
                elsif(pos_y_sign + del_y_sign < to_signed(0,11)) then
                    pos_y_sign := to_signed(0,11);
                else
                    pos_y_sign := pos_y_sign + del_y_sign;
                end if;

                
                puntatore_x <= std_logic_vector(pos_x_sign);
                puntatore_y <= std_logic_vector(pos_y_sign);
        end if; -- new_data = 1    
    end if; -- rising_edge
    
end process;

	sync : entity work.sync (Behavioral)
	port map(
	   clk => clk,
	   vga_clk => vga_clk,
	   R => VGA_R,
       G => VGA_G,
       B => VGA_B,
       hsync => VGA_HS,
       vsync => VGA_VS,
       puntatore_x => puntatore_x,
       puntatore_y => puntatore_y,
       new_data => new_data,
       keyR => keyR,
       keyL => keyL
	);
	
end Behavioral;
