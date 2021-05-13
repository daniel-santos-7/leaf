library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity if_stage_tb is
end entity if_stage_tb;

architecture if_stage_tb_arch of if_stage_tb is
    
    signal clk: std_logic;
    signal jmp, branch, target_shift: std_logic;
    signal target: std_logic_vector(31 downto 0);
    signal rd_instr_mem_data: std_logic_vector(31 downto 0);
    signal rd_instr_mem_addr: std_logic_vector(31 downto 0);
    signal pc, next_pc: std_logic_vector(31 downto 0);
    signal instr: std_logic_vector(31 downto 0);
    signal no_op: std_logic;

    procedure tick(signal clk: out std_logic) is

    begin
        
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;

    end procedure;

begin
    
    uut: if_stage port map (
        clk,
        jmp,
        branch, 
        target_shift,
        target,
        rd_instr_mem_data,
        rd_instr_mem_addr,
        pc, next_pc,
        instr,
        no_op
    );

    process

    begin

        target <= x"00000010";
        rd_instr_mem_data <= x"002081b3";

        jmp <= '0';        
        branch <= '0';
        target_shift <= '0';

        tick(clk);

        assert rd_instr_mem_addr = x"00000004";
        assert pc = x"00000004";
        assert next_pc = x"00000008";
        assert instr = x"002081b3";
        assert no_op = '0';

        jmp <= '1';        
        branch <= '0';
        target_shift <= '0';

        tick(clk);

        assert rd_instr_mem_addr = x"00000010";
        assert pc = x"00000010";
        assert next_pc = x"00000014";
        assert instr = x"002081b3";
        assert no_op = '1';

        jmp <= '0';        
        branch <= '1';
        target_shift <= '0';

        tick(clk);

        assert rd_instr_mem_addr = x"00000010";
        assert pc = x"00000010";
        assert next_pc = x"00000014";
        assert instr = x"002081b3";
        assert no_op = '1';

        jmp <= '1';        
        branch <= '0';
        target_shift <= '1';

        tick(clk);

        assert rd_instr_mem_addr = x"00000020";
        assert pc = x"00000020";
        assert next_pc = x"00000024";
        assert instr = x"002081b3";
        assert no_op = '1';

        wait;

    end process ;
    
end architecture if_stage_tb_arch;