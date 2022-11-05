----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: immediate value generator
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;

entity imm_gen is
    port (
        payload : in  std_logic_vector(24 downto 0);
        itype   : in  std_logic_vector(2  downto 0);
        imm     : out std_logic_vector(31 downto 0)
    );
end entity imm_gen;

architecture imm_gen_arch of imm_gen is
    
    function resize_signed(value: in std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(resize(signed(value), 32));
    end function resize_signed;

begin

    gen: process(itype, payload)
    begin
        case itype is
            when IMM_I_TYPE => imm <= resize_signed(payload(24 downto 13));
            when IMM_S_TYPE => imm <= resize_signed(payload(24 downto 18) & payload(4 downto 0));
            when IMM_B_TYPE => imm <= resize_signed(payload(24) & payload(0) & payload(23 downto 18) & payload(4 downto 1) & '0');
            when IMM_U_TYPE => imm <= payload(24 downto 5) & (11 downto 0 => '0');
            when IMM_J_TYPE => imm <= resize_signed(payload(24) & payload(12 downto 5) & payload(13) & payload(23 downto 14) & '0');
            when IMM_Z_TYPE => imm <= std_logic_vector(resize(unsigned(payload(19 downto 15)), 32));
            when others     => imm <= (31 downto 0 => '-');
        end case;
    end process gen;
    
end architecture imm_gen_arch;