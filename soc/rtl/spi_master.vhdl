library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_master is
    
    port (
        clk:   in std_logic;
        reset: in std_logic;
        
        en: in std_logic;

        tx_data: in  std_logic_vector(7 downto 0);
        rx_data: out std_logic_vector(7 downto 0);

        busy: out std_logic;
        done: out std_logic;

        cpol: in  std_logic;
        cpha: in  std_logic;
        sdo:  out std_logic;
        sdi:  in  std_logic;
        sclk: out std_logic;
        cs:   out std_logic
    );

end entity spi_master;

architecture spi_master_arch of spi_master is
    
    type state is (START, IDLE, COMMUNICATION, UPSHOT);
    
    signal current_state: state;
    signal next_state:    state;

    signal tx_sreg: std_logic_vector(7 downto 0);
    signal rx_sreg: std_logic_vector(7 downto 0);

    signal tx_count: std_logic_vector(7 downto 0);
    signal rx_count: std_logic_vector(7 downto 0);
    
    signal comm_cyc: std_logic;

    signal sclk_i: std_logic;

begin
    
    fsm: process(clk)
    
    begin
    
        if rising_edge(clk) then
            
            if reset = '1' then
                
                current_state <= START;

            else

                current_state <= next_state;

            end if;

        end if;
        
    end process fsm;

    fsm_next_state: process(current_state, en, tx_count, rx_count)
    
    begin
        
        case current_state is
            
            when START =>
                
                next_state <= IDLE;
        
            when IDLE =>
                
                if en = '1' then
                    
                    next_state <= COMMUNICATION;

                else

                    next_state <= IDLE;

                end if;

            when COMMUNICATION =>

                if tx_count = x"FF" and rx_count = x"FF" then
                        
                    next_state <= UPSHOT;

                else

                    next_state <= COMMUNICATION;

                end if;

            when UPSHOT =>

                next_state <= IDLE;
        
        end case;

    end process fsm_next_state;

    comm: process(clk)
    
    begin

        if rising_edge(clk) then
            
            case current_state is
            
                when START =>
                    
                    rx_sreg <= (others => '0');
                    tx_sreg <= (others => '0');

                    rx_count <= (others => '0');
                    tx_count <= (others => '0');
                    
                    comm_cyc <= not cpha;
    
                    sdo <= '0';

                    sclk_i <= cpol;

                when IDLE =>
    
                    if next_state = COMMUNICATION then
                        
                        tx_sreg <= tx_data;
    
                    end if;

                    rx_count <= (others => '0');
                    tx_count <= (others => '0');

                    comm_cyc <= not cpha;

                    sdo <= '0';

                    sclk_i <= cpol;

                when COMMUNICATION =>

                    if rx_count = x"FF" and tx_count = x"FF" then
                       
                        sclk_i <= cpol;

                    else

                        sclk_i <= not sclk_i;

                    end if;

                    comm_cyc <= not comm_cyc;

                    if comm_cyc = '0' and rx_count /= x"FF" then
                        
                        rx_sreg <= rx_sreg(6 downto 0) & sdi;
                        
                        rx_count <= rx_count(6 downto 0) & '1'; 

                    end if;

                    if comm_cyc = '1' and tx_count /= x"FF" then
                        
                        sdo <= tx_sreg(7);
                        
                        tx_sreg <= tx_sreg(6 downto 0) & '0';

                        tx_count <= tx_count(6 downto 0) & '1';

                    end if;

                when UPSHOT =>

                    rx_count <= (others => '0');
                    tx_count <= (others => '0');

                    sclk_i <= cpol;
            
            end case;

        end if;

    end process comm;

    rx_data <= rx_sreg;

    busy <= '0' when current_state = IDLE or current_state = UPSHOT else '1';
    
    done <= '1' when current_state = UPSHOT else '0';
    
    sclk <= sclk_i;

    cs <= '0' when current_state = COMMUNICATION else '1';
    
end architecture spi_master_arch;