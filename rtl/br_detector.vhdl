library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;

entity br_detector is
    port (
        reg0:   in  std_logic_vector(31 downto 0); 
        reg1:   in  std_logic_vector(31 downto 0);
        mode:   in  std_logic_vector(2  downto 0);
        en:     in  std_logic;
        branch: out std_logic
    );
end entity br_detector;

architecture br_detector_arch of br_detector is
    
    signal equal:         std_logic;
    signal less:          std_logic;
    signal less_unsigned: std_logic;
    signal branch_i:      std_logic;

begin
    
    equal <= '1' when reg0 = reg1 else '0';
    
    less <= '1' when signed(reg0) < signed(reg1) else '0';
    
    less_unsigned <= '1' when unsigned(reg0) < unsigned(reg1) else '0';

    exec: process(mode, equal, less, less_unsigned)
    begin
        
        case mode is
            when EQ_BD_MODE  => branch_i <= equal;
            when NE_BD_MODE  => branch_i <= not(equal);
            when LT_BD_MODE  => branch_i <= less;
            when GE_BD_MODE  => branch_i <= not(less) or equal;
            when LTU_BD_MODE => branch_i <= less_unsigned;
            when GEU_BD_MODE => branch_i <= not(less_unsigned) or equal;
            when others      => branch_i <= '0';
        end case;

    end process exec;

    branch <= branch_i and en;

end architecture br_detector_arch;