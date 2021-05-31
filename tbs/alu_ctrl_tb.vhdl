library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity alu_ctrl_tb is 
end alu_ctrl_tb;

architecture alu_ctrl_tb_arch of alu_ctrl_tb is

    signal std_op, imm_op: std_logic;
    signal func: std_logic_vector(9 downto 0);
    signal alu_op: std_logic_vector(3 downto 0);

begin
    
    uut: alu_ctrl port map (std_op, imm_op, func, alu_op);

    process

        constant period: time := 50 ns;

        begin

            -- RR operations decode --

            std_op <= '0';
            imm_op <= '0';
            func <= ALU_CTRL_SRA;

            wait for period;
            assert alu_op = ALU_SRA;

            -- non-logical / arithmetic operation decode --

            std_op <= '1';
            imm_op <= '0';
            func <= ALU_CTRL_SRA;

            wait for period;
            assert alu_op = ALU_ADD;

            std_op <= '0';
            imm_op <= '1';
            func <= ALU_CTRL_SRA;

            wait for period;
            assert alu_op = ALU_SRA;

            wait;

    end process;
    
end architecture alu_ctrl_tb_arch;