library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity alu_ctrl is

    port (
        opcode: in std_logic_vector(6 downto 0);
        func3: in std_logic_vector(2 downto 0);
        func7: in std_logic_vector(6 downto 0);
        alu_src0, alu_src1: in std_logic;
        alu_op: out std_logic_vector(3 downto 0)
    );

end entity alu_ctrl;

architecture alu_ctrl_arch of alu_ctrl is
    
begin

    process(opcode, func3, func7)
    
    begin

        if (opcode = "0110011" and func7 = "0000000") or (opcode = "0010011") then

            case func3 is
                
                when "000" => alu_op <= ALU_ADD;

                when "001" => alu_op <= ALU_SLL;

                when "010" => alu_op <= ALU_SLT;

                when "011" => alu_op <= ALU_SLTU;

                when "100" => alu_op <= ALU_XOR;

                when "101" => alu_op <= ALU_SRL;

                when "110" => alu_op <= ALU_OR;

                when "111" => alu_op <= ALU_AND;

                when others => null;
                    
            end case;
        
        elsif (opcode = "0110011" and func7 = "0100000") then

            case func3 is
                    
                when "000" => alu_op <= ALU_SUB;

                when "101" => alu_op <= ALU_SRA;

                when others => null;
                    
            end case;

        end if;
        
    end process;
    
end architecture alu_ctrl_arch;