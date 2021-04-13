library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity branch_dtct is
    
    port (
        reg0, reg1: in std_logic_vector(31 downto 0);
        mode: in std_logic_vector(2 downto 0);
        branch: out std_logic
    );

end entity branch_dtct;

architecture branch_dtct_arch of branch_dtct is
    
    signal equals, less, less_unsigned: std_logic;

begin
    
    equals <= '1' when reg0 = reg1 else '0';

    less <= '1' when signed(reg0) < signed(reg1) else '0';

    less_unsigned <= '1' when unsigned(reg0) < unsigned(reg1) else '0';

    with mode select branch <=
    
        equals                          when b"000",

        not(equals)                     when b"001",

        less                            when b"100",

        not(less) or equals             when b"101",

        less_unsigned                   when b"110",

        not(less_unsigned) or equals    when b"111",

        '0'                             when others;    
    
end architecture branch_dtct_arch;