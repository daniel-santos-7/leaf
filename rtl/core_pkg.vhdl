library IEEE;
use IEEE.std_logic_1164.all;

package core_pkg is

    constant LOGIC_ARITH_OPCODE: std_logic_vector(6 downto 0) := b"0110011"; 
    constant LOGIC_ARITH_IMM_OPCODE: std_logic_vector(6 downto 0) := b"0010011"; 
    constant JALR_OPCODE: std_logic_vector(6 downto 0) := b"1100111";
    constant LOAD_OPCODE: std_logic_vector(6 downto 0) := b"0000011";
    constant STORE_OPCODE: std_logic_vector(6 downto 0) := b"0100011";
    constant BRANCH_OPCODE: std_logic_vector(6 downto 0) := b"1100011";
    constant LOAD_UPPER_IMM_OPCODE: std_logic_vector(6 downto 0) := b"0110111";
    constant ADD_UPPER_IMM_PC_OPCODE: std_logic_vector(6 downto 0) := b"0010111";
    constant JAL_OPCODE: std_logic_vector(6 downto 0) := b"1101111";

    constant ALU_ADD: std_logic_vector(3 downto 0) := x"0";
    constant ALU_SLL: std_logic_vector(3 downto 0) := x"1";
    constant ALU_SLT: std_logic_vector(3 downto 0) := x"2";
    constant ALU_SLTU: std_logic_vector(3 downto 0) := x"3";
    constant ALU_XOR: std_logic_vector(3 downto 0) := x"4";
    constant ALU_SRL: std_logic_vector(3 downto 0) := x"5";
    constant ALU_OR: std_logic_vector(3 downto 0) := x"6";
    constant ALU_AND: std_logic_vector(3 downto 0) := x"7";
    constant ALU_SUB: std_logic_vector(3 downto 0) := x"8";
    constant ALU_SRA: std_logic_vector(3 downto 0) := x"9";

    component main_ctrl is
    
        port (
            opcode: in std_logic_vector(6 downto 0);
            rf_write_en, rf_write_src: out std_logic;
            lsu_mode, lsu_en: out std_logic;
            branch, jal, jalr: out std_logic
        );
    
    end component;

    component imm_gen is
    
        port (
            instr: in std_logic_vector(31 downto 0);
            imm: out std_logic_vector(31 downto 0)   
        );
    
    end component imm_gen;

    component alu is

        port (
            opd0, opd1: in  std_logic_vector(31 downto 0);
            op: in std_logic_vector(3 downto 0);
            rslt: out std_logic_vector(31 downto 0)
        );

    end component;

    component reg_file is

        port (
            clk: in std_logic;
            rd_reg_addr0, rd_reg_addr1, wr_reg_addr: in std_logic_vector(4 downto 0);
            wr_reg_data: in std_logic_vector(31 downto 0);
            wr_reg_en: in std_logic;
            rd_reg_data0, rd_reg_data1: out std_logic_vector(31 downto 0)
        );

    end component;

    component branch_dtct is
    
        port (
            reg0, reg1: in std_logic_vector(31 downto 0);
            mode: in std_logic_vector(2 downto 0);
            branch: out std_logic
        );
    
    end component branch_dtct;

    component lsu is 

        port (
            rd_mem_data: in std_logic_vector(31 downto 0);
            wr_data: in std_logic_vector(31 downto 0);
            data_type: in std_logic_vector(2 downto 0);
            mode, en: in std_logic;
            rd_mem_en, wr_mem_en: out std_logic;
            wr_mem_data: out std_logic_vector(31 downto 0);
            rd_data: out std_logic_vector(31 downto 0)
        );

    end component;
    
    component if_stage is

        port (
            clk: std_logic;
            branch, jal, jalr: in std_logic;
            target: in std_logic_vector(31 downto 0);
            instr_mem_addr: out std_logic_vector(31 downto 0);
            instr_mem_data: in std_logic_vector(31 downto 0);
            pc, next_pc: out std_logic_vector(31 downto 0);
            instr: out std_logic_vector(31 downto 0)
        );

    end component;
    
end package core_pkg;