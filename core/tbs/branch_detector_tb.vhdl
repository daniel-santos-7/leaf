library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity branch_detector_tb is
end entity branch_detector_tb;

architecture branch_detector_tb_arch of branch_detector_tb is
    
    signal reg0, reg1: std_logic_vector(31 downto 0) := x"00000000";
    signal mode: std_logic_vector(2 downto 0);
    signal en, branch: std_logic;

begin
    
    uut: branch_detector port map(
        reg0, 
        reg1,
        mode,
        en,
        branch
    );

    process
    
        constant period: time := 5 ns;

    begin
        
        en <= '0';
        
        reg0 <= x"00000001";
        reg1 <= x"00000001";
        mode <= EQ_BD_MODE;

        wait for period;
        assert branch = '0' report "unit disable failure" severity failure;

        en <= '1';

        reg0 <= x"0000000f";
        reg1 <= x"0000000f";
        mode <= EQ_BD_MODE;

        wait for period;
        assert branch = '1' report "equal mode failure" severity failure;

        reg0 <= x"0000000a";
        reg1 <= x"0000000f";
        mode <= NE_BD_MODE;

        wait for period;
        assert branch = '1' report "not equal mode failure" severity failure;

        reg0 <= x"0000000a";
        reg1 <= x"0000000f";
        mode <= LT_BD_MODE;

        wait for period;
        assert branch = '1' report "less mode failure" severity failure;

        reg0 <= x"0000000f";
        reg1 <= x"0000000b";
        mode <= GE_BD_MODE;

        wait for period;
        assert branch = '1' report "greater or equal mode failure" severity failure;

        reg0 <= x"0000000f";
        reg1 <= x"ffff0000";
        mode <= LTU_BD_MODE;
        
        wait for period;
        assert branch = '1' report "less unsigned mode failure" severity failure;

        reg0 <= x"ffff0001";
        reg1 <= x"0000000f";
        mode <= GEU_BD_MODE;
        
        wait for period;
        assert branch = '1' report "greater unsigned mode failure" severity failure;
        
        wait;

    end process;
    
end architecture branch_detector_tb_arch;