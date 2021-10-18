library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.uart_pkg.all;

entity uart_tb is
end entity uart_tb;

architecture uart_arch of uart_tb is

    signal clk:     std_logic;
    signal reset:   std_logic;
    signal rd:      std_logic;
    signal rd_addr: std_logic_vector(1 downto 0);
    signal rd_data: std_logic_vector(15 downto 0);
    signal wr:      std_logic;
    signal wr_addr: std_logic_vector(1 downto 0);
    signal wr_data: std_logic_vector(15 downto 0);
    signal rx:      std_logic;
    signal tx:      std_logic;

begin

    rx <= tx;

    uut: uart port map(
        clk     => clk,
        reset   => reset,
        rd      => rd,
        rd_addr => rd_addr,
        rd_data => rd_data,
        wr      => wr,
        wr_addr => wr_addr,
        wr_data => wr_data,
        rx      => rx,
        tx      => tx
    );

    test: process

        constant PERIOD: time := 20 ns;
        constant UART_BAUD: natural := 5208;

    begin
        
        clk     <= '0';
        reset   <= '1';
        rd      <= '0';
        wr      <= '0';
        rd_addr <= (others => '0');
        wr_addr <= (others => '0');
        wr_data <= (others => '0');

        wait for PERIOD;

        clk <= not clk;
        wait for PERIOD/2;
        
        clk <= not clk;
        wait for PERIOD/2;

        reset   <= '0';
        rd      <= '0';
        wr      <= '1';
        wr_addr <= b"10";
        wr_data <= x"1458";

        clk <= not clk;
        wait for PERIOD/2;
        
        clk <= not clk;
        wait for PERIOD/2;

        wr_addr <= b"11";
        wr_data <= x"0041";

        clk <= not clk;
        wait for PERIOD/2;
        
        clk <= not clk;
        wait for PERIOD/2;

        wr <= '0';

        clk <= not clk;
        wait for PERIOD/2;
        
        clk <= not clk;
        wait for PERIOD/2;

        for i in 0 to 20*UART_BAUD loop
            
            clk <= not clk;
            wait for PERIOD/2;
        
        end loop;

        wait;
        
    end process test;
    
end architecture uart_arch;