library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity branch_dtct_tb is
end entity branch_dtct_tb;

architecture branch_dtct_tb_arch of branch_dtct_tb is
    
    signal reg0, reg1: std_logic_vector(31 downto 0);
    signal mode: std_logic_vector(2 downto 0);
    signal branch: std_logic;

begin
    
    uut: branch_dtct port map(
        reg0, 
        reg1,
        mode,
        branch
    );

    process
    
        constant period: time := 50 ns;

    begin
        
        reg0 <= x"0000_000F";
        reg1 <= x"0000_000F";
        mode <= b"000";

        wait for period;

        assert (branch = '1');

        reg0 <= x"0000_000A";
        reg1 <= x"0000_000F";
        mode <= b"001";

        wait for period;

        assert (branch = '1');

        reg0 <= x"0000_000A";
        reg1 <= x"0000_000F";
        mode <= b"100";

        wait for period;

        assert (branch = '1');

        reg0 <= x"0000_000F";
        reg1 <= x"0000_000B";
        mode <= b"101";

        wait for period;

        assert (branch = '1');

        wait;

    end process;
    
end architecture branch_dtct_tb_arch;