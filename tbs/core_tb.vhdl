library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity core_tb is
end entity core_tb;

architecture core_tb_arch of core_tb is
    
    signal clk, rd_mem_en, wr_mem_en: std_logic;
    signal instr_mem_addr, instr_mem_data, rd_mem_data, wr_mem_data: std_logic_vector(31 downto 0);

begin
    
    uut: core port map (
        clk,
        instr_mem_addr,
        instr_mem_data,
        rd_mem_data,
        rd_mem_en,
        wr_mem_data,
        wr_mem_en
    );

    process

        constant half_period: time := 50 ns;

    begin

        instr_mem_data <= b"000010010110_00000_000_00001_0010011";   -- addi x1, x0, 150

        clk <= '0';
        wait for half_period;
        clk <= '1';
        wait for half_period;

        instr_mem_data <= b"001111101000_00000_000_00010_0010011";   -- addi x2, x0, 1000
                   
        clk <= '0';
        wait for half_period;
        clk <= '1';
        wait for half_period;

        instr_mem_data <= b"0000000_00010_00001_000_00011_0110011";   -- add x3, x2, x1
                   
        clk <= '0';
        wait for half_period;
        clk <= '1';
        wait for half_period;

        clk <= '0';
        wait for half_period;
        clk <= '1';
        wait for half_period;

        wait;

    end process;
    
end architecture core_tb_arch;