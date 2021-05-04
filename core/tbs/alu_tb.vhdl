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

            opd0 <= x"00000226";
            opd1 <= x"0000015e";
            
            op <= ALU_ADD;
            wait for period;
            assert rslt = x"00000384";

            op <= ALU_SUB;
            wait for period;
            assert rslt = x"000000c8";

            opd0 <= x"fffffdbd";
            opd1 <= x"000004bd";

            op <= ALU_AND;
            wait for period;
            assert rslt = x"000004bd";

            op <= ALU_OR;
            wait for period;
            assert rslt = x"fffffdbd";

            op <= ALU_XOR;
            wait for period;
            assert rslt = x"fffff900";

            opd0 <= x"000000c8";
            opd1 <= x"fffffe0c";

            op <= ALU_SLT;
            wait for period;
            assert rslt = x"00000000";

            op <= ALU_SLTU;
            wait for period;
            assert rslt = x"00000001";

            opd0 <= x"00000005";
            opd1 <= x"00000021";

            op <= ALU_SLL;
            wait for period;
            assert rslt = x"0000000a";

            op <= ALU_SRL;
            wait for period;
            assert rslt = x"00000002";

            opd0 <= x"00000006";
            opd1 <= x"00000003";
            
            op <= ALU_SRA;
            wait for period;
            assert rslt = x"00000000";

            wait;

    end process;
    
end architecture alu_tb_arch;