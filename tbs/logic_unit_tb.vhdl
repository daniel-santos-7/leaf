library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity logic_unit_tb is 
end logic_unit_tb;

architecture logic_unit_tb_arch of logic_unit_tb is

    signal opd0: std_logic_vector(31 downto 0);
    signal opd1: std_logic_vector(31 downto 0);
    signal op:   std_logic_vector(1  downto 0);
    signal res:  std_logic_vector(31 downto 0);

begin
    
    uut: logic_unit port map (
        opd0 => opd0, 
        opd1 => opd1, 
        op   => op, 
        res  => res
    );

    test: process

        constant period: time := 50 ns;

        begin

            -- XOR operation --

            opd0 <= x"FFFFFC5E";
            opd1 <= x"00000546";
            op   <= b"00";

            wait for period;
            assert res = x"FFFFF918";

            -- OR operation --

            opd0 <= x"00000082";
            opd1 <= x"0000015E";
            op   <= b"01";

            wait for period;
            assert res = x"000001DE";

            -- AND operation --

            opd0 <= x"FFFFFDBD";
            opd1 <= x"000004BD";
            op   <= b"10";

            wait for period;
            assert res = x"000004BD";

            wait;

    end process test;
    
end architecture logic_unit_tb_arch;