library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu is
    port (
        opd0, opd1: in std_logic_vector(31 downto 0);
        op: in std_logic_vector(3 downto 0);
        rst: out std_logic_vector(31 downto 0);
        zero: out std_logic        
    );
end entity alu;

architecture alu_bhv of alu is
    
    signal rst_i: std_logic_vector(31 downto 0);

begin
    
    with op select rst_i <= 
        std_logic_vector(unsigned(opd0) + unsigned(opd1)) when "0000",
        std_logic_vector(unsigned(opd0) - unsigned(opd1)) when "0001",
        opd0 and opd1 when "0010",
        opd0 or opd1 when "0011",
        opd0 xor opd1 when "0100",
        x"0000_0000" when others;

    rst <= rst_i;
    zero <= '1' when (rst_i = x"0000_0000") else '0'; 

end architecture alu_bhv;