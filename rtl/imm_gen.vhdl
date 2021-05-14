library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.core_pkg.all;

entity imm_gen is
    
    port (
        instr_payload: in std_logic_vector(24 downto 0);
        imm_type: in std_logic_vector(2 downto 0);
        imm: out std_logic_vector(31 downto 0)
    );

end entity imm_gen;

architecture imm_gen_arch of imm_gen is
    
    function resize_signed(value: in std_logic_vector) return std_logic_vector is

    begin

        return std_logic_vector(resize(signed(value), 32));

    end function resize_signed;

begin
    
    with imm_type select imm <=

        resize_signed(instr_payload(24 downto 13))                                                                              when IMM_I_TYPE,

        resize_signed(instr_payload(24 downto 18) & instr_payload(4 downto 0))                                                  when IMM_S_TYPE,

        resize_signed(instr_payload(24) & instr_payload(0) & instr_payload(23 downto 18) & instr_payload(4 downto 1) & '0')     when IMM_B_TYPE,

        instr_payload(24 downto 5) & (11 downto 0 => '0')                                                                       when IMM_U_TYPE,

        resize_signed(instr_payload(24) & instr_payload(12 downto 5) & instr_payload(13) & instr_payload(23 downto 14) & '0')   when IMM_J_TYPE,
        
        (31 downto 0 => '-')                                                                                                    when others;
    
end architecture imm_gen_arch;