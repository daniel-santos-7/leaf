library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_rx is

    generic(
        UART_BAUD: integer
    );

    port (
        clk:     in std_logic;
        reset:   in std_logic;
        rx:      in std_logic;
        rd_data: out std_logic_vector(7 downto 0);
        rd_en:   out std_logic
    );

end entity uart_rx;

architecture uart_rx_arch of uart_rx is

    type state is (START, IDLE, RX_START, RX_DATA, RX_STOP);

    signal curr_state: state;
    signal next_state: state;

    signal uart_baud_val: unsigned(31 downto 0);
    
    signal baud_counter_tc:   std_logic;
    signal baud_counter_clr:  std_logic;
    signal baud_counter_en:   std_logic;
    signal baud_counter_mode: std_logic;
    signal baud_counter_val:  unsigned(31 downto 0);
    signal baud_counter_load: unsigned(31 downto 0);
    
    signal rx_counter_tc:   std_logic;
    signal rx_counter_clr:  std_logic;
    signal rx_counter_en:   std_logic;
    signal rx_counter_val:  unsigned(2 downto 0);
    signal rx_counter_load: unsigned(2 downto 0);
    
    signal sipo_clr: std_logic;
    signal sipo_en:  std_logic;
    signal sipo_ser: std_logic;
    signal sipo_val: std_logic_vector(7 downto 0);

    signal buffer_clr:  std_logic;
    signal buffer_ld:   std_logic;
    signal buffer_load: std_logic_vector(7 downto 0);
    signal buffer_val:  std_logic_vector(7 downto 0);

begin
    
    ----------------------------------------------------------------------
    -- finite state machine
    ----------------------------------------------------------------------

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

    fsm_next_state: process(curr_state, rx, baud_counter_tc, rx_counter_tc)
    begin
        
        case curr_state is
            
            when START =>
                
                next_state <= IDLE;
        
            when IDLE =>
                
                if rx = '0' then
                    
                    next_state <= RX_START;

                else

                    next_state <= IDLE;

                end if;

            when RX_START =>

                if baud_counter_tc = '1' then
                    
                    next_state <= RX_DATA;

                else

                    next_state <= RX_START;

                end if;

            when RX_DATA =>

                if  baud_counter_tc = '1' and rx_counter_tc = '1' then
                    
                    next_state <= RX_STOP;

                else

                    next_state <= RX_DATA;

                end if;

            when RX_STOP => 

                if baud_counter_tc = '1' then
                    
                    next_state <= IDLE;

                else

                    next_state <= RX_STOP;

                end if;
        
        end case;

    end process fsm_next_state;

    ----------------------------------------------------------------------
    -- counter to delay the state machine on receipt
    ----------------------------------------------------------------------

    uart_baud_val <= to_unsigned(UART_BAUD, 32);

    baud_counter_load <= '0' & uart_baud_val(31 downto 1) when curr_state = RX_START else uart_baud_val;

    baud_counter_tc   <= '1' when baud_counter_val = x"00000000" else '0';

    baud_counter_clr  <= '1' when curr_state = START else '0';

    baud_counter_en   <= '0' when curr_state = START else '1';

    baud_counter_mode <= '1' when curr_state = IDLE or baud_counter_tc = '1' else '0';

    baud_counter: process(clk, baud_counter_clr)
    begin
        
        if baud_counter_clr = '1' then
            
            baud_counter_val <= (others => '1');

        elsif rising_edge(clk) then

            if baud_counter_en = '1' then
                
                if baud_counter_mode = '1' then
                    
                    baud_counter_val <= baud_counter_load;

                elsif baud_counter_tc = '1' then

                    baud_counter_val <= (others => '1');

                else

                    baud_counter_val <= baud_counter_val - 1;

                end if;

            end if;
        
        end if;

    end process baud_counter;

    ----------------------------------------------------------------------
    -- received bit counter
    ----------------------------------------------------------------------

    rx_counter_tc  <= '1' when rx_counter_val = b"000" else '0';

    rx_counter_clr <= '1' when curr_state = START else '0';

    rx_counter_en  <= baud_counter_tc when curr_state = RX_DATA else '0';

    rx_counter: process(clk, rx_counter_clr)
    begin
        
        if rx_counter_clr = '1' then
            
            rx_counter_val <= (others => '1');

        elsif rising_edge(clk) then

            if rx_counter_en = '1' then
                
                if rx_counter_tc = '1' then

                    rx_counter_val <= (others => '1');

                else

                    rx_counter_val <= rx_counter_val - 1;

                end if;

            end if;
        
        end if;

    end process rx_counter;

    ----------------------------------------------------------------------
    -- receive buffer
    ----------------------------------------------------------------------

    buffer_clr <= '1' when curr_state = START else '0';

    buffer_ld  <= '1' when curr_state = RX_STOP and next_state = IDLE else '0';

    buffer_load <= sipo_val;

    rx_buffer: process(clk)
    begin
        
        if buffer_clr = '1' then
                
            buffer_val <= (others => '0');

        elsif rising_edge(clk) then

            if buffer_ld = '1' then
                
                buffer_val <= buffer_load;

            end if;

        end if;

    end process rx_buffer;

    ----------------------------------------------------------------------
    -- 8 bit sipo register for reception (serial-in, parallel-out)
    ----------------------------------------------------------------------

    sipo_clr <= '1' when curr_state = START else '0';

    sipo_en  <= baud_counter_tc when curr_state = RX_START or curr_state = RX_DATA else '0';        
    
    sipo_ser <= rx;

    sipo: process(clk, sipo_clr)
    begin
        
        if sipo_clr = '1' then
            
            sipo_val <= (others => '1');

        elsif rising_edge(clk) then

            if sipo_en = '1' then

                sipo_val <= sipo_ser & sipo_val(7 downto 1);

            end if;

        end if;

    end process sipo;

    ----------------------------------------------------------------------
    -- reception output
    ----------------------------------------------------------------------

    rd_data <= buffer_val;

    ----------------------------------------------------------------------
    -- flags
    ----------------------------------------------------------------------

    rd_en <= '1' when curr_state = IDLE else '0';
    
end architecture uart_rx_arch;