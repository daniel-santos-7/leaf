library IEEE;
use IEEE.std_logic_1164.all;

package core_pkg is

    -- opcodes --
    
    constant RR_OPCODE:     std_logic_vector(6 downto 0) := b"0110011"; 
    constant IMM_OPCODE:    std_logic_vector(6 downto 0) := b"0010011"; 
    constant JALR_OPCODE:   std_logic_vector(6 downto 0) := b"1100111";
    constant LOAD_OPCODE:   std_logic_vector(6 downto 0) := b"0000011";
    constant STORE_OPCODE:  std_logic_vector(6 downto 0) := b"0100011";
    constant BRANCH_OPCODE: std_logic_vector(6 downto 0) := b"1100011";
    constant LUI_OPCODE:    std_logic_vector(6 downto 0) := b"0110111";
    constant AUIPC_OPCODE:  std_logic_vector(6 downto 0) := b"0010111";
    constant JAL_OPCODE:    std_logic_vector(6 downto 0) := b"1101111";
    constant SYSTEM_OPCODE: std_logic_vector(6 downto 0) := b"1110011";
    constant FENCE_OPCODE:  std_logic_vector(6 downto 0) := b"0001111";

    -- CSR addr --

    constant CSR_ADDR_MHARTID:  std_logic_vector(11 downto 0) := x"F14";
    constant CSR_ADDR_MSTATUS:  std_logic_vector(11 downto 0) := x"300";
    constant CSR_ADDR_MISA:     std_logic_vector(11 downto 0) := x"301";
    constant CSR_ADDR_MIE:      std_logic_vector(11 downto 0) := x"304";
    constant CSR_ADDR_MTVEC:    std_logic_vector(11 downto 0) := x"305";    
    constant CSR_ADDR_MSCRATCH: std_logic_vector(11 downto 0) := x"340";
    constant CSR_ADDR_MEPC:     std_logic_vector(11 downto 0) := x"341";
    constant CSR_ADDR_MCAUSE:   std_logic_vector(11 downto 0) := x"342";
    constant CSR_ADDR_MTVAL:    std_logic_vector(11 downto 0) := x"343";
    constant CSR_ADDR_MIP:      std_logic_vector(11 downto 0) := x"344";

    -- ALU op --

    constant ALU_ADD:  std_logic_vector(5 downto 0) := b"001111";
    constant ALU_SLL:  std_logic_vector(5 downto 0) := b"001100";
    constant ALU_SLT:  std_logic_vector(5 downto 0) := b"101111";
    constant ALU_SLTU: std_logic_vector(5 downto 0) := b"111111";
    constant ALU_XOR:  std_logic_vector(5 downto 0) := b"000011";
    constant ALU_SRL:  std_logic_vector(5 downto 0) := b"001101";
    constant ALU_OR:   std_logic_vector(5 downto 0) := b"000111";
    constant ALU_AND:  std_logic_vector(5 downto 0) := b"001011";
    constant ALU_SUB:  std_logic_vector(5 downto 0) := b"011111";
    constant ALU_SRA:  std_logic_vector(5 downto 0) := b"001110";

    -- ALU control func --

    constant ALU_CTRL_ADD:  std_logic_vector(9 downto 0) := b"0000000000";
    constant ALU_CTRL_SLL:  std_logic_vector(9 downto 0) := b"0000000001";
    constant ALU_CTRL_SLT:  std_logic_vector(9 downto 0) := b"0000000010";
    constant ALU_CTRL_SLTU: std_logic_vector(9 downto 0) := b"0000000011";
    constant ALU_CTRL_XOR:  std_logic_vector(9 downto 0) := b"0000000100";
    constant ALU_CTRL_SRL:  std_logic_vector(9 downto 0) := b"0000000101";
    constant ALU_CTRL_OR:   std_logic_vector(9 downto 0) := b"0000000110";
    constant ALU_CTRL_AND:  std_logic_vector(9 downto 0) := b"0000000111";
    constant ALU_CTRL_SUB:  std_logic_vector(9 downto 0) := b"0100000000";
    constant ALU_CTRL_SRA:  std_logic_vector(9 downto 0) := b"0100000101";

    -- imm types --

    constant IMM_I_TYPE: std_logic_vector(2 downto 0) := b"000";
    constant IMM_S_TYPE: std_logic_vector(2 downto 0) := b"001";
    constant IMM_B_TYPE: std_logic_vector(2 downto 0) := b"010";
    constant IMM_U_TYPE: std_logic_vector(2 downto 0) := b"011";
    constant IMM_J_TYPE: std_logic_vector(2 downto 0) := b"100";
    constant IMM_Z_TYPE: std_logic_vector(2 downto 0) := b"101";

    -- branch detector mode --

    constant EQ_BD_MODE:  std_logic_vector(2 downto 0) := b"000";
    constant NE_BD_MODE:  std_logic_vector(2 downto 0) := b"001";
    constant LT_BD_MODE:  std_logic_vector(2 downto 0) := b"100";
    constant GE_BD_MODE:  std_logic_vector(2 downto 0) := b"101";
    constant LTU_BD_MODE: std_logic_vector(2 downto 0) := b"110";
    constant GEU_BD_MODE: std_logic_vector(2 downto 0) := b"111";

    -- lsu data type --

    constant LSU_BYTE:  std_logic_vector(2 downto 0) := b"000";
    constant LSU_BYTEU: std_logic_vector(2 downto 0) := b"100";
    constant LSU_HALF:  std_logic_vector(2 downto 0) := b"001";
    constant LSU_HALFU: std_logic_vector(2 downto 0) := b"101";
    constant LSU_WORD:  std_logic_vector(2 downto 0) := b"010";

    component alu is

        port (
            opd0: in  std_logic_vector(31 downto 0);
            opd1: in  std_logic_vector(31 downto 0);
            op:   in  std_logic_vector(5  downto 0);
            
            res:  out std_logic_vector(31 downto 0)
        );

    end component alu;

    component alu_ctrl is

        port (
            alu_op_en:     in std_logic;
            alu_func_type: in std_logic;
            func3:         in std_logic_vector(2 downto 0);
            func7:         in std_logic_vector(6 downto 0);
    
            alu_op: out std_logic_vector(5 downto 0)
        );
    
    end component alu_ctrl;

    component main_ctrl is
    
        port (
            opcode: in std_logic_vector(6 downto 0);
            flush: in std_logic;
    
            rf_wr_reg_src: out std_logic_vector(1 downto 0);
            rf_wr_reg_en:  out std_logic;
            
            ig_imm_type: out std_logic_vector(2 downto 0);
            
            alu_src0:      out std_logic; 
            alu_src1:      out std_logic; 
            alu_opd0_pass: out std_logic;
            alu_opd1_pass: out std_logic;
            
            alu_op_en:     out std_logic;
            alu_func_type: out std_logic;
    
            lsu_mode: out std_logic;
            lsu_en:   out std_logic;
            
            brd_en:     out std_logic;
    
            csrs_wr_en: out std_logic;
    
            if_jmp:     out std_logic
        );
    
    end component main_ctrl;

    component imm_gen is
    
        port (
            payload:  in  std_logic_vector(24 downto 0);
            imm_type: in  std_logic_vector(2  downto 0);
            imm:      out std_logic_vector(31 downto 0)
        );
    
    end component imm_gen;

    component reg_file is

        port (
            clk: in std_logic;
        
            rd_reg_addr0: in std_logic_vector(4 downto 0);
            rd_reg_addr1: in std_logic_vector(4 downto 0);
            wr_reg_addr:  in std_logic_vector(4 downto 0);
            
            wr_reg_data: in std_logic_vector(31 downto 0);
            wr_reg_en:   in std_logic;
            
            rd_reg_data0: out std_logic_vector(31 downto 0);
            rd_reg_data1: out std_logic_vector(31 downto 0)
        );

    end component reg_file;

    component br_detector is
    
        port (
            reg0: in std_logic_vector(31 downto 0); 
            reg1: in std_logic_vector(31 downto 0);
            mode: in std_logic_vector(2  downto 0);
            en:   in std_logic;
            
            branch: out std_logic
        );
    
    end component br_detector;

    component csrs is

        generic (
            MHART_ID: std_logic_vector(31 downto 0) := (others => '0')
        );
    
        port (
            clk:   in std_logic;
            reset: in std_logic;
    
            ex_irq: in std_logic;
            sw_irq: in std_logic;
            tm_irq: in std_logic;
    
            wr_mode: in std_logic_vector(2 downto 0);
            wr_en:   in std_logic;
    
            rd_wr_addr:  in  std_logic_vector(11 downto 0);
            wr_reg_data: in  std_logic_vector(31 downto 0);
            wr_imm_data: in  std_logic_vector(31 downto 0);
            rd_data:     out std_logic_vector(31 downto 0)
        );    
    
    end component csrs;

    component lsu is 

        port (
            rd_data:    out std_logic_vector(31 downto 0);        
            wr_data:    in  std_logic_vector(31 downto 0);
            rd_wr_addr: in  std_logic_vector(31 downto 0);
            
            data_type: in std_logic_vector(2 downto 0);
            mode:      in std_logic;
            en:        in std_logic;
    
            rd_mem_en: out std_logic; 
            wr_mem_en: out std_logic;
    
            rd_mem_data:    in  std_logic_vector(31 downto 0);
            wr_mem_data:    out std_logic_vector(31 downto 0);
            rd_wr_mem_addr: out std_logic_vector(31 downto 0);
            wr_mem_byte_en: out std_logic_vector(3  downto 0)
        );

    end component lsu;

    component id_ex_stage is
    
        port (
            clk:   in std_logic;
            reset: in std_logic;
            
            pc:         in std_logic_vector(31 downto 0);
            next_pc:    in std_logic_vector(31 downto 0);
            instr:      in std_logic_vector(31 downto 0);
            flush:      in std_logic;
            
            rd_mem_data:    in  std_logic_vector(31 downto 0);
            wr_mem_data:    out std_logic_vector(31 downto 0);
            rd_mem_en:      out std_logic;
            wr_mem_en:      out std_logic;
            rd_wr_mem_addr: out std_logic_vector(31 downto 0);
            wr_mem_byte_en: out std_logic_vector(3 downto 0);
    
            ex_irq: in std_logic;
            sw_irq: in std_logic;
            tm_irq: in std_logic;
            
            branch:  out std_logic; 
            jmp:     out std_logic; 
            trap:    out std_logic;
            
            target: out std_logic_vector(31 downto 0)
        );
    
    end component id_ex_stage;
    
    component if_stage is

        generic (
            RESET_ADDR: std_logic_vector(31 downto 0) := (others => '0')
        );
    
        port (
            clk:   in std_logic;
            reset: in std_logic;
    
            jmp:     in std_logic;
            branch:  in std_logic;
            trap:    in std_logic;
    
            target: in std_logic_vector(31 downto 0);
            
            rd_instr_mem_data: in  std_logic_vector(31 downto 0);
            rd_instr_mem_addr: out std_logic_vector(31 downto 0);
            
            pc:      out std_logic_vector(31 downto 0);
            next_pc: out std_logic_vector(31 downto 0);
            instr:   out std_logic_vector(31 downto 0);
            flush:   out std_logic
        );

    end component if_stage;

    component core is
    
        port (
            clk:   in std_logic; 
            reset: in std_logic;
            
            rd_instr_mem_data: in  std_logic_vector(31 downto 0);
            rd_instr_mem_addr: out std_logic_vector(31 downto 0);
            
            rd_mem_data: in  std_logic_vector(31 downto 0);
            wr_mem_data: out std_logic_vector(31 downto 0);
            
            rd_mem_en: out std_logic;
            wr_mem_en: out std_logic;
            
            rd_wr_mem_addr: out std_logic_vector(31 downto 0);
            wr_mem_byte_en: out std_logic_vector(3 downto 0);
    
            ex_irq: in std_logic;
            sw_irq: in std_logic;
            tm_irq: in std_logic
        );
    
    end component core;

    ----------------------------------------------------------------

    component logic_unit is
        port (
            opd0:   in  std_logic_vector(31 downto 0);
            opd1:   in  std_logic_vector(31 downto 0);
            op:     in  std_logic_vector(1  downto 0);
            res:    out std_logic_vector(31 downto 0)
        );
    end component logic_unit;

    component ex_block is
        port (
            opd0_src0: in  std_logic_vector(31 downto 0);
            opd0_src1: in  std_logic_vector(31 downto 0);
            opd1_src0: in  std_logic_vector(31 downto 0);
            opd1_src1: in  std_logic_vector(31 downto 0);
            ex_ctrl:   in  std_logic_vector(5  downto 0);     
            ex_func:   in  std_logic_vector(9  downto 0);
            res:       out std_logic_vector(31 downto 0)
        );
    end component ex_block;

    component int_strg is
        port (
            clk:        in  std_logic;
            wr_en:      in  std_logic;
            wr_src0:    in  std_logic_vector(31 downto 0);
            wr_src1:    in  std_logic_vector(31 downto 0);
            wr_src2:    in  std_logic_vector(31 downto 0);
            wr_src3:    in  std_logic_vector(31 downto 0);
            wr_src_sel: in  std_logic_vector(1  downto 0);
            regs_addr:  in  std_logic_vector(14 downto 0);
            rd_data0:   out std_logic_vector(31 downto 0);
            rd_data1:   out std_logic_vector(31 downto 0)
        );
    end component int_strg;

    component id_block is
        port (
            instr           : in  std_logic_vector(31 downto 0);
            flush           : in  std_logic;
            regs_addr       : out std_logic_vector(14 downto 0);
            csrs_addr       : out std_logic_vector(11 downto 0);
            ex_func         : out std_logic_vector(9  downto 0);
            csrs_mode       : out std_logic_vector(2  downto 0);
            brde_mode       : out std_logic_vector(2  downto 0);
            dmls_dtype      : out std_logic_vector(2  downto 0);
            imm             : out std_logic_vector(31 downto 0);
            int_strg_ctrl   : out std_logic_vector(2  downto 0);
            ex_ctrl         : out std_logic_vector(5  downto 0);
            dmls_ctrl       : out std_logic_vector(1  downto 0);
            brde_ctrl       : out std_logic_vector(1  downto 0);
            csrs_ctrl       : out std_logic
        );
    end component id_block;
    
end package core_pkg;