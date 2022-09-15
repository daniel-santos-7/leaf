library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity soc_syscon is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        clk_o : out std_logic;
        rst_o : out std_logic
    );
end entity soc_syscon;

architecture rtl of soc_syscon is
    
    signal dly    : std_logic;
    signal in_rst : std_logic;

begin
    
    rst_gen: process(clk)
    begin                                     
        if rising_edge(clk) then
            dly    <= (not rst and dly and not in_rst) or (not rst and not dly and in_rst);
            in_rst <= (not rst and not dly and not in_rst);
        end if;
    end process rst_gen;

    clk_o <= clk;
    rst_o <= rst;

end architecture rtl;