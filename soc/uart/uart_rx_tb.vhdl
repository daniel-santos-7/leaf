library IEEE;
use IEEE.std_logic_1164.all;
use work.leaf_chip_pkg.all;

entity uart_rx_tb is
end entity uart_rx_tb;

architecture uart_rx_tb_arch of uart_rx_tb is

    signal clk:     std_logic;
    signal reset:   std_logic;
    signal rd_data: std_logic_vector(7 downto 0);
    signal rd_en:   std_logic;
    signal rx:      std_logic;

    signal sim_started:  boolean;
    signal sim_finished: boolean;

    -- f_clk = 50 MHz --

    constant period: time := 20 ns;
    
    -- uart_baud = 50 Mhz/9600 bauds

    constant uart_baud: integer := 5208;

    constant uart_period: time := uart_baud*period;
    
begin
    
    uut: uart_rx generic map(
        UART_BAUD => uart_baud
    ) port map(
        clk     => clk,
        reset   => reset,
        rd_data => rd_data,
        rd_en   => rd_en,
        rx      => rx
    );

    sim_started <= false, true after period;

    reset <= '1' when not sim_started else '0';

    clk <= not clk after period/2 when sim_started and not sim_finished else '0';

    send_data: process

        constant data: std_logic_vector(7 downto 0) := b"01000001";

    begin

        rx <= '1';
        wait until rd_en = '1';

        rx <= '0';
        wait for uart_period;

        for i in 0 to 7 loop
            
            rx <= data(i);
            wait for uart_period;

        end loop;

        rx <= '1';
        wait for uart_period;

        sim_finished <= true;
        
    end process send_data;

end architecture uart_rx_tb_arch;