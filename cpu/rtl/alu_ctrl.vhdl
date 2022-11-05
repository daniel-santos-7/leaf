----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: ALU control
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity alu_ctrl is
    port (
        op_en : in  std_logic;
        ftype : in  std_logic;
        func3 : in  std_logic_vector(2 downto 0);
        func7 : in  std_logic_vector(6 downto 0);
        op    : out std_logic_vector(5 downto 0)
    );
end entity alu_ctrl;

architecture alu_ctrl_arch of alu_ctrl is
begin

    alu_op_ctrl: process(op_en, ftype, func3, func7)
    begin
        if op_en = '0' then
            op <= ALU_ADD;
        else
            case func3 is
                when b"000" =>
                    if func7 = b"0100000" and ftype = '0' then
                        op <= ALU_SUB;
                    else
                        op <= ALU_ADD;
                    end if;
                when b"001" => op <= ALU_SLL;
                when b"010" => op <= ALU_SLT;
                when b"011" => op <= ALU_SLTU;
                when b"100" => op <= ALU_XOR;
                when b"101" =>
                    if func7 = b"0100000" then
                        op <= ALU_SRA;
                    else
                        op <= ALU_SRL;
                    end if;
                when b"110" => op <= ALU_OR;
                when b"111" => op <= ALU_AND;
                when others => op <= ALU_ADD;
            end case;
        end if;
    end process alu_op_ctrl;
    
end architecture alu_ctrl_arch;