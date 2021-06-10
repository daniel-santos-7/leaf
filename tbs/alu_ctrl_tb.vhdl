library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;

entity alu_ctrl_tb is
end entity alu_ctrl_tb;

architecture alu_ctrl_tb_arch of alu_ctrl_tb is

    signal alu_op_en:     std_logic;
    signal alu_func_type: std_logic;

    signal func3:  std_logic_vector(2 downto 0);
    signal func7:  std_logic_vector(6 downto 0);
    signal alu_op: std_logic_vector(5 downto 0);

begin
    
    uut: alu_ctrl port map (
        alu_op_en     => alu_op_en,
        alu_func_type => alu_func_type,
        func3         => func3,
        func7         => func7,
        alu_op        => alu_op
    );

    test: process
        
        constant period: time := 50 ns;

    begin
        
        -- setup --
    
        alu_op_en <= '1';

        -- RR operations --

        alu_func_type <= '0';

        -- ADD operation --

        func3 <= b"000";
        func7 <= b"0000000";

        wait for period;

        assert alu_op = ALU_ADD;

        -- SUB operation --

        func3 <= b"000";
        func7 <= b"0100000";

        wait for period;

        assert alu_op = ALU_SUB;

        -- SLL operation --

        func3 <= b"001";
        func7 <= b"0000000";

        wait for period;

        assert alu_op = ALU_SLL;

        -- SLT operation --

        func3 <= b"010";
        func7 <= b"0000000";

        wait for period;

        assert alu_op = ALU_SLT;

        -- SLTU operation --

        func3 <= b"011";
        func7 <= b"0000000";

        wait for period;

        assert alu_op = ALU_SLTU;

        -- XOR operation --

        func3 <= b"100";
        func7 <= b"0000000";

        wait for period;

        assert alu_op = ALU_XOR;

        -- SRL operation --

        func3 <= b"101";
        func7 <= b"0000000";

        wait for period;

        assert alu_op = ALU_SRL;

        -- SRA operation --

        func3 <= b"101";
        func7 <= b"0100000";

        wait for period;

        assert alu_op = ALU_SRA;

        -- OR operation --

        func3 <= b"110";
        func7 <= b"0000000";

        wait for period;

        assert alu_op = ALU_OR;

        -- AND operation --

        func3 <= b"111";
        func7 <= b"0000000";

        wait for period;

        assert alu_op = ALU_AND;

        -- IMM operations --

        alu_func_type <= '1';

        -- ADD operation --

        func3 <= b"000";
        func7 <= b"0100000";

        wait for period;

        assert alu_op = ALU_ADD;

        -- SRA operation --

        func3 <= b"101";
        func7 <= b"0100000";

        wait for period;

        assert alu_op = ALU_SRA;

        -- others operations --

        alu_op_en <= '0';

        -- ADD operation --

        func3 <= b"101";
        func7 <= b"0100000";

        wait for period;

        assert alu_op = ALU_ADD;

        wait;

    end process test;        

end architecture alu_ctrl_tb_arch;