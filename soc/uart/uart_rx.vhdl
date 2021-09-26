library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_rx is

    generic(
        UART_BAUD: integer
    );

    port (
        clk:    in std_logic;
        reset:  in std_logic;
        rx:     in std_logic;

        rd_en: out std_logic;
        rdata: out std_logic_vector(7 downto 0)
    );

end entity uart_rx;

architecture uart_rx_arch of uart_rx is

    type state is (START, IDLE, RX_START, RX_DATA, RX_STOP);

    signal curr_state: state;
    signal next_state: state;
    
    signal baud_counter_val: integer;
    signal baud_counter_inc: std_logic;
    signal baud_counter_clr: std_logic;
    
    signal rx_counter_val: integer range 0 to 7;
    signal rx_counter_inc: std_logic;
    signal rx_counter_clr: std_logic;
    
    signal rx_buffer:       std_logic_vector(7 downto 0);
    signal rx_buffer_clr:   std_logic;
    signal rx_buffer_shift: std_logic;

begin
    
    fsm: process(clk)
    begin
        
        if rising_edge(clk) then
            
            if reset = '1' then
            
                curr_state <= START;
            
            else

                curr_state <= next_state;

            end if;

        end if;

    end process fsm;

    baud_counter: process(clk)
    begin
        
        if rising_edge(clk) then
            
            if baud_counter_clr = '1' then
                
                baud_counter_val <= 0;

            elsif baud_counter_inc = '1' then

                baud_counter_val <= baud_counter_val + 1;

            end if;

        end if;

    end process baud_counter;

    rx_counter: process(clk)
    begin
        
        if rising_edge(clk) then
            
            if rx_counter_clr = '1' then
                
                rx_counter_val <= 0;

            elsif rx_counter_inc = '1' then

                rx_counter_val <= rx_counter_val + 1;

            end if;

        end if;

    end process rx_counter;

    rx_buffer_ctrl: process(clk)
    begin
        
        if rising_edge(clk) then
            
            if rx_buffer_clr = '1' then
                
                rx_buffer <= (others => '1');

            elsif rx_buffer_shift = '1' then

                rx_buffer <= rx & rx_buffer(7 downto 1); 

            end if;

        end if;

    end process rx_buffer_ctrl;

    execute: process(curr_state, rx, baud_counter_val)
    begin
        
        case curr_state is
            
            when START =>
                
                next_state       <= IDLE;
                baud_counter_inc <= '0';
                baud_counter_clr <= '1';
                rx_counter_inc   <= '0';
                rx_counter_clr   <= '1';
                rx_buffer_clr    <= '1';
                rx_buffer_shift  <= '0';
        
            when IDLE =>
                
                if rx = '0' then
                    
                    next_state <= RX_START;

                else

                    next_state <= IDLE;

                end if;

                baud_counter_inc <= '0';
                baud_counter_clr <= '1';
                rx_counter_inc   <= '0';
                rx_counter_clr   <= '1';
                rx_buffer_clr    <= '0';
                rx_buffer_shift  <= '0';

            when RX_START =>

                if baud_counter_val = UART_BAUD/2 then
                    
                    next_state       <= RX_DATA;
                    baud_counter_inc <= '0';
                    baud_counter_clr <= '1';

                else

                    next_state       <= RX_START;
                    baud_counter_inc <= '1';
                    baud_counter_clr <= '0';

                end if;

                rx_counter_inc  <= '0';
                rx_counter_clr  <= '1';
                rx_buffer_clr   <= '1';
                rx_buffer_shift <= '0';

            when RX_DATA =>

                if baud_counter_val = UART_BAUD then

                    if rx_counter_val = 7 then
                        
                        next_state       <= RX_STOP;
                        baud_counter_inc <= '0';
                        baud_counter_clr <= '1';
                        rx_counter_inc   <= '0';
                        rx_counter_clr   <= '1';

                    else

                        next_state       <= RX_DATA;
                        baud_counter_inc <= '0';
                        baud_counter_clr <= '1';
                        rx_counter_inc   <= '1';
                        rx_counter_clr   <= '0';

                    end if;

                    rx_buffer_shift  <= '1';

                else

                    next_state       <= RX_DATA;
                    baud_counter_inc <= '1';
                    baud_counter_clr <= '0';
                    rx_counter_inc   <= '0';
                    rx_counter_clr   <= '0';
                    rx_buffer_shift  <= '0';

                end if;

                rx_buffer_clr  <= '0';

            when RX_STOP => 

                if baud_counter_val = UART_BAUD then
                    
                    next_state       <= IDLE;
                    baud_counter_inc <= '0';
                    baud_counter_clr <= '1';

                else

                    next_state       <= RX_STOP;
                    baud_counter_inc <= '1';
                    baud_counter_clr <= '0';

                end if;

                rx_counter_inc  <= '0';
                rx_counter_clr  <= '1';
                rx_buffer_clr   <= '0';
                rx_buffer_shift <= '0';
        
        end case;

    end process execute;

    rd_en <= '1' when curr_state = IDLE else '0';
    
    rdata <= rx_buffer when curr_state = IDLE else (others => '1');

end architecture uart_rx_arch;