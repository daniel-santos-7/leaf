----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- package: leaf package
-- 2022
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package core_pkg is

    -- opcodes --
    
    constant RR_OPCODE     : std_logic_vector(6 downto 0) := b"0110011"; 
    constant IMM_OPCODE    : std_logic_vector(6 downto 0) := b"0010011"; 
    constant JALR_OPCODE   : std_logic_vector(6 downto 0) := b"1100111";
    constant LOAD_OPCODE   : std_logic_vector(6 downto 0) := b"0000011";
    constant STORE_OPCODE  : std_logic_vector(6 downto 0) := b"0100011";
    constant BRANCH_OPCODE : std_logic_vector(6 downto 0) := b"1100011";
    constant LUI_OPCODE    : std_logic_vector(6 downto 0) := b"0110111";
    constant AUIPC_OPCODE  : std_logic_vector(6 downto 0) := b"0010111";
    constant JAL_OPCODE    : std_logic_vector(6 downto 0) := b"1101111";
    constant SYSTEM_OPCODE : std_logic_vector(6 downto 0) := b"1110011";
    constant FENCE_OPCODE  : std_logic_vector(6 downto 0) := b"0001111";

    -- CSR addr --

    constant CSR_ADDR_MHARTID  : std_logic_vector(11 downto 0) := x"F14";
    constant CSR_ADDR_MSTATUS  : std_logic_vector(11 downto 0) := x"300";
    constant CSR_ADDR_MISA     : std_logic_vector(11 downto 0) := x"301";
    constant CSR_ADDR_MIE      : std_logic_vector(11 downto 0) := x"304";
    constant CSR_ADDR_MTVEC    : std_logic_vector(11 downto 0) := x"305";    
    constant CSR_ADDR_MSCRATCH : std_logic_vector(11 downto 0) := x"340";
    constant CSR_ADDR_MEPC     : std_logic_vector(11 downto 0) := x"341";
    constant CSR_ADDR_MCAUSE   : std_logic_vector(11 downto 0) := x"342";
    constant CSR_ADDR_MTVAL    : std_logic_vector(11 downto 0) := x"343";
    constant CSR_ADDR_MIP      : std_logic_vector(11 downto 0) := x"344";
    constant CSR_ADDR_CYCLE    : std_logic_vector(11 downto 0) := x"C00";
    constant CSR_ADDR_TIME     : std_logic_vector(11 downto 0) := x"C01";
    constant CSR_ADDR_INSTRET  : std_logic_vector(11 downto 0) := x"C02";
    constant CSR_ADDR_CYCLEH   : std_logic_vector(11 downto 0) := x"C80";
    constant CSR_ADDR_TIMEH    : std_logic_vector(11 downto 0) := x"C81";
    constant CSR_ADDR_INSTRETH : std_logic_vector(11 downto 0) := x"C82";

    -- ALU op --

    constant ALU_ADD  : std_logic_vector(5 downto 0) := b"001111";
    constant ALU_SLL  : std_logic_vector(5 downto 0) := b"001100";
    constant ALU_SLT  : std_logic_vector(5 downto 0) := b"101111";
    constant ALU_SLTU : std_logic_vector(5 downto 0) := b"111111";
    constant ALU_XOR  : std_logic_vector(5 downto 0) := b"000011";
    constant ALU_SRL  : std_logic_vector(5 downto 0) := b"001101";
    constant ALU_OR   : std_logic_vector(5 downto 0) := b"000111";
    constant ALU_AND  : std_logic_vector(5 downto 0) := b"001011";
    constant ALU_SUB  : std_logic_vector(5 downto 0) := b"011111";
    constant ALU_SRA  : std_logic_vector(5 downto 0) := b"001110";

    -- ALU control func --

    constant ALU_CTRL_ADD  :  std_logic_vector(9 downto 0) := b"0000000000";
    constant ALU_CTRL_SLL  :  std_logic_vector(9 downto 0) := b"0000000001";
    constant ALU_CTRL_SLT  :  std_logic_vector(9 downto 0) := b"0000000010";
    constant ALU_CTRL_SLTU :  std_logic_vector(9 downto 0) := b"0000000011";
    constant ALU_CTRL_XOR  :  std_logic_vector(9 downto 0) := b"0000000100";
    constant ALU_CTRL_SRL  :  std_logic_vector(9 downto 0) := b"0000000101";
    constant ALU_CTRL_OR   :  std_logic_vector(9 downto 0) := b"0000000110";
    constant ALU_CTRL_AND  :  std_logic_vector(9 downto 0) := b"0000000111";
    constant ALU_CTRL_SUB  :  std_logic_vector(9 downto 0) := b"0100000000";
    constant ALU_CTRL_SRA  :  std_logic_vector(9 downto 0) := b"0100000101";

    -- imm types --

    constant IMM_I_TYPE : std_logic_vector(2 downto 0) := b"000";
    constant IMM_S_TYPE : std_logic_vector(2 downto 0) := b"001";
    constant IMM_B_TYPE : std_logic_vector(2 downto 0) := b"010";
    constant IMM_U_TYPE : std_logic_vector(2 downto 0) := b"011";
    constant IMM_J_TYPE : std_logic_vector(2 downto 0) := b"100";
    constant IMM_Z_TYPE : std_logic_vector(2 downto 0) := b"101";

    -- branch detector mode --

    constant EQ_BD_MODE  : std_logic_vector(2 downto 0) := b"000";
    constant NE_BD_MODE  : std_logic_vector(2 downto 0) := b"001";
    constant LT_BD_MODE  : std_logic_vector(2 downto 0) := b"100";
    constant GE_BD_MODE  : std_logic_vector(2 downto 0) := b"101";
    constant LTU_BD_MODE : std_logic_vector(2 downto 0) := b"110";
    constant GEU_BD_MODE : std_logic_vector(2 downto 0) := b"111";

    -- lsu data type --

    constant LSU_BYTE  : std_logic_vector(2 downto 0) := b"000";
    constant LSU_BYTEU : std_logic_vector(2 downto 0) := b"100";
    constant LSU_HALF  : std_logic_vector(2 downto 0) := b"001";
    constant LSU_HALFU : std_logic_vector(2 downto 0) := b"101";
    constant LSU_WORD  : std_logic_vector(2 downto 0) := b"010";

    component if_stage is
        generic (
            RESET_ADDR : std_logic_vector(31 downto 0) := (others => '0')
        );
        port (
            clk        : in  std_logic;
            reset      : in  std_logic;
            pcwr_en    : in  std_logic;
            imrd_err   : in  std_logic;
            taken      : in  std_logic;
            target     : in  std_logic_vector(31 downto 0);
            imrd_data  : in  std_logic_vector(31 downto 0);
            imrd_en    : out std_logic;
            imrd_fault : out std_logic;
            flush      : out std_logic;
            imrd_addr  : out std_logic_vector(31 downto 0);
            pc         : out std_logic_vector(31 downto 0);
            next_pc    : out std_logic_vector(31 downto 0);
            instr      : out std_logic_vector(31 downto 0)
        );
    end component if_stage;

    component imm_gen is
        port (
            payload : in  std_logic_vector(24 downto 0);
            itype   : in  std_logic_vector(2  downto 0);
            imm     : out std_logic_vector(31 downto 0)
        );
    end component imm_gen;

    component main_ctrl is
        port (
            flush     : in  std_logic;
            opcode    : in  std_logic_vector(6 downto 0);
            instr_err : out std_logic;
            imm_type  : out std_logic_vector(2 downto 0);
            istg_ctrl : out std_logic_vector(3 downto 0);
            exec_ctrl : out std_logic_vector(7 downto 0);
            dmls_ctrl : out std_logic_vector(1 downto 0)
        );
    end component main_ctrl;

    component id_block is
        port (
            flush     : in  std_logic;
            instr     : in  std_logic_vector(31 downto 0);
            instr_err : out std_logic;
            func3     : out std_logic_vector(2  downto 0);
            func7     : out std_logic_vector(6  downto 0);
            dmls_ctrl : out std_logic_vector(1  downto 0);
            istg_ctrl : out std_logic_vector(3  downto 0);
            exec_ctrl : out std_logic_vector(7  downto 0);
            csrs_addr : out std_logic_vector(11 downto 0);
            regs_addr : out std_logic_vector(14 downto 0);
            imm       : out std_logic_vector(31 downto 0)
        );
    end component id_block;

    component reg_file is
        generic (
            SIZE : natural := 32
        );
        port (
            clk      : in  std_logic;
            we       : in  std_logic;
            wr_addr  : in  std_logic_vector(4  downto 0);
            wr_data  : in  std_logic_vector(31 downto 0);
            rd_addr0 : in  std_logic_vector(4  downto 0);
            rd_addr1 : in  std_logic_vector(4  downto 0);
            rd_data0 : out std_logic_vector(31 downto 0);
            rd_data1 : out std_logic_vector(31 downto 0)
        );
    end component reg_file;

    component csrs_logic is
        port (
            csrwr_mode : in  std_logic_vector(2  downto 0);
            csrrd_data : in  std_logic_vector(31 downto 0);
            regwr_data : in  std_logic_vector(31 downto 0);
            immwr_data : in  std_logic_vector(31 downto 0);
            csrwr_data : out std_logic_vector(31 downto 0)
        );
    end component csrs_logic;

    component csrs is
        generic (
            MHART_ID : std_logic_vector(31 downto 0) := (others => '0')
        );
        port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            ex_irq      : in  std_logic;
            sw_irq      : in  std_logic;
            tm_irq      : in  std_logic;
            imrd_malgn  : in  std_logic;
            imrd_fault  : in  std_logic;
            instr_err   : in  std_logic;
            dmld_malgn  : in  std_logic;
            dmld_fault  : in  std_logic;
            dmst_malgn  : in  std_logic;
            dmst_fault  : in  std_logic;
            wr_en       : in  std_logic;
            wr_mode     : in  std_logic_vector(2  downto 0);
            rw_addr     : in  std_logic_vector(11 downto 0);
            wr_data     : in  std_logic_vector(31 downto 0);
            exec_res    : in  std_logic_vector(31 downto 0);
            pc          : in  std_logic_vector(31 downto 0);
            next_pc     : in  std_logic_vector(31 downto 0);
            cycle       : in  std_logic_vector(63 downto 0);
            timer       : in  std_logic_vector(63 downto 0);
            instret     : in  std_logic_vector(63 downto 0);
            pcwr_en     : out std_logic;
            trap_taken  : out std_logic;
            trap_target : out std_logic_vector(31 downto 0);
            rd_data     : out std_logic_vector(31 downto 0)
        );
    end component csrs;

    component istg_block is
        generic (
            REG_FILE_SIZE : natural := 32;
            CSRS_MHART_ID : std_logic_vector(31 downto 0) := (others => '0')
        );
        port (
            clk        : in  std_logic;
            reset      : in  std_logic;
            ex_irq     : in  std_logic;
            sw_irq     : in  std_logic;
            tm_irq     : in  std_logic;
            instr_err  : in  std_logic;
            imrd_malgn : in  std_logic;
            imrd_fault : in  std_logic;
            dmld_malgn : in  std_logic;
            dmld_fault : in  std_logic;
            dmst_malgn : in  std_logic;
            dmst_fault : in  std_logic;
            cycle      : in  std_logic_vector(63 downto 0);
            timer      : in  std_logic_vector(63 downto 0);
            instret    : in  std_logic_vector(63 downto 0);
            exec_res   : in  std_logic_vector(31 downto 0);
            dmld_data  : in  std_logic_vector(31 downto 0);
            pc         : in  std_logic_vector(31 downto 0);
            next_pc    : in  std_logic_vector(31 downto 0);
            imm        : in  std_logic_vector(31 downto 0);
            func3      : in  std_logic_vector(2  downto 0);
            regs_addr  : in  std_logic_vector(14 downto 0);
            csrs_addr  : in  std_logic_vector(11 downto 0);
            istg_ctrl  : in  std_logic_vector(3  downto 0);
            pcwr_en    : out std_logic;
            trap_taken : out std_logic;
            trap_target: out std_logic_vector(31 downto 0);
            rd_data0   : out std_logic_vector(31 downto 0);
            rd_data1   : out std_logic_vector(31 downto 0)
        );
    end component istg_block;    

    component alu is
        port(
            opd0 : in  std_logic_vector(31 downto 0);
            opd1 : in  std_logic_vector(31 downto 0);
            op   : in  std_logic_vector(5  downto 0);
            res  : out std_logic_vector(31 downto 0)
        );
    end component alu;

    component alu_ctrl is
        port (
            op_en : in  std_logic;
            ftype : in  std_logic;
            func3 : in  std_logic_vector(2 downto 0);
            func7 : in  std_logic_vector(6 downto 0);
            op    : out std_logic_vector(5 downto 0)
        );
    end component alu_ctrl;

    component br_detector is
        port (
            reg0   : in  std_logic_vector(31 downto 0); 
            reg1   : in  std_logic_vector(31 downto 0);
            mode   : in  std_logic_vector(2  downto 0);
            en     : in  std_logic;
            branch : out std_logic
        );
    end component br_detector;

    component ex_block is
        port (
            trap_taken  : in  std_logic;
            trap_target : in  std_logic_vector(31 downto 0);
            func3       : in  std_logic_vector(2  downto 0);
            func7       : in  std_logic_vector(6  downto 0);
            reg0        : in  std_logic_vector(31 downto 0);
            reg1        : in  std_logic_vector(31 downto 0);
            pc          : in  std_logic_vector(31 downto 0);
            imm         : in  std_logic_vector(31 downto 0);
            exec_ctrl   : in  std_logic_vector(7  downto 0);
            imrd_malgn  : out std_logic;
            taken       : out std_logic;
            target      : out std_logic_vector(31 downto 0);
            res         : out std_logic_vector(31 downto 0)
        );
    end component ex_block;

    component dmls_block is
        port (
            dmrd_err   : in  std_logic;
            dmwr_err   : in  std_logic;
            dmls_ctrl  : in  std_logic_vector(1  downto 0);
            dmls_dtype : in  std_logic_vector(2  downto 0);
            dmst_data  : in  std_logic_vector(31 downto 0);
            dmls_addr  : in  std_logic_vector(31 downto 0);
            dmrd_data  : in  std_logic_vector(31 downto 0);
            dmld_malgn : out std_logic;
            dmld_fault : out std_logic;
            dmst_malgn : out std_logic;
            dmst_fault : out std_logic;
            dmrd_en    : out std_logic; 
            dmwr_en    : out std_logic;
            dmwr_data  : out std_logic_vector(31 downto 0);
            dmrw_addr  : out std_logic_vector(31 downto 0);
            dm_byte_en : out std_logic_vector(3  downto 0);
            dmld_data  : out std_logic_vector(31 downto 0)       
        );
    end component dmls_block;

    component id_ex_stage is
        generic (
            REG_FILE_SIZE : natural := 32;
            CSRS_MHART_ID : std_logic_vector(31 downto 0) := (others => '0')
        );
        port (
            clk        : in  std_logic;
            reset      : in  std_logic;
            ex_irq     : in  std_logic;
            sw_irq     : in  std_logic;
            tm_irq     : in  std_logic;
            dmrd_err   : in  std_logic;
            dmwr_err   : in  std_logic;
            imrd_fault : in  std_logic;
            flush      : in  std_logic;
            instr      : in  std_logic_vector(31 downto 0);
            pc         : in  std_logic_vector(31 downto 0);
            next_pc    : in  std_logic_vector(31 downto 0);
            dmrd_data  : in  std_logic_vector(31 downto 0);
            cycle      : in  std_logic_vector(63 downto 0);
            timer      : in  std_logic_vector(63 downto 0);
            instret    : in  std_logic_vector(63 downto 0);
            dmrd_en    : out std_logic;
            dmwr_en    : out std_logic;
            pcwr_en    : out std_logic;
            taken      : out std_logic;
            target     : out std_logic_vector(31 downto 0);
            dmwr_data  : out std_logic_vector(31 downto 0);
            dmrw_addr  : out std_logic_vector(31 downto 0);
            dm_byte_en : out std_logic_vector(3  downto 0)
        );
    end component id_ex_stage;

    component core is
        generic (
            RESET_ADDR    : std_logic_vector(31 downto 0) := (others => '0');
            CSRS_MHART_ID : std_logic_vector(31 downto 0) := (others => '0');
            REG_FILE_SIZE : natural := 32
        );
        port (
            clk       : in  std_logic; 
            reset     : in  std_logic;
            ex_irq    : in  std_logic;
            sw_irq    : in  std_logic;
            tm_irq    : in  std_logic;
            imrd_err  : in  std_logic;
            dmrd_err  : in  std_logic;
            dmwr_err  : in  std_logic;
            imrd_data : in  std_logic_vector(31 downto 0);
            dmrd_data : in  std_logic_vector(31 downto 0);
            cycle     : in  std_logic_vector(63 downto 0);
            timer     : in  std_logic_vector(63 downto 0);
            instret   : in  std_logic_vector(63 downto 0);
            imrd_en   : out std_logic;
            dmrd_en   : out std_logic;
            dmwr_en   : out std_logic;
            dmwr_be   : out std_logic_vector(3  downto 0);
            imrd_addr : out std_logic_vector(31 downto 0);
            dmrw_addr : out std_logic_vector(31 downto 0);
            dmwr_data : out std_logic_vector(31 downto 0)
        );
    end component core;

    component leaf is
        generic (
            RESET_ADDR    : std_logic_vector(31 downto 0) := (others => '0');
            CSRS_MHART_ID : std_logic_vector(31 downto 0) := (others => '0');
            REG_FILE_SIZE : natural := 32
        );
        port (
            clk_i  : in  std_logic;
            rst_i  : in  std_logic;
            ex_irq : in  std_logic;
            sw_irq : in  std_logic;
            tm_irq : in  std_logic;
            ack_i  : in  std_logic;
            err_i  : in  std_logic;
            dat_i  : in  std_logic_vector(31 downto 0);
            cyc_o  : out std_logic;
            stb_o  : out std_logic;
            we_o   : out std_logic;
            sel_o  : out std_logic_vector(3  downto 0);
            adr_o  : out std_logic_vector(31 downto 0);
            dat_o  : out std_logic_vector(31 downto 0)
        );
    end component leaf;

    component wb_ctrl is
        port (
            clk_i     : in  std_logic;
            rst_i     : in  std_logic;
            imrd_en   : in  std_logic;
            dmrd_en   : in  std_logic;
            dmwr_en   : in  std_logic;
            ack_i     : in  std_logic;
            err_i     : in  std_logic;
            dat_i     : in  std_logic_vector(31 downto 0);
            dmwr_be   : in  std_logic_vector(3  downto 0);
            imrd_addr : in  std_logic_vector(31 downto 0);
            dmrw_addr : in  std_logic_vector(31 downto 0);
            dmwr_data : in  std_logic_vector(31 downto 0);
            cyc_o     : out std_logic;
            stb_o     : out std_logic;
            we_o      : out std_logic;
            clk_en    : out std_logic;
            reset     : out std_logic;
            imrd_err  : out std_logic;
            dmrd_err  : out std_logic;
            dmwr_err  : out std_logic;
            sel_o     : out std_logic_vector(3  downto 0);
            adr_o     : out std_logic_vector(31 downto 0);
            dat_o     : out std_logic_vector(31 downto 0);
            imrd_data : out std_logic_vector(31 downto 0);
            dmrd_data : out std_logic_vector(31 downto 0)
        );
    end component wb_ctrl;

    component counters is
        port (
            clk     : in  std_logic;
            reset   : in  std_logic;
            cycle   : out std_logic_vector(63 downto 0);
            timer   : out std_logic_vector(63 downto 0);
            instret : out std_logic_vector(63 downto 0)
        );
    end component counters;

    component clk_ctrl is
        port (
            clk_i  : in  std_logic;
            rst_i  : in  std_logic;
            clk_en : in  std_logic;
            clk    : out std_logic
        );
    end component clk_ctrl;
    
end package core_pkg;