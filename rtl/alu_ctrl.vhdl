library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity alu_ctrl is

    port (
        std_op: in std_logic;
        imm_op: in std_logic;
        func: in std_logic_vector(9 downto 0);
        alu_op: out std_logic_vector(3 downto 0)
    );

end entity alu_ctrl;

architecture alu_ctrl_arch of alu_ctrl is

begin

    ctrl: process(std_op, imm_op, func)
        
        variable shift_op: boolean;

    begin
    
        shift_op := func = ALU_CTRL_SLL or func = ALU_CTRL_SRL or func = ALU_CTRL_SRA;

        if std_op = '0' and shift_op then
                
            alu_op <= func(8) & func(2 downto 0);

        elsif std_op = '0' then

            alu_op <= (func(8) and not imm_op) & func(2 downto 0);

        else

            alu_op <= ALU_ADD;

        end if;

    end process ctrl;

end architecture alu_ctrl_arch;