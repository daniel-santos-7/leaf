library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity alu_ctrl is

    port (
        la_op: in std_logic;
        imm_op: in std_logic;
        func: in std_logic_vector(9 downto 0);
        alu_op: out std_logic_vector(3 downto 0)
    );

end entity alu_ctrl;

architecture alu_ctrl_arch of alu_ctrl is
    
begin

    alu_op <= ALU_ADD when la_op = '0' else (func(8) and not(imm_op)) & func(2 downto 0);

end architecture alu_ctrl_arch;