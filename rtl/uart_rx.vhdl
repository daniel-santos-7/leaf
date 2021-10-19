library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.uart_pkg.all;

entity uart_rx is
    port (
        clk:      in  std_logic;
        reset:    in  std_logic;
        baud_div: in  std_logic_vector(15 downto 0);
        wr:       out std_logic;
        wr_en:    in  std_logic;
        wr_data:  out std_logic_vector(7 downto 0);
        busy:     out std_logic;
        rx:       in  std_logic
    );
end entity uart_rx;

architecture uart_rx_arch of uart_rx is

    type state is (START, IDLE, RX_START, RX_DATA, RX_STOP);

    signal curr_state: state;
    signal next_state: state;

    signal uart_baud_val: std_logic_vector(15 downto 0);
    
    signal baud_counter_tc:   std_logic;
    signal baud_counter_clr:  std_logic;
    signal baud_counter_en:   std_logic;
    signal baud_counter_mode: std_logic;
    signal baud_counter_val:  std_logic_vector(15 downto 0);
    signal baud_counter_load: std_logic_vector(15 downto 0);
    
    signal rx_counter_tc:   std_logic;
    signal rx_counter_clr:  std_logic;
    signal rx_counter_en:   std_logic;
    signal rx_counter_val:  std_logic_vector(2 downto 0);
    signal rx_counter_load: std_logic_vector(2 downto 0);
    
    signal rx_sipo_clr: std_logic;
    signal rx_sipo_en:  std_logic;
    signal rx_sipo_ser: std_logic;
    signal rx_sipo_val: std_logic_vector(7 downto 0);

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

    fsm_next_state: process(curr_state, wr_en, rx, baud_counter_tc, rx_counter_tc)
    begin
        
        case curr_state is
            
            when START =>
                
                next_state <= IDLE;
        
            when IDLE =>
                
                if wr_en = '1' and rx = '0' then

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

    uart_baud_val <= baud_div;

    baud_counter_load <= '0' & uart_baud_val(15 downto 1) when curr_state = RX_START else uart_baud_val;

    baud_counter_tc   <= '1' when baud_counter_val = x"0000" else '0';

    baud_counter_clr  <= '1' when curr_state = START else '0';

    baud_counter_en   <= '0' when curr_state = START else '1';

    baud_counter_mode <= '1' when curr_state = IDLE or baud_counter_tc = '1' else '0';

    baud_counter: down_counter generic map (
        BITS => 16
    ) port map (
        clk  => clk,
        clr  => baud_counter_clr,
        en   => baud_counter_en,
        mode => baud_counter_mode,
        load => baud_counter_load,
        val  => baud_counter_val
    );

    rx_counter_tc  <= '1' when rx_counter_val = b"000" else '0';

    rx_counter_clr <= '1' when curr_state = START else '0';

    rx_counter_en  <= baud_counter_tc when curr_state = RX_DATA else '0';

    rx_counter: down_counter generic map (
        BITS => 3
    ) port map (
        clk  => clk,
        clr  => rx_counter_clr,
        en   => rx_counter_en,
        mode => '0',
        load => (others => '1'),
        val  => rx_counter_val
    );

    rx_sipo_clr <= '1' when curr_state = START else '0';

    rx_sipo_en  <= baud_counter_tc when curr_state = RX_START or curr_state = RX_DATA else '0';        
    
    rx_sipo_ser <= rx;

    rx_sipo: sipo generic map (
        BITS => 8
    ) port map (
        clk => clk,
        clr => rx_sipo_clr,
        en  => rx_sipo_en,
        ser => rx_sipo_ser,
        val => rx_sipo_val
    );

    wr <= '1' when curr_state = RX_STOP and next_state = IDLE else '0';

    wr_data <= rx_sipo_val;

    busy <= '0' when curr_state = IDLE else '1';
    
end architecture uart_rx_arch;