library IEEE;
use IEEE.std_logic_1164.all;

entity syscon is
    generic (
        CLK_PERIOD : time := 20 ns
    );
    port (
        halt  : in  std_logic;
        clk_o : out std_logic;
        rst_o : out std_logic
    );
end entity syscon;

architecture rtl of syscon is
    
    signal clk : std_logic;

begin
    
    clk <= not clk after (CLK_PERIOD/2) when halt = '0' else '0';

    clk_o <= clk;
    rst_o <= '1', '0' after CLK_PERIOD;

end architecture rtl;