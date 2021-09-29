library IEEE;
use IEEE.std_logic_1164.all;
use work.uart_pkg.all;

entity uart_rx_tb is
end entity uart_rx_tb;

architecture uart_rx_tb_arch of uart_rx_tb is

    constant uart_baud: integer := 5208;

    signal clk:     std_logic;
    signal reset:   std_logic;
    signal rx:      std_logic;
    signal rd_data: std_logic_vector(7 downto 0);
    signal rd_en:   std_logic;

begin
    
    uut: uart_rx generic map(
        UART_BAUD => uart_baud
    ) port map(
        clk     => clk,
        reset   => reset,
        rx      => rx,
        rd_data => rd_data,
        rd_en   => rd_en
    );

    test: process

        constant period: time := 20 ns;

        constant tx_data: std_logic_vector(9 downto 0) := b"1010000010";

    begin
        
        clk     <= '0';
        reset   <= '1';
        rx      <= '1';

        wait for period;

        reset <= '0';

        for i in 0 to 2*uart_baud loop
                
            clk <= not clk;
            wait for period/2;

        end loop;

        for i in 0 to 9 loop

            rx <= tx_data(i);

            for j in 0 to 2*uart_baud loop
                
                clk <= not clk;
                wait for period/2;

            end loop;

        end loop;

        rx <= '1';

        for i in 0 to 2*uart_baud loop
            
            clk <= not clk;
            wait for period/2;

        end loop;

        assert rd_data = b"01000001" report "wrong rx data" severity failure;

        wait;

    end process test;

end architecture uart_rx_tb_arch;