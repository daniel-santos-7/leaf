library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.leaf_soc_pkg.all;

entity soc_syscon_tb is
end entity soc_syscon_tb;

architecture sim of soc_syscon_tb is
    
    constant CLK_PERIOD : time := 20 ns;
    
    signal clk   : std_logic;
    signal rst   : std_logic;
    signal clk_o : std_logic;
    signal rst_o : std_logic;

begin
    
    uut: soc_syscon port map (
        clk   => clk,
        rst   => rst,
        clk_o => clk_o,
        rst_o => rst_o
    );
    
    clk_gen: process
    begin
        clk <= '0';
        for i in 0 to 15 loop
            wait for CLK_PERIOD/2;
            clk <= not clk;
        end loop;
        wait;
    end process clk_gen;

    rst_gen: process
    begin
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';
        wait;
    end process rst_gen;

end architecture sim;