library IEEE;
use IEEE.std_logic_1164.all;

package tbs_pkg is

    constant CLK_PERIOD: time := 20 ns;

    procedure tick(signal clk: out std_logic);
    procedure tickn(signal clk: inout std_logic; constant N: natural);

    function r_instr(
        opcode: in std_logic_vector(6 downto 0);
        rd: in std_logic_vector(4 downto 0);
        func3: in std_logic_vector(2 downto 0);
        rs1: in std_logic_vector(4 downto 0);
        rs2: in std_logic_vector(4 downto 0);
        func7: in std_logic_vector(6 downto 0)
    ) return std_logic_vector;
    
    function i_instr(
        opcode: in std_logic_vector(6 downto 0);
        rd: in std_logic_vector(4 downto 0);
        func3: in std_logic_vector(2 downto 0);
        rs1: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector;

    function s_instr(
        opcode: in std_logic_vector(6 downto 0);
        func3: in std_logic_vector(2 downto 0);
        rs1: in std_logic_vector(4 downto 0);
        rs2: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector;

    function b_instr(
        opcode: in std_logic_vector(6 downto 0);
        func3: in std_logic_vector(2 downto 0);
        rs1: in std_logic_vector(4 downto 0);
        rs2: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector;

    function u_instr(
        opcode: in std_logic_vector(6 downto 0);
        rd: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector;

    function j_instr(
        opcode: in std_logic_vector(6 downto 0);
        rd: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector;

    function add_instr(
        rd: in std_logic_vector(4 downto 0);
        rs1: in std_logic_vector(4 downto 0);
        rs2: in std_logic_vector(4 downto 0)
    ) return std_logic_vector;

    function addi_instr(
        rd: in std_logic_vector(4 downto 0);
        rs1: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector;

    function blt_instr(
        rs1: in std_logic_vector(4 downto 0);
        rs2: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector;
    
    function sw_instr(
        rs1: in std_logic_vector(4 downto 0);
        rs2: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector;
    
end package tbs_pkg;

package body tbs_pkg is

    procedure tick(signal clk: out std_logic) is
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;

        clk <= '1';
        wait for CLK_PERIOD/2;
    end procedure;

    procedure tickn(signal clk: inout std_logic; constant N: natural) is
    begin
        for i in 0 to N loop
            tick(clk);
        end loop;
    end procedure;

    function r_instr(
        opcode: in std_logic_vector(6 downto 0);
        rd: in std_logic_vector(4 downto 0);
        func3: in std_logic_vector(2 downto 0);
        rs1: in std_logic_vector(4 downto 0);
        rs2: in std_logic_vector(4 downto 0);
        func7: in std_logic_vector(6 downto 0)
    ) return std_logic_vector is

    begin

        return func7 & rs2 & rs1 & func3 & rd & opcode;

    end function r_instr;
    
    function i_instr(
        opcode: in std_logic_vector(6 downto 0);
        rd: in std_logic_vector(4 downto 0);
        func3: in std_logic_vector(2 downto 0);
        rs1: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector is

    begin

        return imm(11 downto 0) & rs1 & func3 & rd & opcode;

    end function i_instr;

    function s_instr(
        opcode: in std_logic_vector(6 downto 0);
        func3: in std_logic_vector(2 downto 0);
        rs1: in std_logic_vector(4 downto 0);
        rs2: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector is

    begin

        return imm(11 downto 5) & rs2 & rs1 & func3 & imm(4 downto 0) & opcode;

    end function s_instr;

    function b_instr(
        opcode: in std_logic_vector(6 downto 0);
        func3: in std_logic_vector(2 downto 0);
        rs1: in std_logic_vector(4 downto 0);
        rs2: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector is

    begin

        return imm(12) & imm(10 downto 5) & rs2 & rs1 & func3 & imm(4 downto 1) & imm(11) & opcode;

    end function b_instr;

    function u_instr(
        opcode: in std_logic_vector(6 downto 0);
        rd: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector is

    begin

        return imm(31 downto 12) & rd & opcode;

    end function u_instr;

    function j_instr(
        opcode: in std_logic_vector(6 downto 0);
        rd: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector is

    begin

        return imm(20) & imm(10 downto 1) & imm(11) & imm(19 downto 12) & rd & opcode;

    end function j_instr;

    function add_instr(
        rd: in std_logic_vector(4 downto 0);
        rs1: in std_logic_vector(4 downto 0);
        rs2: in std_logic_vector(4 downto 0)
    ) return std_logic_vector is

    begin

        return r_instr(b"0110011", rd, b"000", rs1, rs2, b"0000000");
        
    end function add_instr;

    function addi_instr(
        rd: in std_logic_vector(4 downto 0);
        rs1: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector is

    begin

        return i_instr(b"0010011", rd, b"000", rs1, imm);

    end function addi_instr;

    function blt_instr(
        rs1: in std_logic_vector(4 downto 0);
        rs2: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector is

    begin

        return b_instr(b"1100011", b"100", rs1, rs2, imm);

    end function blt_instr;

    function sw_instr(
        rs1: in std_logic_vector(4 downto 0);
        rs2: in std_logic_vector(4 downto 0);
        imm: in std_logic_vector(31 downto 0)
    ) return std_logic_vector is

    begin

        return s_instr(b"0100011", b"010", rs1, rs2, imm);

    end function sw_instr;

end package body tbs_pkg;