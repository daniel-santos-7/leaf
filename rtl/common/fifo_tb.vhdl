----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- testbench: fifo
-- description: fifo module tests
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.common_pkg.all;

entity fifo_tb is
end entity fifo_tb;

architecture fifo_tb_arch of fifo_tb is

    signal clk:     std_logic;
    signal reset:   std_logic;
    signal wr:      std_logic;
    signal wr_en:   std_logic;
    signal wr_data: std_logic_vector(7 downto 0);
    signal rd:      std_logic;
    signal rd_en:   std_logic;
    signal rd_data: std_logic_vector(7 downto 0);

begin
    
    uut: fifo generic map(
        SIZE => 4,
        BITS => 8  
    ) port map(
        clk     => clk,
        reset   => reset,
        wr      => wr,
        wr_en   => wr_en,
        wr_data => wr_data,
        rd      => rd,
        rd_en   => rd_en,
        rd_data => rd_data
    );    

    test: process

        constant PERIOD: time := 20 ns;

    begin

        clk   <= '0';
        reset <= '1';
        
        rd <= '0';
        wr <= '0';
        wr_data <= (others => '0');
        
        wait for PERIOD;

        reset <= '0';

        rd <= '0';
        wr      <= '1';
        wr_data <= (others => '1');

        ntick(PERIOD, clk, 4);

        rd <= '1';
        wr <= '0';
        wr_data <= (others => '0');

        ntick(PERIOD, clk, 4);

        wait;

    end process test;
    
end architecture fifo_tb_arch;