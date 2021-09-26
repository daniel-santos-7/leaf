library IEEE;
use IEEE.std_logic_1164.all;
use work.uart_pkg.all;

entity uart_tx_tb is
end entity uart_tx_tb;

architecture uart_tx_tb_arch of uart_tx_tb is

    constant uart_baud: integer := 5208;

    signal clk:     std_logic;
    signal reset:   std_logic;
    signal wr:      std_logic;
    signal wr_data: std_logic_vector(7 downto 0);
    signal wr_en:   std_logic;
    signal tx:      std_logic;

    signal rx_data: std_logic_vector(9 downto 0) := (others => '1');
    
begin

    uut: uart_tx generic map (
        UART_BAUD => uart_baud
    ) port map (
        clk     => clk,
        reset   => reset,
        wr      => wr,
        wr_data => wr_data,
        wr_en   => wr_en,
        tx      => tx
    );
    
    test: process

        constant period: time := 20 ns;

    begin
        
        clk     <= '0';
        reset   <= '1';
        wr      <= '0';
        wr_data <= b"01000001";

        wait for period;
        
        reset <= '0';

        for i in 0 to 2*uart_baud loop
            
            clk <= not clk;
            wait for period/2;

        end loop;

        wr <= '1';

        for i in 0 to 9 loop

            for j in 0 to uart_baud loop
                
                clk <= not clk;
                wait for period/2;

            end loop;

            rx_data(i) <= tx;

            for k in 0 to uart_baud loop
            
                clk <= not clk;
                wait for period/2;

            end loop;

        end loop;

        wr <= '0';

        for i in 0 to 2*uart_baud loop
            
            clk <= not clk;
            wait for period/2;

        end loop;

        assert rx_data = b"1010000010" report "wrong rx data" severity failure;

        wait;

    end process test;
    
end architecture uart_tx_tb_arch;