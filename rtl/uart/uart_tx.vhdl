library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_tx is

    generic(
        UART_BAUD: integer
    );

    port (
        clk:     in  std_logic;
        reset:   in  std_logic;
        wr:      in  std_logic;
        wr_data: in  std_logic_vector(7 downto 0);
        wr_en:   out std_logic;
        tx:      out std_logic
    );
end entity uart_tx;

architecture uart_tx_arch of uart_tx is

    type state is (START, IDLE, TX_START, TX_DATA, TX_STOP);

    signal curr_state: state;
    signal next_state: state;

    signal baud_counter_tc:   std_logic;
    signal baud_counter_clr:  std_logic;
    signal baud_counter_en:   std_logic;
    signal baud_counter_mode: std_logic;
    signal baud_counter_val:  unsigned(31 downto 0);
    signal baud_counter_load: unsigned(31 downto 0);

    signal tx_counter_tc:   std_logic;
    signal tx_counter_clr:  std_logic;
    signal tx_counter_en:   std_logic;
    signal tx_counter_val:  unsigned(2 downto 0);
    signal tx_counter_load: unsigned(2 downto 0);

    signal piso_clr:  std_logic;
    signal piso_en:   std_logic;
    signal piso_mode: std_logic;
    signal piso_val:  std_logic_vector(7 downto 0);
    signal piso_load: std_logic_vector(7 downto 0);

    signal buffer_clr:  std_logic;
    signal buffer_ld:   std_logic;
    signal buffer_load: std_logic_vector(7 downto 0);
    signal buffer_val:  std_logic_vector(7 downto 0);

    signal tx_bit: std_logic;

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

    fsm_next_state: process(curr_state, wr, baud_counter_tc, tx_counter_tc)
    begin
        
        case curr_state is
            
            when START =>
                
                next_state <= IDLE;
        
            when IDLE =>
                
                if wr = '1' then
                    
                    next_state <= TX_START;

                else

                    next_state <= IDLE;

                end if;

            when TX_START =>

                if baud_counter_tc = '1' then
                    
                    next_state <= TX_DATA;
                    
                else

                    next_state <= TX_START;

                end if;

            when TX_DATA =>

                if baud_counter_tc = '1' and tx_counter_tc = '1' then
                    
                    next_state <= TX_STOP;

                else

                    next_state <= TX_DATA;

                end if;

            when TX_STOP => 

                if baud_counter_tc = '1' then
                    
                    next_state <= IDLE;

                else

                    next_state <= TX_STOP;

                end if;
        
        end case;

    end process fsm_next_state;

    ----------------------------------------------------------------------
    -- counter to delay state machine in transmission
    ----------------------------------------------------------------------

    baud_counter_load <= to_unsigned(UART_BAUD, 32);

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
    -- transmitted bit count
    ----------------------------------------------------------------------

    tx_counter_tc  <= '1' when tx_counter_val = b"000" else '0';

    tx_counter_clr <= '1' when curr_state = START else '0';

    tx_counter_en  <= baud_counter_tc when curr_state = TX_DATA else '0';

    tx_counter: process(clk, tx_counter_clr)
    begin
        
        if tx_counter_clr = '1' then
            
            tx_counter_val <= (others => '1');

        elsif rising_edge(clk) then

            if tx_counter_en = '1' then
                
                if tx_counter_tc = '1' then

                    tx_counter_val <= (others => '1');

                else

                    tx_counter_val <= tx_counter_val - 1;

                end if;

            end if;
        
        end if;

    end process tx_counter;

    ----------------------------------------------------------------------
    -- transmission buffer register
    ----------------------------------------------------------------------

    buffer_clr <= '1' when curr_state = START else '0';

        buffer_ld  <= '1' when curr_state = IDLE and next_state = TX_START else '0';
    
        buffer_load <= wr_data;
    
        buffer_reg: process(clk, buffer_clr)
        begin
            
            if buffer_clr = '1' then
                
                buffer_val <= (others => '0');
    
            elsif rising_edge(clk) then
    
                if buffer_ld = '1' then
                    
                    buffer_val <= buffer_load;
    
                end if;
    
            end if;
    
        end process buffer_reg;

    ----------------------------------------------------------------------
    -- 8 bit piso register for transmission (parallel-in, serial-out)
    ----------------------------------------------------------------------

    piso_clr <= '1' when curr_state = START else '0';

    piso_en  <= baud_counter_tc when curr_state = TX_START or curr_state = TX_DATA else '0';

    piso_mode <= '1' when curr_state = TX_START else '0';

    piso_load <= buffer_val;

    piso: process(clk, piso_clr)
    begin
        
        if piso_clr = '1' then
            
            piso_val <= (others => '1');

        elsif rising_edge(clk) then

            if piso_en = '1' then
                
                if piso_mode = '1' then
                    
                    piso_val <= piso_load;

                else

                    piso_val <= '1' & piso_val(7 downto 1);

                end if;

            end if;

        end if;

    end process piso;

    ----------------------------------------------------------------------
    -- transmission output
    ----------------------------------------------------------------------

    tx_bit <= '0' when curr_state = TX_START else '1';

    tx <= piso_val(0) when curr_state = TX_DATA else tx_bit;

    ----------------------------------------------------------------------
    -- flags
    ----------------------------------------------------------------------

    wr_en <= '1' when curr_state = IDLE else '0';

end architecture uart_tx_arch;