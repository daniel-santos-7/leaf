library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity id_ex_stage_tb is
end entity id_ex_stage_tb;

architecture id_ex_stage_tb_arch of id_ex_stage_tb is
    
    signal clk, branch, jal, jalr, rd_mem_en, wr_mem_en: std_logic;
    signal pc, next_pc, instr, target, rd_mem_data, wr_mem_data: std_logic_vector(31 downto 0);

begin
    
    uut: id_ex_stage port map (
        clk,
        pc,
        next_pc,
        instr,
        rd_mem_data,
        rd_mem_en,
        wr_mem_data,
        wr_mem_en,
        branch, jal, jalr,
        target
    );

    process

        constant half_period: time := 50 ns;

    begin

        pc <= x"0000_0000";
        next_pc <= x"0000_0004";
        instr <= b"000010010110_00000_000_00001_0010011";   -- addi x1, x0, 150

        clk <= '0';
        wait for half_period;
        clk <= '1';
        wait for half_period;

        pc <= x"0000_0004";
        next_pc <= x"0000_0008";
        instr <= b"001111101000_00000_000_00010_0010011";   -- addi x2, x0, 1000
                   
        clk <= '0';
        wait for half_period;
        clk <= '1';
        wait for half_period;

        pc <= x"0000_0008";
        next_pc <= x"0000_000C";
        instr <= b"0000000_00010_00001_000_00011_0110011";   -- add x3, x2, x1
                   
        clk <= '0';
        wait for half_period;
        clk <= '1';
        wait for half_period;

        wait;

    end process;
    
end architecture id_ex_stage_tb_arch;