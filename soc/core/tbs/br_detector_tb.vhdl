library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity br_detector_tb is
end entity br_detector_tb;

architecture br_detector_tb_arch of br_detector_tb is
    
    signal reg0: std_logic_vector(31 downto 0);
    signal reg1: std_logic_vector(31 downto 0);
    signal mode: std_logic_vector(2  downto 0);
    signal en:     std_logic;
    signal branch: std_logic;

begin
    
    uut: br_detector port map(
        reg0   => reg0, 
        reg1   => reg1,
        mode   => mode,
        en     => en,
        branch => branch
    );

    process
    
        constant period: time := 50 ns;

    begin

        -- setup --
    
        reg0 <= x"00000000";
        reg1 <= x"00000000";
        
        -- disable mode --

        en <= '0';
        
        reg0 <= x"00000001";
        reg1 <= x"00000001";
        mode <= EQ_BD_MODE;

        wait for period;

        assert branch = '0';

        -- enable mode --

        en <= '1';

        -- equal mode --

        reg0 <= x"0000000f";
        reg1 <= x"0000000f";
        mode <= EQ_BD_MODE;

        wait for period;

        assert branch = '1';

        -- not equal mode --

        reg0 <= x"0000000A";
        reg1 <= x"0000000F";
        mode <= NE_BD_MODE;

        wait for period;
        
        assert branch = '1';

        -- less than mode --

        reg0 <= x"0000000A";
        reg1 <= x"0000000F";
        mode <= LT_BD_MODE;

        wait for period;
        
        assert branch = '1';

        -- greater or equal mode --

        reg0 <= x"0000000F";
        reg1 <= x"0000000B";
        mode <= GE_BD_MODE;

        wait for period;

        assert branch = '1';

        -- less unsigned mode --

        reg0 <= x"0000000F";
        reg1 <= x"ffff0000";
        mode <= LTU_BD_MODE;
        
        wait for period;

        assert branch = '1';

        -- greater unsigned mode --
        
        reg0 <= x"FFFF0001";
        reg1 <= x"0000000F";
        mode <= GEU_BD_MODE;
        
        wait for period;

        assert branch = '1';
        
        wait;

    end process;
    
end architecture br_detector_tb_arch;