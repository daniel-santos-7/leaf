----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: ALU control
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

entity alu_ctrl is
    port (
        op_en_i : in  std_logic;
        ftype_i : in  std_logic;
        func3_i : in  std_logic_vector(2 downto 0);
        func7_i : in  std_logic_vector(6 downto 0);
        op_o    : out std_logic_vector(5 downto 0)
    );
end entity alu_ctrl;

architecture alu_ctrl_arch of alu_ctrl is
begin

    alu_op_ctrl: process(op_en_i, ftype_i, func3_i, func7_i)
    begin
        if op_en_i = '0' then
            op_o <= ALU_ADD;
        else
            case func3_i is
                when b"000" =>
                    if func7_i = b"0100000" and ftype_i = '0' then
                        op_o <= ALU_SUB;
                    else
                        op_o <= ALU_ADD;
                    end if;
                when b"001" => op_o <= ALU_SLL;
                when b"010" => op_o <= ALU_SLT;
                when b"011" => op_o <= ALU_SLTU;
                when b"100" => op_o <= ALU_XOR;
                when b"101" =>
                    if func7_i = b"0100000" then
                        op_o <= ALU_SRA;
                    else
                        op_o <= ALU_SRL;
                    end if;
                when b"110" => op_o <= ALU_OR;
                when b"111" => op_o <= ALU_AND;
                when others => op_o <= ALU_ADD;
            end case;
        end if;
    end process alu_op_ctrl;

end architecture alu_ctrl_arch;
