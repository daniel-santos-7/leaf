library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity if_stage_tb is
end entity if_stage_tb;

architecture if_stage_tb_arch of if_stage_tb is
    
    signal clk, branch, jal, jalr: std_logic;
    signal target, instr_mem_addr, instr_mem_data, pc, next_pc, instr: std_logic_vector(31 downto 0);

begin
    
    uut: if_stage port map (
        clk, 
        branch, 
        jal, 
        jalr, 
        target, 
        instr_mem_addr,
        instr_mem_data,
        pc, 
        next_pc,
        instr
    );

    process

        constant half_period: time := 50 ns;

    begin

        target <= x"0000_0005";
        instr_mem_data <= x"0020_81B3";
        
        branch <= '0';
        jal <= '0';
        jalr <= '0';

        clk <= '0';
        wait for half_period;
        clk <= '1';
        wait for half_period;

        assert (instr_mem_addr = x"0000_0004");
        assert (pc = x"0000_0004");
        assert (next_pc = x"0000_0008");
        assert (instr = x"0020_81B3");

        branch <= '1';
        jal <= '0';
        jalr <= '0';

        clk <= '0';
        wait for half_period;
        clk <= '1';
        wait for half_period;

        assert (instr_mem_addr = x"0000_0005");
        assert (pc = x"0000_0005");
        assert (next_pc = x"0000_0009");
        assert (instr = x"0000_0000");

        branch <= '0';
        jal <= '1';
        jalr <= '0';

        clk <= '0';
        wait for half_period;
        clk <= '1';
        wait for half_period;

        assert (instr_mem_addr = x"0000_0005");
        assert (pc = x"0000_0005");
        assert (next_pc = x"0000_0009");
        assert (instr = x"0000_0000");

        branch <= '0';
        jal <= '0';
        jalr <= '1';

        clk <= '0';
        wait for half_period;
        clk <= '1';
        wait for half_period;

        assert (instr_mem_addr = x"0000_000A");
        assert (pc = x"0000_000A");
        assert (next_pc = x"0000_000E");
        assert (instr = x"0000_0000");

        wait;

    end process ;
    
end architecture if_stage_tb_arch;