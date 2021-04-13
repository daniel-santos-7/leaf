library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity alu_tb is 
end alu_tb;

architecture alu_tb_arch of alu_tb is

    signal opd0, opd1, rslt: std_logic_vector(31 downto 0);
    signal op : std_logic_vector(3 downto 0);

begin
    
    uut: alu port map (opd0, opd1, op, rslt);

    process

        constant period: time := 10 ns;

        begin

            opd0 <= x"0001_2CD7";
            opd1 <= x"0000_04EC";
            op <= ALU_ADD;
            wait for period;
            assert (rslt = x"0001_31C3") ;

            opd0 <= x"0A05_1AB1";
            opd1 <= x"010B_A1D0";
            op <= ALU_SUB;
            wait for period;
            assert (rslt = x"08F9_78E1");

            opd0 <= x"AF15_AAC1";
            opd1 <= x"F1FC_B1C1";
            op <= ALU_AND;
            wait for period;
            assert (rslt = x"A114_A0C1") ;

            opd0 <= x"A765_15C1";
            opd1 <= x"F10C_C121";
            op <= ALU_OR;
            wait for period;
            assert (rslt = x"F76D_D5E1");


            opd0 <= x"B165_9001";
            opd1 <= x"F75C_1101";
            op <= ALU_XOR;
            wait for period;
            assert (rslt = x"4639_8100"); 

            wait;

    end process;
    
end architecture alu_tb_arch;