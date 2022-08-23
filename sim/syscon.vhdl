library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity syscon is
    generic (
        CLK_PERIOD : time := 20 ns
    );
    port (
        halt_i : in  std_logic;
        clk_o  : out std_logic;
        rst_o  : out std_logic
    );
end entity syscon;

architecture syscon_arch of syscon is
    
    signal clk : std_logic := '0';

begin
    
    clk <= not clk after (CLK_PERIOD/2) when halt_i = '0' else '0';

    clk_o <= clk;
    rst_o <= '1', '0' after CLK_PERIOD;

end architecture syscon_arch;