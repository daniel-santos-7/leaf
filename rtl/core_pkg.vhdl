library IEEE;
use IEEE.std_logic_1164.all;

package core_pkg is

    -- opcodes --
    
    constant LOGIC_ARITH_OPCODE: std_logic_vector(6 downto 0) := b"0110011"; 
    constant LOGIC_ARITH_IMM_OPCODE: std_logic_vector(6 downto 0) := b"0010011"; 
    constant JALR_OPCODE: std_logic_vector(6 downto 0) := b"1100111";
    constant LOAD_OPCODE: std_logic_vector(6 downto 0) := b"0000011";
    constant STORE_OPCODE: std_logic_vector(6 downto 0) := b"0100011";
    constant BRANCH_OPCODE: std_logic_vector(6 downto 0) := b"1100011";
    constant LOAD_UPPER_IMM_OPCODE: std_logic_vector(6 downto 0) := b"0110111";
    constant ADD_UPPER_IMM_PC_OPCODE: std_logic_vector(6 downto 0) := b"0010111";
    constant JAL_OPCODE: std_logic_vector(6 downto 0) := b"1101111";

    -- alu op --

    constant ALU_ADD: std_logic_vector(3 downto 0) := b"0000";
    constant ALU_SLL: std_logic_vector(3 downto 0) := b"0001";
    constant ALU_SLT: std_logic_vector(3 downto 0) := b"0010";
    constant ALU_SLTU: std_logic_vector(3 downto 0) := b"0011";
    constant ALU_XOR: std_logic_vector(3 downto 0) := b"0100";
    constant ALU_SRL: std_logic_vector(3 downto 0) := b"0101";
    constant ALU_OR: std_logic_vector(3 downto 0) := b"0110";
    constant ALU_AND: std_logic_vector(3 downto 0) := b"0111";
    constant ALU_SUB: std_logic_vector(3 downto 0) := b"1000";
    constant ALU_SRA: std_logic_vector(3 downto 0) := b"1101";

    -- alu control func --

    constant ALU_CTRL_ADD: std_logic_vector(9 downto 0) := b"0000000000";
    constant ALU_CTRL_SLL: std_logic_vector(9 downto 0) := b"0000000001";
    constant ALU_CTRL_SLT: std_logic_vector(9 downto 0) := b"0000000010";
    constant ALU_CTRL_SLTU: std_logic_vector(9 downto 0) := b"0000000011";
    constant ALU_CTRL_XOR: std_logic_vector(9 downto 0) := b"0000000100";
    constant ALU_CTRL_SRL: std_logic_vector(9 downto 0) := b"0000000101";
    constant ALU_CTRL_OR: std_logic_vector(9 downto 0) := b"0000000110";
    constant ALU_CTRL_AND: std_logic_vector(9 downto 0) := b"0000000111";
    constant ALU_CTRL_SUB: std_logic_vector(9 downto 0) := b"0100000000";
    constant ALU_CTRL_SRA: std_logic_vector(9 downto 0) := b"0100000101";

    -- imms types --

    constant IMM_I_TYPE: std_logic_vector(2 downto 0) := b"000";
    constant IMM_S_TYPE: std_logic_vector(2 downto 0) := b"001";
    constant IMM_B_TYPE: std_logic_vector(2 downto 0) := b"010";
    constant IMM_U_TYPE: std_logic_vector(2 downto 0) := b"011";
    constant IMM_J_TYPE: std_logic_vector(2 downto 0) := b"100";

    -- branch detector modes --

    constant EQ_BD_MODE: std_logic_vector(2 downto 0) := b"000";
    constant NE_BD_MODE: std_logic_vector(2 downto 0) := b"001";
    constant LT_BD_MODE: std_logic_vector(2 downto 0) := b"100";
    constant GE_BD_MODE: std_logic_vector(2 downto 0) := b"101";
    constant LTU_BD_MODE: std_logic_vector(2 downto 0) := b"110";
    constant GEU_BD_MODE: std_logic_vector(2 downto 0) := b"111";

    -- lsu data types --

    constant LSU_BYTE: std_logic_vector(2 downto 0) := b"000";
    constant LSU_BYTEU: std_logic_vector(2 downto 0) := b"100";
    constant LSU_HALF: std_logic_vector(2 downto 0) := b"001";
    constant LSU_HALFU: std_logic_vector(2 downto 0) := b"101";
    constant LSU_WORD: std_logic_vector(2 downto 0) := b"010";

    component alu is

        port (
            opd0, opd1: in  std_logic_vector(31 downto 0);
            op: in std_logic_vector(3 downto 0);
            res: out std_logic_vector(31 downto 0)
        );

    end component alu;

    component alu_ctrl is

        port (
            std_op: in std_logic;
            imm_op: in std_logic;
            func: in std_logic_vector(9 downto 0);
            alu_op: out std_logic_vector(3 downto 0)
        );
    
    end component alu_ctrl;

    component main_ctrl is
    
        port (
            opcode: in std_logic_vector(6 downto 0);
            no_op: in std_logic;
            rf_write_src: out std_logic_vector(1 downto 0);
            rf_write_en: out std_logic;
            ig_imm_type: out std_logic_vector(2 downto 0);
            alu_src0, alu_src1, alu_src0_pass: out std_logic;
            alu_std_op, alu_imm_op: out std_logic;
            lsu_mode, lsu_en: out std_logic;
            br_detector_en: out std_logic;
            if_jmp, if_target_shift: out std_logic
        );
    
    end component main_ctrl;

    component imm_gen is
    
        port (
            instr_payload: in std_logic_vector(24 downto 0);
            imm_type: in std_logic_vector(2 downto 0);
            imm: out std_logic_vector(31 downto 0)
        );
    
    end component imm_gen;

    component reg_file is

        port (
            clk: in std_logic;
            rd_reg_addr0, rd_reg_addr1, wr_reg_addr: in std_logic_vector(4 downto 0);
            wr_reg_data: in std_logic_vector(31 downto 0);
            wr_reg_en: in std_logic;
            rd_reg_data0, rd_reg_data1: out std_logic_vector(31 downto 0)
        );

    end component reg_file;

    component branch_detector is
    
        port (
            reg0, reg1: in std_logic_vector(31 downto 0);
            mode: in std_logic_vector(2 downto 0);
            en: in std_logic;
            branch: out std_logic
        );
    
    end component branch_detector;

    component lsu is 

        port (
            rd_mem_data:    in std_logic_vector(31 downto 0);
            rd_wr_addr:     in std_logic_vector(31 downto 0);
            wr_data:        in std_logic_vector(31 downto 0);
            data_type:      in std_logic_vector(2 downto 0);
            mode, en:       in std_logic;
            rd_mem_en:      out std_logic;
            wr_mem_en:      out std_logic;
            rd_wr_mem_addr: out std_logic_vector(31 downto 0);
            wr_mem_data:    out std_logic_vector(31 downto 0);
            rd_data:        out std_logic_vector(31 downto 0);
            wr_mem_byte_en: out std_logic_vector(3  downto 0)
        );

    end component lsu;

    component id_ex_stage is
    
        port (
            clk: in std_logic;
            pc: in std_logic_vector(31 downto 0);
            next_pc: in std_logic_vector(31 downto 0);
            instr: in std_logic_vector(31 downto 0);
            no_op: in std_logic;
            rd_mem_data: in std_logic_vector(31 downto 0);
            rd_mem_en: out std_logic;
            wr_mem_en: out std_logic;
            rd_wr_mem_addr: out std_logic_vector(31 downto 0);
            wr_mem_data: out std_logic_vector(31 downto 0);
            wr_mem_byte_en: out std_logic_vector(3 downto 0);
            branch, jmp, target_shift: out std_logic;
            target: out std_logic_vector(31 downto 0)
        );
    
    end component id_ex_stage;
    
    component if_stage is

        port (
            clk: in std_logic;
            reset: in std_logic;
            jmp, branch, target_shift: in std_logic;
            target: in std_logic_vector(31 downto 0);
            rd_instr_mem_data: in std_logic_vector(31 downto 0);
            rd_instr_mem_addr: out std_logic_vector(31 downto 0);
            pc, next_pc: out std_logic_vector(31 downto 0);
            instr: out std_logic_vector(31 downto 0);
            no_op: out std_logic
        );

    end component if_stage;

    component core is
    
        port (
            clk, reset: in std_logic;
            rd_instr_mem_data: in std_logic_vector(31 downto 0);
            rd_instr_mem_addr: out std_logic_vector(31 downto 0);
            rd_mem_data: in std_logic_vector(31 downto 0);
            rd_mem_en: out std_logic;
            wr_mem_data: out std_logic_vector(31 downto 0);
            wr_mem_en: out std_logic;
            rd_wr_mem_addr: out std_logic_vector(31 downto 0);
            wr_mem_byte_en: out std_logic_vector(3 downto 0)
        );
    
    end component core;
    
end package core_pkg;