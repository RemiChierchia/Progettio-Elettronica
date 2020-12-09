library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mouse is
    Port ( 
        clk : in std_logic;
        clk_mouse : inout std_logic;
        data_mouse : inout std_logic;
        reset : in std_logic;
        error : out std_logic;
        led_tasto_sinistro : out std_logic; --v11 --15
        led_tasto_destro : out std_logic; --v12 --14
        LED : out std_logic_vector (7 downto 0);
        data_ready : out std_logic;
        mouse_status : out std_logic_vector(7 downto 0) := (OTHERS => '0');
        x_direction : out std_logic_vector(7 downto 0) := (OTHERS => '0');
        y_direction : out std_logic_vector(7 downto 0) := (OTHERS => '0')
        );
end mouse;

architecture Behavioral of mouse is
    
    Type state_host is ( res, inhibit, start, mouse_release, ack_start, set_stream, ack_stream, idle, aquisition );
    signal state : state_host := res;

    signal parity : std_logic := '0'; --bit di Parità
    signal bit_count : integer := 0;
    signal count100 : integer := 0;
    signal scrivi : std_logic := '0'; --di default a Z
    signal set_clock : std_logic := '1'; --di default a Z
    signal data_to_mouse : std_logic := '0';
    signal mouse_status_read : std_logic_vector(7 downto 0) := (OTHERS => '0');
    signal x_direction_read : std_logic_vector(7 downto 0) := (OTHERS => '0');
    signal y_direction_read : std_logic_vector(7 downto 0) := (OTHERS => '0');
    signal recived1 : std_logic_vector(7 downto 0) := (OTHERS => '0');
    signal recived2 : std_logic_vector(7 downto 0) := (OTHERS => '0');
    signal recived3 : std_logic_vector(7 downto 0) := (OTHERS => '0'); 
    
    signal falling_clk_mouse : std_logic;

    signal A, B : std_logic := '0';
    
    signal controllo : std_logic := '0';

begin

	data_mouse <= data_to_mouse when scrivi = '1' else 'Z';
    clk_mouse <= '0' when set_clock = '0' else 'Z';
    
    falling_clk_mouse <= (not A) and B; --va a 1 al falling edge del clk del mouse altrimenti e a 0

    process(clk, state, falling_clk_mouse) begin --togliere clk_mouse forse inutile 

        if rising_edge(clk) then --reset sincrono
        
            A <= clk_mouse;
            B <= A;   
        
            if reset = '0' then --azzeramento dei vari registri e segnali       
                state <= res;
            else
            
                case state is
                
                    when res =>
                        led(7 downto 0) <= (others => '0');
                        led(0) <= '1';                  
                        parity <= '0';
                        bit_count <= 0;
                        count100 <= 0;
                        error <= '0';
                        controllo <= '0';
                        data_to_mouse <= '0';
                        state <= inhibit;
                        scrivi <= '0';
                        set_clock <= '1';
                        mouse_status <= (OTHERS => '0');
                        x_direction <= (OTHERS => '0');
                        y_direction <= (OTHERS => '0');
                        recived1 <= (OTHERS => '0');
                        recived2 <= (OTHERS => '0');
                        recived3 <= (OTHERS => '0');
                        state <= inhibit;
                        
                    when inhibit => --inibizione
                        led(7 downto 0) <= (others => '0');
                        led(1) <= '1';
                        data_to_mouse <= '0';
                        count100 <= count100 + 1;
                        if count100 < 11000 then --inibizione
                            scrivi <= '0';
                            set_clock <= '0'; --setto a 0 il clock
                        elsif count100 < 13000 then --il tempo per un cambio di stato del data deve stare dai 5 ai 25us causa della frequenza del clock del mouse
                            set_clock <= '0'; --tieni a 0 il clock
                            scrivi <= '1'; --data a 0
                        else
                            set_clock <= '1'; --quando rilascio il clock del mouse devo metterlo a Z per default
                            count100 <= 0;
                            if controllo = '1' then
                                state <= set_stream;
                                controllo <= '0';
                            else
                                state <= start;
                                controllo <= '1';
                            end if;
                        end if;
                        
                    when start => --invio FF
                        led(7 downto 0) <= (others => '0');
                        led(2) <= '1';
                        if (falling_clk_mouse = '1') then
                            bit_count <= bit_count + 1;
                            scrivi <= '1';
                            if (bit_count >= 0 and bit_count < 8) then   
                                data_to_mouse <= '1';
                            elsif (bit_count = 8) then
                                data_to_mouse <= '1';
                            else
                                state <= ack_start;
                                bit_count <= 0;
                                scrivi <= '0';
                            end if;
                        end if;
                        
                    when ack_start => -- controllo ricezione FA, AA e 00
                        led(7 downto 0) <= (others => '0');
                        led(3) <= '1';
                        if falling_clk_mouse = '1' then
                            bit_count <= bit_count + 1;
                            if bit_count < 33 then
                                if (bit_count < 10) then
                                    recived1 <= data_mouse & recived1(7 downto 1); --shift right
                                elsif (bit_count >= 13 and bit_count < 21) then
                                    recived2 <= data_mouse & recived2(7 downto 1); --shift right
                                elsif (bit_count >= 24 and bit_count < 32) then
                                    recived3 <= data_mouse & recived3(7 downto 1); --shift right  
                                end if;
                            else                                 
                                if (recived1 = "11111010" and recived2 = "10101010" and recived3 = "00000000") then --controllo ricezione
                                    bit_count <= 0;
                                    controllo <= '1';            
                                    state <= inhibit;                 
                                end if;
                            end if;
                        end if; 
                                 
                    when set_stream => --invio di F4 per mandare il mouse in stream mode 
                        led(7 downto 0) <= (others => '0');
                        led(4) <= '1';
                        if (falling_clk_mouse = '1') then --il clk non inizia a oscillare
                            bit_count <= bit_count + 1;
                            scrivi <= '1';
                            if (bit_count >= 0 and bit_count < 2) then
                                data_to_mouse <= '0';
                            elsif (bit_count = 2) then
                                data_to_mouse <= '1';
                            elsif (bit_count = 3) then
                                data_to_mouse <= '0';
                            elsif (bit_count >= 4 and bit_count < 8) then
                                data_to_mouse <= '1';
                            elsif (bit_count = 8) then
                                data_to_mouse <= '0';
                            else 
                                scrivi <= '0';
                                bit_count <= 0;
                                state <= ack_stream; 
                            end if;
                        end if;
                        
                    when ack_stream => -- controllo ricezione FA
                        led(7 downto 0) <= (others => '0');
                        led(5) <= '1';
                        if falling_clk_mouse = '1' then 
                            if (bit_count < 11) then --finiscono i colpi di clock per cui devo limitarmi a 11 senno campiono quando il clock torna a 1
                                bit_count <= bit_count + 1;
                                if (bit_count < 10) then --guarda qua meglio
                                    recived1 <= data_mouse & recived1(7 downto 1); --shift right
                                end if;
                            else
                                if (recived1 = "11111010") then --controllo ricezione FA 
                                    bit_count <= 0;
                                    state <= idle; -- ricezione di FA vai a enable data
                                end if;
                            end if;
                        end if;
                        
                    when idle => -- stato intermedio dove si aspetta l'inizio della comunicazione del mouse
                        led(7 downto 0) <= (others => '0');
                        led(6) <= '1';
                        scrivi <= '0'; --setto Z di default su data_mouse
                        set_clock <= '1'; --setto il clock a Z 
                        parity <= '0';
                        bit_count <= 0;
                        error <= '0';
                        mouse_status <= (OTHERS => '0');
                        x_direction <= (OTHERS => '0');
                        y_direction <= (OTHERS => '0');
                        data_ready <= '0';
                        if (data_mouse = '0') then --bit di start
                            --data_ready <= '0';
                            state <= aquisition;
                        end if;
                        
                    when aquisition => -- inizio acquisizione dati, prima il bit meno significativo, shift a destra
                        led(7 downto 0) <= (others => '0');
                        led(7) <= '1';
                        
                        if falling_clk_mouse = '1' then   
                            if bit_count < 9 then --cosi butto fuori il bit di start
                                mouse_status_read <= data_mouse & mouse_status_read(7 downto 1); --shift right
                                parity <= parity xor data_mouse; --il bit di start non influisce
                            elsif (bit_count = 9) then --parity bit
                                mouse_status <= mouse_status_read;
                                if(parity /= data_mouse) then
                                    error <= '0';
                                else
                                    error <= '1';
                                end if;            
                                parity <= '0'; --dopo il controllo azzero il bit di Parità  
                                
                            elsif (bit_count >= 12 and bit_count < 20) then --in 20 c'e il parity bit che non leggo
                                x_direction_read <= data_mouse & x_direction_read(7 downto 1); --shift right
                                parity <= parity xor data_mouse;
                            elsif (bit_count = 20) then --parity bit
                                x_direction <= x_direction_read;
                                if(parity /= data_mouse) then
                                    error <= '0';
                                else
                                    error <= '1';
                                end if;
                                parity <= '0'; --dopo il controllo azzero il bit di Parità
                                
                            elsif (bit_count >= 23 and bit_count < 31) then
                                y_direction_read <= data_mouse & y_direction_read(7 downto 1); --shift right
                                parity <= parity xor data_mouse;
                            elsif (bit_count = 31) then
                                y_direction <= y_direction_read;
                                if(parity /= data_mouse) then
                                    error <= '0';
                                else
                                    error <= '1';
                                end if;
                                parity <= '0';
                            elsif (bit_count = 32) then --bit di stop
                                if data_mouse = '1' then
                                    state <= idle;
                                    bit_count <= 0;
                                    data_ready <= '1';
                                    
                                end if;
                            end if;
                            
                            bit_count <= bit_count + 1;
                        end if;     
                    when others =>
                        state <= res;
                end case;              
            end if;
        end if; 

    end process;
    
        
end Behavioral;