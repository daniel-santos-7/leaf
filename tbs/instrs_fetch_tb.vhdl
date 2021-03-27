library IEEE;
use IEEE.std_logic_1164.all;

entity instrs_fetch_tb is 
end instrs_fetch_tb;

architecture instrs_fetch_tb_arch of instrs_fetch_tb is

    signal clk, pc_clr: std_logic;
    signal instr_addr: std_logic_vector(31 downto 0);

begin
    
    uut: entity work.instrs_fetch port map (clk, pc_clr, instr_addr);

    process

        constant half_period: time := 5 ns;

        begin

            -- Test case 1
            
            pc_clr <= '1';

            clk <= '0';
            wait for half_period;
            clk <= '1';
            wait for half_period;

            assert (instr_addr = x"0000_0000")
            report "test failure: instr_addr should be x0" severity failure;

            -- Test case 2

            pc_clr <= '0';
            
            clk <= '0';
            wait for half_period;
            clk <= '1';
            wait for half_period;

            assert (instr_addr = x"0000_0004")
            report "test failure: instr_addr should be x4" severity failure;

            -- Test case 3

            pc_clr <= '0';
            
            clk <= '0';
            wait for half_period;
            clk <= '1';
            wait for half_period;

            assert (instr_addr = x"0000_0008")
            report "test failure: instr_addr should be x8" severity failure;

            -- Test case 4
            
            pc_clr <= '0';

            clk <= '0';
            wait for half_period;
            clk <= '1';
            wait for half_period;

            assert (instr_addr = x"0000_000C")
            report "test failure: instr_addr should be xC" severity failure;

            -- Test case 5

            pc_clr <= '1';

            clk <= '0';
            wait for half_period;
            clk <= '1';
            wait for half_period;

            assert (instr_addr = x"0000_0000")
            report "test failure: instr_addr should be x0 again" severity failure;

            wait;

    end process;
    
end architecture instrs_fetch_tb_arch;