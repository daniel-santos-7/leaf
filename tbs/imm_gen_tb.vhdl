library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity imm_gen_tb is 
end imm_gen_tb;

architecture imm_gen_tb_arch of imm_gen_tb is

    signal instr, imm: std_logic_vector(31 downto 0);

begin
    
    uut: imm_gen port map (instr, imm);

    process

        constant period: time := 50 ns;

        begin

            instr <= b"000000000010_00000_000_00001_0010011";
            wait for period;
            assert imm = x"0000_0002";

            instr <= b"0000001_00001_00000_010_00001_0100011";
            wait for period;
            assert imm = x"0000_0021";

            wait;

    end process;
    
end architecture imm_gen_tb_arch;