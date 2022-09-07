library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity id_block_tb is 
end id_block_tb;

architecture id_block_tb_arch of id_block_tb is

    signal instr         : std_logic_vector(31 downto 0);
    signal flush         : std_logic;
    signal regs_addr     : std_logic_vector(14 downto 0);
    signal csrs_addr     : std_logic_vector(11 downto 0);
    signal ex_func       : std_logic_vector(9  downto 0);
    signal csrs_mode     : std_logic_vector(2  downto 0);
    signal brde_mode     : std_logic_vector(2  downto 0);
    signal dmls_dtype    : std_logic_vector(2  downto 0);
    signal imm           : std_logic_vector(31 downto 0);
    signal int_strg_ctrl : std_logic_vector(2  downto 0);
    signal ex_ctrl       : std_logic_vector(5  downto 0);
    signal dmls_ctrl     : std_logic_vector(1  downto 0);
    signal brde_ctrl     : std_logic_vector(1  downto 0);
    signal csrs_ctrl     : std_logic;

begin

    uut: id_block port map (
        instr         => instr,
        flush         => flush,
        regs_addr     => regs_addr,
        csrs_addr     => csrs_addr,
        ex_func       => ex_func,
        csrs_mode     => csrs_mode,
        brde_mode     => brde_mode,
        dmls_dtype    => dmls_dtype,
        imm           => imm,
        int_strg_ctrl => int_strg_ctrl,
        ex_ctrl       => ex_ctrl,
        dmls_ctrl     => dmls_ctrl,
        brde_ctrl     => brde_ctrl,
        csrs_ctrl     => csrs_ctrl
    );

    test: process

        constant period: time := 50 ns;

        begin

            instr <= (others => '0');
            flush <= '0';

            wait for period;
            wait;

    end process test;
    
end architecture id_block_tb_arch;