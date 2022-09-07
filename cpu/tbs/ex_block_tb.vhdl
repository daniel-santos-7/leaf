library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity ex_block_tb is 
end ex_block_tb;

architecture ex_block_tb_arch of ex_block_tb is

    signal opd0_src0: std_logic_vector(31 downto 0);
    signal opd0_src1: std_logic_vector(31 downto 0);
    signal opd1_src0: std_logic_vector(31 downto 0);
    signal opd1_src1: std_logic_vector(31 downto 0);
    signal ex_ctrl:   std_logic_vector(5  downto 0);
    signal ex_func:   std_logic_vector(9  downto 0);
    signal res:       std_logic_vector(31 downto 0);

begin
    
    uut: ex_block port map (
        opd0_src0 => opd0_src0,
        opd0_src1 => opd0_src1,
        opd1_src0 => opd1_src0,
        opd1_src1 => opd1_src1,
        ex_ctrl   => ex_ctrl,
        ex_func   => ex_func,
        res       => res
    );

    test: process

        constant period: time := 50 ns;

        begin

            opd0_src0 <= (others => '0');
            opd0_src1 <= (others => '0');
            opd1_src0 <= (others => '0');
            opd1_src1 <= (others => '0');
            ex_ctrl   <= (others => '0');
            ex_func   <= (others => '0');

            wait for period;
            wait;

    end process test;
    
end architecture ex_block_tb_arch;