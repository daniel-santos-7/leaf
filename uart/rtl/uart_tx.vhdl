library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.uart_pkg.all;

entity uart_tx is
    port (
        clk:      in  std_logic;
        reset:    in  std_logic;
        baud_div: in  std_logic_vector(15 downto 0);
        rd:       out std_logic;
        rd_en:    in  std_logic;
        rd_data:  in  std_logic_vector(7 downto 0);
        busy:     out std_logic;
        tx:       out std_logic
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
    signal baud_counter_val:  std_logic_vector(15 downto 0);
    signal baud_counter_load: std_logic_vector(15 downto 0);

    signal tx_counter_tc:   std_logic;
    signal tx_counter_clr:  std_logic;
    signal tx_counter_en:   std_logic;
    signal tx_counter_val:  std_logic_vector(2 downto 0);
    signal tx_counter_load: std_logic_vector(2 downto 0);

    signal tx_piso_clr:  std_logic;
    signal tx_piso_en:   std_logic;
    signal tx_piso_mode: std_logic;
    signal tx_piso_ser:  std_logic;
    signal tx_piso_load: std_logic_vector(7 downto 0);

    signal tx_bit: std_logic;

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

    fsm_next_state: process(curr_state, rd_en, baud_counter_tc, tx_counter_tc)
    begin
        
        case curr_state is
            
            when START =>
                
                next_state <= IDLE;
        
            when IDLE =>
                
                if rd_en = '1' then
                    
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

    baud_counter_load <= baud_div;

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

    tx_counter_tc  <= '1' when tx_counter_val = b"000" else '0';

    tx_counter_clr <= '1' when curr_state = START else '0';

    tx_counter_en  <= baud_counter_tc when curr_state = TX_DATA else '0';

    tx_counter: down_counter generic map (
        BITS => 3
    ) port map (
        clk  => clk,
        clr  => tx_counter_clr,
        en   => tx_counter_en,
        mode => '0',
        load => (others => '1'),
        val  => tx_counter_val
    );

    tx_piso_clr <= '1' when curr_state = START else '0';

    tx_piso_en  <= baud_counter_tc when curr_state = TX_START or curr_state = TX_DATA else '0';

    tx_piso_mode <= '1' when curr_state = TX_START else '0';

    tx_piso_load <= rd_data;

    tx_piso: piso generic map (
        BITS => 8
    ) port map (
        clk  => clk,
        clr  => tx_piso_clr,
        en   => tx_piso_en,
        mode => tx_piso_mode,
        load => tx_piso_load,
        ser  => tx_piso_ser
    );

    rd <= '1' when curr_state = IDLE and next_state = TX_START else '0';

    tx_bit <= '0' when curr_state = TX_START else '1';

    tx <= tx_piso_ser when curr_state = TX_DATA else tx_bit;

    busy <= '0' when curr_state = IDLE else '1';

end architecture uart_tx_arch;