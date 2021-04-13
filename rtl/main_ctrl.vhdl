library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity main_ctrl is
    
    port (
        opcode: in std_logic_vector(6 downto 0);
        rf_write_en, rf_write_src: out std_logic;
        lsu_mode, lsu_en: out std_logic;
        branch, jal, jalr: out std_logic
    );

end entity main_ctrl;

architecture main_ctrl_arch of main_ctrl is
    
begin

    with opcode select rf_write_en <=
        '1' when LOGIC_ARITH_OPCODE | LOGIC_ARITH_IMM_OPCODE | JALR_OPCODE | LOAD_OPCODE | JAL_OPCODE, 
        '0' when others;

    with opcode select rf_write_src <= 
        '1' when LOAD_OPCODE,
        '0' when others;

    with opcode select lsu_mode <= 
        '1' when STORE_OPCODE,
        '0' when others;
    
    with opcode select lsu_en <= 
        '1' when LOAD_OPCODE | STORE_OPCODE,
        '0' when others;

    with opcode select branch <= 
        '1' when BRANCH_OPCODE,
        '0' when others;

    with opcode select jal <= 
        '1' when JAL_OPCODE,
        '0' when others;

    with opcode select jalr <= 
        '1' when JALR_OPCODE,
        '0' when others;
    
end architecture main_ctrl_arch;