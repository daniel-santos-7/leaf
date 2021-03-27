library IEEE;
use IEEE.std_logic_1164.all;

entity alu_tb is 
end alu_tb;

architecture alu_tb_arch of alu_tb is

    signal opd0, opd1, rst: std_logic_vector(31 downto 0);
    signal op : std_logic_vector(3 downto 0);
    signal zero: std_logic;

begin
    
    uut: entity work.alu port map (opd0, opd1, op, rst, zero);

    process

        constant period: time := 10 ns;

        begin

            -- Test case 1

            opd0 <= x"0001_2CD7";
            opd1 <= x"0000_04EC";
            op <= b"0000";
            wait for period;
            assert (rst = x"0001_31C3" and zero = '0') 
            report "test failure: it should exec sum op" severity failure;

            -- Test case 2

            opd0 <= x"0A05_1AB1";
            opd1 <= x"010B_A1D0";
            op <= b"0001";
            wait for period;
            assert (rst = x"08F9_78E1" and zero = '0') 
            report "test failure: it should exec sub op" severity failure;

            -- Test case 3

            opd0 <= x"AF15_AAC1";
            opd1 <= x"F1FC_B1C1";
            op <= b"0010";
            wait for period;
            assert (rst = x"A114_A0C1" and zero = '0') 
            report "test failure: it should exec and op" severity failure;

            -- Test case 4

            opd0 <= x"A765_15C1";
            opd1 <= x"F10C_C121";
            op <= b"0011";
            wait for period;
            assert (rst = x"F76D_D5E1" and zero = '0') 
            report "test failure: it should exec or op" severity failure;

            -- Test case 5

            opd0 <= x"B165_9001";
            opd1 <= x"F75C_1101";
            op <= b"0100";
            wait for period;
            assert (rst = x"4639_8100" and zero = '0') 
            report "test failure: it should exec xor op" severity failure;

            wait;

    end process;
    
end architecture alu_tb_arch;