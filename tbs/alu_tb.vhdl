library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity alu_tb is 
end alu_tb;

architecture alu_tb_arch of alu_tb is

    signal opd0, opd1, res: std_logic_vector(31 downto 0);
    signal op : std_logic_vector(3 downto 0);

begin
    
    uut: alu port map (opd0, opd1, op, res);

    process

        constant period: time := 50 ns;

        begin

            opd0 <= x"00000226";
            opd1 <= x"0000015E";
            op <= ALU_ADD;

            wait for period;
            assert res = x"00000384";

            opd0 <= x"00000064";
            opd1 <= x"0000007d";
            op <= ALU_SUB;

            wait for period;
            assert res = x"FFFFFFE7";

            opd0 <= x"FFFFFDBD";
            opd1 <= x"000004BD";
            op <= ALU_AND;

            wait for period;
            assert res = x"000004BD";

            opd0 <= x"00000082";
            opd1 <= x"0000015E";
            op <= ALU_OR;

            wait for period;
            assert res = x"000001DE";

            opd0 <= x"FFFFFC5E";
            opd1 <= x"00000546";
            op <= ALU_XOR;

            wait for period;
            assert res = x"FFFFF918";

            opd0 <= x"000000C8";
            opd1 <= x"FFFFFE0C";
            op <= ALU_SLT;

            wait for period;
            assert res = x"00000000";

            opd0 <= x"000000C8";
            opd1 <= x"FFFFFE0C";
            op <= ALU_SLTU;

            wait for period;
            assert res = x"00000001";

            opd0 <= x"00000005";
            opd1 <= x"00000021";
            op <= ALU_SLL;

            wait for period;
            assert res = x"0000000A";

            opd0 <= x"FFFFFFFE";
            opd1 <= x"00000003";
            op <= ALU_SRL;

            wait for period;
            assert res = x"1FFFFFFF";

            opd0 <= x"FFFFFFF7";
            opd1 <= x"00000409";
            op <= ALU_SRA;

            wait for period;
            assert res = x"FFFFFFFF";

            wait;

    end process;
    
end architecture alu_tb_arch;