library IEEE;
use IEEE.std_logic_1164.all;

package alu_pkg is
    
    subtype alu_op is std_logic_vector(3 downto 0);

    constant ALU_AND: alu_op := x"1";
    
    constant ALU_OR: alu_op := x"2";
    
    constant ALU_XOR: alu_op := x"3";
    
    constant ALU_SLT: alu_op := x"4";
    
    constant ALU_SLTU: alu_op := x"5";
    
    constant ALU_ADD: alu_op := x"6";
    
    constant ALU_SUB: alu_op := x"7";
    
    constant ALU_SRL: alu_op := x"8";
    
    constant ALU_SLL: alu_op := x"9";
    
    constant ALU_SRA: alu_op := x"A";

    component alu is

        port(
            opd0, opd1: in  std_logic_vector(31 downto 0);
	        op: in alu_op;
	        rslt: out std_logic_vector(31 downto 0);
            zero: out std_logic
        );

    end component;

end package alu_pkg;