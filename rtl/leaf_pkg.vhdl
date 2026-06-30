----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- package: leaf package
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package leaf_pkg is

    constant XLEN : natural := 32;

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

    -- Custom machine-mode CSR window for coprocessors --

    constant CSR_ADDR_COP0_MIN : std_logic_vector(11 downto 0) := x"7C0";
    constant CSR_ADDR_COP0_MAX : std_logic_vector(11 downto 0) := x"7FF";

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

    -- branch op --

    constant BR_NONE   : std_logic_vector(1 downto 0) := "00";
    constant BR_BRANCH : std_logic_vector(1 downto 0) := "01";
    constant BR_JUMP   : std_logic_vector(1 downto 0) := "10";

    -- lsu data type --

    constant LSU_BYTE  : std_logic_vector(2 downto 0) := b"000";
    constant LSU_BYTEU : std_logic_vector(2 downto 0) := b"100";
    constant LSU_HALF  : std_logic_vector(2 downto 0) := b"001";
    constant LSU_HALFU : std_logic_vector(2 downto 0) := b"101";
    constant LSU_WORD  : std_logic_vector(2 downto 0) := b"010";

    -- dmls ctrl --
    constant DMLS_IDLE  : std_logic_vector(1 downto 0) := "00";
    constant DMLS_LOAD  : std_logic_vector(1 downto 0) := "01";
    constant DMLS_STORE : std_logic_vector(1 downto 0) := "10";

    component if_stage is
        generic (
            RESET_ADDR : std_logic_vector(XLEN-1 downto 0) := (others => '0')
        );
        port (
            clk_i        : in  std_logic;
            reset_i      : in  std_logic;
        ready_i      : in  std_logic;
        inst_ack_i   : in  std_logic;
            inst_err_i   : in  std_logic;
            taken_i : in  std_logic;
            target_i : in  std_logic_vector(XLEN-1 downto 0);
            inst_dat_i   : in  std_logic_vector(XLEN-1 downto 0);
            inst_err_o   : out std_logic;
            inst_cyc_o   : out std_logic;
            inst_stb_o   : out std_logic;
            valid_o      : out std_logic;
            inst_adr_o   : out std_logic_vector(XLEN-1 downto 2);
            pc_o         : out std_logic_vector(XLEN-1 downto 2);
            next_pc_o    : out std_logic_vector(XLEN-1 downto 2);
            inst_o       : out std_logic_vector(XLEN-1 downto 0);
            retire_o     : out std_logic
        );
    end component if_stage;

    component main_ctrl is
        port (
            imrd_malgn_i   : in std_logic;
            imrd_fault_i   : in std_logic;
            dmld_malgn_i   : in std_logic;
            dmld_fault_i   : in std_logic;
            dmst_malgn_i   : in std_logic;
            dmst_fault_i   : in std_logic;
            instr_i        : in  std_logic_vector(XLEN-1 downto 0);
            valid_i        : in  std_logic;
            mip_meip_i     : in  std_logic;
            mip_msip_i     : in  std_logic;
            mip_mtip_i     : in  std_logic;
            mie_meie_i     : in  std_logic;
            mie_mtie_i     : in  std_logic;
            mie_msie_i     : in  std_logic;
            mstatus_mie_i  : in  std_logic;
            mepc_i         : in  std_logic_vector(XLEN-1 downto 2);
            mtvec_base_i   : in  std_logic_vector(XLEN-1 downto 2);
            instr_err_o    : out std_logic;
            ecall_o        : out std_logic;
            ebreak_o       : out std_logic;
            mret_o         : out std_logic;
            wfi_o          : out std_logic;
            csrwr_en_o     : out std_logic;
            regwr_en_o     : out std_logic;
            regwr_sel_o    : out std_logic_vector(1  downto 0);
            dmls_ctrl_o    : out std_logic_vector(1  downto 0);
            branch_op_o    : out std_logic_vector(1  downto 0);
            opd0_src_sel_o : out std_logic;
            opd1_src_sel_o : out std_logic;
            opd0_pass_o    : out std_logic;
            opd1_pass_o    : out std_logic;
            alu_op_o       : out std_logic_vector(5  downto 0);
            imm_o          : out std_logic_vector(XLEN-1 downto 0);
            func3_o        : out std_logic_vector(2  downto 0);
            regwr_addr_o   : out std_logic_vector(4  downto 0);
            regrd_addr0_o  : out std_logic_vector(4  downto 0);
            regrd_addr1_o  : out std_logic_vector(4  downto 0);
            csrs_addr_o    : out std_logic_vector(11 downto 0);
            ready_i        : in  std_logic;
            ready_o        : out std_logic;
            exc_taken_o   : out std_logic;
            int_taken_o   : out std_logic;
            exi_taken_o   : out std_logic;
            tmi_taken_o   : out std_logic;
            swi_taken_o   : out std_logic;
            trap_taken_o   : out std_logic;
            trap_target_o  : out std_logic_vector(XLEN-1 downto 0)
        );
    end component main_ctrl;

    component reg_file is
        generic (
            SIZE : natural := 32
        );
        port (
            clk_i      : in  std_logic;
            we_i       : in  std_logic;
            wr_sel_i   : in  std_logic_vector(1 downto 0);
            wr_addr_i  : in  std_logic_vector(4  downto 0);
            wr_data0_i : in  std_logic_vector(XLEN-1 downto 0);
            wr_data1_i : in  std_logic_vector(XLEN-1 downto 0);
            wr_data2_i : in  std_logic_vector(XLEN-1 downto 0);
            wr_data3_i : in  std_logic_vector(XLEN-1 downto 0);
            rd_addr0_i : in  std_logic_vector(4  downto 0);
            rd_addr1_i : in  std_logic_vector(4  downto 0);
            rd_data0_o : out std_logic_vector(XLEN-1 downto 0);
            rd_data1_o : out std_logic_vector(XLEN-1 downto 0)
        );
    end component reg_file;

    component csrs_logic is
        port (
            csrwr_mode_i : in  std_logic_vector(2           downto 0);
            csrrd_data_i : in  std_logic_vector(XLEN-1      downto 0);
            regwr_data_i : in  std_logic_vector(XLEN-1      downto 0);
            immwr_data_i : in  std_logic_vector(XLEN-1      downto 0);
            csrwr_data_o : out std_logic_vector(XLEN-1      downto 0)
        );
    end component csrs_logic;

    component csrs is
        generic (
            MHART_ID : std_logic_vector(XLEN-1 downto 0) := (others => '0')
        );
        port (
            clk_i        : in  std_logic;
            reset_i      : in  std_logic;
            ex_irq_i     : in  std_logic;
            sw_irq_i     : in  std_logic;
            tm_irq_i     : in  std_logic;
            imrd_malgn_i : in  std_logic;
            imrd_fault_i : in  std_logic;
            instr_err_i  : in  std_logic;
            dmld_malgn_i : in  std_logic;
            dmld_fault_i : in  std_logic;
            dmst_malgn_i : in  std_logic;
            dmst_fault_i : in  std_logic;
            ecall_i      : in  std_logic;
            ebreak_i     : in  std_logic;
            mret_i       : in  std_logic;
            wfi_i        : in  std_logic;
            exc_taken_i  : in  std_logic;
            int_taken_i  : in  std_logic;
            exi_taken_i  : in  std_logic;
            tmi_taken_i  : in  std_logic;
            swi_taken_i  : in  std_logic;
            wr_en_i      : in  std_logic;
            wr_addr_i    : in  std_logic_vector(11 downto 0);
            rw_addr_i    : in  std_logic_vector(11 downto 0);
            wr_data_i    : in  std_logic_vector(XLEN-1 downto 0);
            exec_res_i   : in  std_logic_vector(XLEN-1 downto 0);
            pc_i         : in  std_logic_vector(XLEN-1 downto 0);
            fault_pc_i   : in  std_logic_vector(XLEN-1 downto 0);
            next_pc_i    : in  std_logic_vector(XLEN-1 downto 0);
            cycle_i      : in  std_logic_vector(63 downto 0);
            timer_i      : in  std_logic_vector(63 downto 0);
            instret_i    : in  std_logic_vector(63 downto 0);
            cop_dat_i    : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
            cop_adr_o    : out std_logic_vector(5 downto 0);
            cop_dat_o    : out std_logic_vector(XLEN-1 downto 0);
            cop_we_o     : out std_logic;
            mie_meie_o   : out std_logic;
            mie_mtie_o   : out std_logic;
            mie_msie_o   : out std_logic;
            mstatus_mie_o: out std_logic;
            mip_meip_o   : out std_logic;
            mip_mtip_o   : out std_logic;
            mip_msip_o   : out std_logic;
            mepc_o       : out std_logic_vector(XLEN-1 downto 2);
            mtvec_base_o : out std_logic_vector(XLEN-1 downto 2);
            rd_data_o    : out std_logic_vector(XLEN-1 downto 0)
        );
    end component csrs;

    component id_stage is
        generic (
            REG_FILE_SIZE : natural := 32;
            CSRS_MHART_ID : std_logic_vector(XLEN-1 downto 0) := (others => '0')
        );
        port (
            clk_i         : in  std_logic;
            reset_i       : in  std_logic;
            ex_irq_i      : in  std_logic;
            sw_irq_i      : in  std_logic;
            tm_irq_i      : in  std_logic;
            imrd_malgn_i  : in  std_logic;
            dmld_malgn_i  : in  std_logic;
            dmld_fault_i  : in  std_logic;
            dmst_malgn_i  : in  std_logic;
            dmst_fault_i  : in  std_logic;
            cycle_i       : in  std_logic_vector(63 downto 0);
            timer_i       : in  std_logic_vector(63 downto 0);
            instret_i     : in  std_logic_vector(63 downto 0);
            exec_res_i    : in  std_logic_vector(XLEN-1 downto 0);
            dmld_data_i   : in  std_logic_vector(XLEN-1 downto 0);
            pc_i          : in  std_logic_vector(XLEN-1 downto 2);
            next_pc_i     : in  std_logic_vector(XLEN-1 downto 2);
            instr_i       : in  std_logic_vector(XLEN-1 downto 0);
            fault_i       : in  std_logic;
            valid_i       : in  std_logic;
            cop_dat_i     : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
            cop_adr_o     : out std_logic_vector(5 downto 0);
            cop_dat_o     : out std_logic_vector(XLEN-1 downto 0);
            cop_we_o      : out std_logic;
            csr_wr_data_i : in  std_logic_vector(XLEN-1 downto 0);
            ready_i       : in  std_logic;
            ready_o       : out std_logic;
            func3_o       : out std_logic_vector(2  downto 0);
            branch_op_o   : out std_logic_vector(1  downto 0);
            alu_op_o      : out std_logic_vector(5  downto 0);
            dmls_ctrl_o   : out std_logic_vector(1  downto 0);
            trap_taken_o  : out std_logic;
            trap_target_o : out std_logic_vector(XLEN-1 downto 0);
            rd_data0_o    : out std_logic_vector(XLEN-1 downto 0);
            rd_data1_o    : out std_logic_vector(XLEN-1 downto 0);
            csrrd_data_o  : out std_logic_vector(XLEN-1 downto 0);
            imm_o         : out std_logic_vector(XLEN-1 downto 0);
            opd0_src_sel_o : out std_logic;
            opd1_src_sel_o : out std_logic;
            opd0_pass_o    : out std_logic;
            opd1_pass_o    : out std_logic;
            pc_full_o     : out std_logic_vector(XLEN-1 downto 0)
        );
    end component id_stage;

    component alu is
        port(
            opd0_i : in  std_logic_vector(XLEN-1 downto 0);
            opd1_i : in  std_logic_vector(XLEN-1 downto 0);
            op_i   : in  std_logic_vector(5          downto 0);
            res_o  : out std_logic_vector(XLEN-1 downto 0)
        );
    end component alu;

    component br_detector is
        port (
            reg0_i       : in  std_logic_vector(XLEN-1 downto 0);
            reg1_i       : in  std_logic_vector(XLEN-1 downto 0);
            mode_i       : in  std_logic_vector(2           downto 0);
            en_i         : in  std_logic;
            jmp_i        : in  std_logic;
            alu_res_i    : in  std_logic_vector(XLEN-1 downto 0);
            trap_taken_i : in  std_logic;
            trap_target_i: in  std_logic_vector(XLEN-1 downto 0);
            branch_o     : out std_logic;
            taken_o      : out std_logic;
            target_o     : out std_logic_vector(XLEN-1 downto 0);
            imrd_malgn_o : out std_logic
        );
    end component br_detector;

    component ex_block is
        port (
            clk_i         : in  std_logic;
            reset_i       : in  std_logic;
            trap_taken_i  : in  std_logic;
            trap_target_i : in  std_logic_vector(XLEN-1 downto 0);
            func3_i       : in  std_logic_vector(2  downto 0);
            reg0_i        : in  std_logic_vector(XLEN-1 downto 0);
            reg1_i        : in  std_logic_vector(XLEN-1 downto 0);
            pc_i          : in  std_logic_vector(XLEN-1 downto 0);
            opd0_src_sel_i : in  std_logic;
            opd1_src_sel_i : in  std_logic;
            opd0_pass_i    : in  std_logic;
            opd1_pass_i    : in  std_logic;
            branch_op_i   : in  std_logic_vector(1  downto 0);
            alu_op_i      : in  std_logic_vector(5  downto 0);
            dmls_ctrl_i   : in  std_logic_vector(1  downto 0);
            data_dat_i   : in  std_logic_vector(XLEN-1 downto 0);
            data_ack_i   : in  std_logic;
            data_err_i   : in  std_logic;
            csrrd_data_i  : in  std_logic_vector(XLEN-1 downto 0);
            immwr_data_i  : in  std_logic_vector(XLEN-1 downto 0);
            csrwr_data_o  : out std_logic_vector(XLEN-1 downto 0);
            imrd_malgn_o  : out std_logic;
            dmld_malgn_o  : out std_logic;
            dmld_fault_o  : out std_logic;
            dmst_malgn_o  : out std_logic;
            dmst_fault_o  : out std_logic;
            data_cyc_o         : out std_logic;
            data_stb_o         : out std_logic;
            data_dat_o   : out std_logic_vector(XLEN-1 downto 0);
            data_adr_o   : out std_logic_vector(XLEN-1 downto 2);
            data_sel_o  : out std_logic_vector(3  downto 0);
            data_we_o   : out std_logic;
            dmld_data_o   : out std_logic_vector(XLEN-1 downto 0);
            taken_o  : out std_logic;
            target_o : out std_logic_vector(XLEN-1 downto 0);
            ready_o       : out std_logic;
            branch_o      : out std_logic;
            res_o         : out std_logic_vector(XLEN-1 downto 0);
            valid_i       : in  std_logic
        );
    end component ex_block;

    component dmls_block is
        port (
            clk_i        : in  std_logic;
            reset_i      : in  std_logic;
            dmls_ctrl_i  : in  std_logic_vector(1           downto 0);
            dmls_dtype_i : in  std_logic_vector(2           downto 0);
            dmst_data_i  : in  std_logic_vector(XLEN-1      downto 0);
            dmls_addr_i  : in  std_logic_vector(XLEN-1      downto 0);
            data_dat_i  : in  std_logic_vector(XLEN-1      downto 0);
            data_ack_i  : in  std_logic;
            data_err_i  : in  std_logic;
            dmld_malgn_o : out std_logic;
            dmld_fault_o : out std_logic;
            dmst_malgn_o : out std_logic;
            dmst_fault_o : out std_logic;
            data_cyc_o   : out std_logic;
            data_stb_o   : out std_logic;
            data_dat_o  : out std_logic_vector(XLEN-1      downto 0);
            data_adr_o  : out std_logic_vector(XLEN-1      downto 2);
            data_sel_o : out std_logic_vector(3           downto 0);
            data_we_o  : out std_logic;
            dmls_ready_o : out std_logic;
            dmld_data_o  : out std_logic_vector(XLEN-1      downto 0)
        );
    end component dmls_block;

    component core is
        generic (
            RESET_ADDR    : std_logic_vector(XLEN-1 downto 0) := (others => '0');
            CSRS_MHART_ID : std_logic_vector(XLEN-1 downto 0) := (others => '0');
            REG_FILE_SIZE : natural := 32
        );
        port (
        clk_i       : in  std_logic;
        reset_i     : in  std_logic;
        ex_irq_i    : in  std_logic;
        sw_irq_i    : in  std_logic;
        tm_irq_i    : in  std_logic;
        inst_err_i  : in  std_logic;
        inst_ack_i  : in  std_logic;
        inst_dat_i  : in  std_logic_vector(XLEN-1 downto 0);
        inst_cyc_o  : out std_logic;
        inst_stb_o  : out std_logic;
        inst_adr_o  : out std_logic_vector(XLEN-1 downto 2);
        data_dat_i : in  std_logic_vector(XLEN-1 downto 0);
        data_ack_i : in  std_logic;
        data_err_i : in  std_logic;
        cycle_i     : in  std_logic_vector(63 downto 0);
        timer_i     : in  std_logic_vector(63 downto 0);
        instret_i   : in  std_logic_vector(63 downto 0);
        cop_dat_i   : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o   : out std_logic_vector(5 downto 0);
        cop_dat_o   : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o    : out std_logic;
        retire_o    : out std_logic;
        data_cyc_o  : out std_logic;
        data_stb_o  : out std_logic;
        data_we_o   : out std_logic;
        data_sel_o   : out std_logic_vector(3         downto 0);
        data_adr_o : out std_logic_vector(XLEN-1 downto 2);
            data_dat_o : out std_logic_vector(XLEN-1 downto 0)
        );
    end component core;

    component leaf is
        generic (
            RESET_ADDR    : std_logic_vector(XLEN-1 downto 0) := (others => '0');
            CSRS_MHART_ID : std_logic_vector(XLEN-1 downto 0) := (others => '0');
            REG_FILE_SIZE : natural := 32
        );
        port (
            clk_i     : in  std_logic;
            rst_i     : in  std_logic;
            ex_irq_i  : in  std_logic;
            sw_irq_i  : in  std_logic;
            tm_irq_i  : in  std_logic;
            ack_i     : in  std_logic;
            err_i     : in  std_logic;
            dat_i     : in  std_logic_vector(XLEN-1 downto 0);
            cop_dat_i : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
            cop_adr_o : out std_logic_vector(5 downto 0);
            cop_dat_o : out std_logic_vector(XLEN-1 downto 0);
            cop_we_o  : out std_logic;
            cyc_o     : out std_logic;
            stb_o     : out std_logic;
            we_o      : out std_logic;
            sel_o     : out std_logic_vector(3         downto 0);
            adr_o     : out std_logic_vector(XLEN-1 downto 2);
            dat_o     : out std_logic_vector(XLEN-1 downto 0)
        );
    end component leaf;

    component counters is
        port (
            clk_i    : in  std_logic;
            reset_i  : in  std_logic;
            retire_i : in  std_logic;
            cycle_o  : out std_logic_vector(63 downto 0);
            timer_o  : out std_logic_vector(63 downto 0);
            instret_o: out std_logic_vector(63 downto 0)
        );
    end component counters;

    component wb_arbiter is
        port (
            clk_i    : in  std_logic;
            rst_i    : in  std_logic;

            inst_cyc_i : in  std_logic;
            inst_stb_i : in  std_logic;
            inst_adr_i : in  std_logic_vector(XLEN-1 downto 2);
            inst_ack_o : out std_logic;
            inst_err_o : out std_logic;

            data_cyc_i : in  std_logic;
            data_stb_i : in  std_logic;
            data_adr_i : in  std_logic_vector(XLEN-1 downto 2);
            data_sel_i : in  std_logic_vector(3 downto 0);
            data_we_i  : in  std_logic;
            data_dat_i : in  std_logic_vector(XLEN-1 downto 0);
            data_ack_o : out std_logic;
            data_err_o : out std_logic;

            cyc_o   : out std_logic;
            stb_o   : out std_logic;
            adr_o   : out std_logic_vector(XLEN-1 downto 2);
            sel_o   : out std_logic_vector(3 downto 0);
            we_o    : out std_logic;
            dat_o   : out std_logic_vector(XLEN-1 downto 0);
            ack_i   : in  std_logic;
            err_i   : in  std_logic;
            dat_i   : in  std_logic_vector(XLEN-1 downto 0);
            inst_dat_o : out std_logic_vector(XLEN-1 downto 0);
            data_dat_o : out std_logic_vector(XLEN-1 downto 0)
        );
    end component wb_arbiter;

end package leaf_pkg;
