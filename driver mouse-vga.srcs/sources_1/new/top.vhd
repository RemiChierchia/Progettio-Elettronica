library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity top is
    Port (
        clk : in std_logic;
        SW0 : in std_logic;
        CPU_RESETN : in std_logic;
        clk_mouse : inout std_logic;
        data_mouse : inout std_logic;
        error : out std_logic; --led10 U14
        LED : out std_logic_vector (7 downto 0);
        led_tasto_destro : out std_logic; --v12
        led_tasto_sinistro : out std_logic; --v11
        VGA_R,VGA_G,VGA_B : out std_logic_vector (3 downto 0);
        VGA_HS,VGA_VS : out std_logic;
        CA, CB, CC, CD, CE, CF, CG, DP : out std_logic;
        AN : out std_logic_vector( 7 downto 0 )
        );
end top;

architecture Behavioral of top is

    signal data_ready : std_logic := '0';
    signal mouse_status : std_logic_vector(7 downto 0) := (OTHERS => '0');
    signal x_direction : std_logic_vector(7 downto 0) := (OTHERS => '0');
    signal y_direction : std_logic_vector(7 downto 0) := (OTHERS => '0');
    signal segno_x : std_logic := '0';
    signal segno_y : std_logic := '0';
    signal xo : std_logic := '0';--overflow lungo x
    signal yo : std_logic := '0';--overflow lungo y
    signal digit0, digit1, digit2, digit3, digit4, digit5, digit6, digit7 : std_logic_vector (3 downto 0);
    signal vga_clk : std_logic := '0';
    signal seg7x : integer := 0;
    signal seg7y : integer := 0;
    component clk_wiz_0
        port(
            clk_out1          : out    std_logic;
            clk_in1           : in     std_logic
            );
    end component;
    
begin

    pll_vga_clock : clk_wiz_0
        port map(
            clk_in1 => clk,
            clk_out1 => vga_clk
        );

    mouse_driver : entity work.mouse(Behavioral) 
        port map(
            clk => clk,
            clk_mouse => clk_mouse,          
            data_mouse => data_mouse,
            reset => CPU_RESETN,
            error => error,
            led_tasto_sinistro => led_tasto_sinistro,
            led_tasto_destro => led_tasto_destro,
            LED => LED,
            data_ready => data_ready,
            mouse_status => mouse_status,
            x_direction => x_direction,
            y_direction => y_direction
        );
        
    process(clk, data_ready) is begin --dipende dal clk perche data_ready sta a 1 per un ciclo di clock
        if rising_edge(clk) then
            x_direction <= x_direction;--std_logic_vector(unsigned( x_direction )/4);
            y_direction <= y_direction;--std_logic_vector(unsigned( y_direction )/4);
            
            if data_ready ='1' then
                    digit0 <= std_logic_vector(to_signed(   to_integer(signed(y_direction))  mod 10,4));
                    digit1 <= std_logic_vector(to_signed(  (to_integer(signed(y_direction))/10) mod 10,4));
                    digit2 <= std_logic_vector(to_signed(  (to_integer(signed(y_direction))/100) mod 10,4));
                    digit3 <= mouse_status(7) & "00" & mouse_status(5);
                   
                    digit4 <= std_logic_vector(to_signed(   to_integer(signed(x_direction))  mod 10,4));
                    digit5 <= std_logic_vector(to_signed(  (to_integer(signed(x_direction))/10) mod 10,4));
                    digit6 <= std_logic_vector(to_signed(  (to_integer(signed(x_direction))/100) mod 10,4));
                    digit7 <= mouse_status(6) & "00" & mouse_status(4);
            end if;
             
            segno_x <= mouse_status(4);
            segno_y <= mouse_status(5); --va sempre negato perche sulla vga si proietta il contrario --RIMOSSO IL NOT
            xo <= mouse_status(6);
            yo <= mouse_status(7);
            led_tasto_destro <= mouse_status(1);
            led_tasto_sinistro <= mouse_status(0);
        end if;
    end process;

    vga_driver : entity work.vga(Behavioral) 
    port map(
        reset => CPU_RESETN,
        clk => clk,
        VGA_R => VGA_R,
        VGA_G => VGA_G,
        VGA_B => VGA_B,
        VGA_HS => VGA_HS,
        VGA_VS => VGA_VS,
        vga_clk => vga_clk,
        x_direction => x_direction,--_medium,
        y_direction => y_direction,--_medium,
        xo => xo,
        yo => yo,
        segno_x => segno_x,
        segno_y => segno_y,
        new_data => data_ready,
        keyR => mouse_status(1),
        keyL => mouse_status(0)
        );
    
    SevenSeg : entity work.SevenSeg(Behavioral)
    port map(
        clock => clk,
        reset => CPU_RESETN,
        digit0 => digit0,
        digit1 => digit1,
        digit2 => digit2,
        digit3 => digit3,
        digit4 => digit4,
        digit5 => digit5,
        digit6 => digit6,
        digit7 => digit7,
        AN => AN,
        CA => CA,
        CB => CB,
        CC => CC,
        CD => CD,
        CE => CE,
        CF => CF,
        CG => CG,
        DP => DP
    );
end Behavioral;