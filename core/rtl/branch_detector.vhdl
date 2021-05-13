library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.core_pkg.all;

entity branch_detector is
    
    port (
        reg0, reg1: in std_logic_vector(31 downto 0);
        mode: in std_logic_vector(2 downto 0);
        en: in std_logic;
        branch: out std_logic
    );

end entity branch_detector;

architecture branch_detector_arch of branch_detector is
    
    signal equal, less, less_unsigned, branch_i: std_logic;

begin
    
    equal <= '1' when reg0 = reg1 else '0';

    less <= '1' when signed(reg0) < signed(reg1) else '0';

    less_unsigned <= '1' when unsigned(reg0) < unsigned(reg1) else '0';

    with mode select branch_i <=
    
        equal                          when EQ_BD_MODE,

        not(equal)                     when NE_BD_MODE,

        less                           when LT_BD_MODE,

        not(less) or equal             when GE_BD_MODE,

        less_unsigned                  when LTU_BD_MODE,

        not(less_unsigned) or equal    when GEU_BD_MODE,

        '0'                            when others;    
    
    branch <= branch_i and en;

end architecture branch_detector_arch;