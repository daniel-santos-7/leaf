library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity alu_ctrl is
    
    port (
        alu_op_en:     in std_logic;
        alu_func_type: in std_logic;
        func3:         in std_logic_vector(2 downto 0);
        func7:         in std_logic_vector(6 downto 0);

        alu_op: out std_logic_vector(5 downto 0)
    );

end entity alu_ctrl;

architecture alu_ctrl_arch of alu_ctrl is
    
begin

    alu_op_ctrl: process(alu_op_en, alu_func_type, func3, func7)

    begin
        
        if alu_op_en = '0' then
            
            alu_op <= ALU_ADD;

        else

            case func3 is
                    
                when b"000" =>
                    
                    if func7 = b"0100000" and alu_func_type = '0' then
                        
                        alu_op <= ALU_SUB;
    
                    else
    
                        alu_op <= ALU_ADD;
    
                    end if;
    
                when b"001" =>
    
                    alu_op <= ALU_SLL;
    
                when b"010" =>
    
                    alu_op <= ALU_SLT;
    
                when b"011" =>
    
                    alu_op <= ALU_SLTU;
    
                when b"100" =>
    
                    alu_op <= ALU_XOR;
                    
                when b"101" =>
    
                    if func7 = b"0100000" then
    
                        alu_op <= ALU_SRA;
    
                    else
    
                        alu_op <= ALU_SRL;
    
                    end if;
    
                when b"110" =>
    
                    alu_op <= ALU_OR;
    
                when b"111" =>
    
                    alu_op <= ALU_AND;
    
                when others =>
                    
                    alu_op <= ALU_ADD;
    
            end case;

        end if;

    end process alu_op_ctrl;
    
end architecture alu_ctrl_arch;