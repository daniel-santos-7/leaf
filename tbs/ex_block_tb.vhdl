library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity ex_block_tb is 
end ex_block_tb;

architecture ex_block_tb_arch of ex_block_tb is

    signal opd0_src0:    std_logic_vector(31 downto 0);
    signal opd0_src1:    std_logic_vector(31 downto 0);
    signal opd1_src0:    std_logic_vector(31 downto 0);
    signal opd1_src1:    std_logic_vector(31 downto 0);
    signal opd0_src_sel: std_logic;
    signal opd1_src_sel: std_logic;
    signal opd0_pass:    std_logic;
    signal opd1_pass:    std_logic;
    signal func_type:    std_logic;
    signal op_en:        std_logic;
    signal func3:        std_logic_vector(2  downto 0);
    signal func7:        std_logic_vector(6  downto 0);
    signal res:          std_logic_vector(31 downto 0);

begin
    
    uut: ex_block port map (
        opd0_src0    => opd0_src0,
        opd0_src1    => opd0_src1,
        opd1_src0    => opd1_src0,
        opd1_src1    => opd1_src1,
        opd0_src_sel => opd0_src_sel,
        opd1_src_sel => opd1_src_sel,
        opd0_pass    => opd0_pass,
        opd1_pass    => opd1_pass,
        func_type    => func_type,
        op_en        => op_en,
        func3        => func3,
        func7        => func7,
        res          => res
    );

    test: process

        constant period: time := 50 ns;

        begin

            opd0_src0    <= (others => '0');
            opd0_src1    <= (others => '0');
            opd1_src0    <= (others => '0');
            opd1_src1    <= (others => '0');
            opd0_src_sel <= '0';
            opd1_src_sel <= '0';
            opd0_pass    <= '0';
            opd1_pass    <= '0';
            func_type    <= '0';
            func3        <= (others => '0');
            func7        <= (others => '0');

            wait for period;

            wait;

    end process test;
    
end architecture ex_block_tb_arch;