library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.core_pkg.all;

entity imm_gen is
    
    port (
        instr: in std_logic_vector(31 downto 0);
        imm: out std_logic_vector(31 downto 0)   
    );

end entity imm_gen;

architecture imm_gen_arch of imm_gen is
    
    signal opcode: std_logic_vector(6 downto 0);

begin
    
    opcode <= instr(6 downto 0);

    with opcode select imm <=

        std_logic_vector(resize(signed(instr(31 downto 20)), 32))                                           when LOGIC_ARITH_IMM_OPCODE | JALR_OPCODE | LOAD_OPCODE,

        std_logic_vector(resize(signed(instr(31 downto 25) & instr(11 downto 7)), 32))                      when STORE_OPCODE,

        std_logic_vector(resize(signed(instr(7) & instr(30 downto 25) & instr(11 downto 8) & '0'), 32))     when BRANCH_OPCODE,

        std_logic_vector(resize(signed(instr(31 downto 12) & (11 downto 0 => '0')), 32))                    when LOAD_UPPER_IMM_OPCODE | ADD_UPPER_IMM_PC_OPCODE,

        std_logic_vector(resize(signed(instr(19 downto 12) & instr(20) & instr(30 downto 21) & '0'), 32))   when JAL_OPCODE,
        
        (31 downto 0 => '0')                                                                                when others;
    
end architecture imm_gen_arch;