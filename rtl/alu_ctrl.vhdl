library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity alu_ctrl is

    port (
        opcode: in std_logic_vector(6 downto 0);
        func3: in std_logic_vector(2 downto 0);
        func7: in std_logic_vector(6 downto 0);
        alu_src0, alu_src1: out std_logic;
        alu_op: out std_logic_vector(3 downto 0)
    );

end entity alu_ctrl;

architecture alu_ctrl_arch of alu_ctrl is
    
begin

    alu_src0 <= '1' when opcode = JALR_OPCODE or opcode = BRANCH_OPCODE or opcode = JAL_OPCODE else '0'; 

    alu_src1 <= '0' when opcode = LOGIC_ARITH_OPCODE else '1';

    alu_op <= 
    
        ALU_ADD when (opcode = LOGIC_ARITH_OPCODE and func3 = b"000" and func7 = b"0000000") or
                     (opcode = LOGIC_ARITH_IMM_OPCODE and func3 = b"000") else
        
        ALU_SLL when (opcode = LOGIC_ARITH_OPCODE and func3 = b"001" and func7 = b"0000000") or
                     (opcode = LOGIC_ARITH_IMM_OPCODE and func3 = b"001") else

        ALU_SLT when (opcode = LOGIC_ARITH_OPCODE and func3 = b"010" and func7 = b"0000000") or
                     (opcode = LOGIC_ARITH_IMM_OPCODE and func3 = b"010") else
    
        ALU_SLTU when (opcode = LOGIC_ARITH_OPCODE and func3 = b"011" and func7 = b"0000000") or
                      (opcode = LOGIC_ARITH_IMM_OPCODE and func3 = b"011") else
        
        ALU_XOR when (opcode = LOGIC_ARITH_OPCODE and func3 = b"100" and func7 = b"0000000") or
                     (opcode = LOGIC_ARITH_IMM_OPCODE and func3 = b"100") else

        ALU_SRL when (opcode = LOGIC_ARITH_OPCODE and func3 = b"101" and func7 = b"0000000") or
                     (opcode = LOGIC_ARITH_IMM_OPCODE and func3 = b"101") else

        ALU_OR when  (opcode = LOGIC_ARITH_OPCODE and func3 = b"110" and func7 = b"0000000") or
                     (opcode = LOGIC_ARITH_IMM_OPCODE and func3 = b"110") else

        ALU_AND when (opcode = LOGIC_ARITH_OPCODE and func3 = b"111" and func7 = b"0000000") or
                     (opcode = LOGIC_ARITH_IMM_OPCODE and func3 = b"111") else

        ALU_SUB when (opcode = LOGIC_ARITH_OPCODE and func3 = b"000" and func7 = b"0100000") or
                     (opcode = LOGIC_ARITH_IMM_OPCODE and func3 = b"000") else

        ALU_SRA when (opcode = LOGIC_ARITH_OPCODE and func3 = b"101" and func7 = b"0100000") or
                     (opcode = LOGIC_ARITH_IMM_OPCODE and func3 = b"101") else

        ALU_ADD;
        
end architecture alu_ctrl_arch;