----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: execution block
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

entity ex_block is
    port (
        clk_i          : in  std_logic;
        reset_i        : in  std_logic;
        mepc_reg_i     : in  std_logic_vector(XLEN-1 downto 2);
        mtvec_reg_i    : in  std_logic_vector(XLEN-1 downto 2);
        func3_i        : in  std_logic_vector(2  downto 0);
        reg0_i         : in  std_logic_vector(XLEN-1 downto 0);
        reg1_i         : in  std_logic_vector(XLEN-1 downto 0);
        pc_i           : in  std_logic_vector(XLEN-1 downto 0);
        immwr_data_i   : in  std_logic_vector(XLEN-1 downto 0);
        csrrd_data_i   : in  std_logic_vector(XLEN-1 downto 0);
        opd_src_sel_i  : in  std_logic_vector(1  downto 0);
        opd_pass_i     : in  std_logic_vector(1  downto 0);
        branch_op_i    : in  std_logic_vector(1  downto 0);
        alu_op_i       : in  std_logic_vector(5  downto 0);
        dmls_ctrl_i    : in  std_logic_vector(1  downto 0);
        redirect_ack_i : in  std_logic;

        instr_err_i    : in  std_logic;
        fetch_fault_i  : in  std_logic;
        ecall_i        : in  std_logic;
        ebreak_i       : in  std_logic;
        mret_i         : in  std_logic;
        wfi_i          : in  std_logic;
        int_trap_i     : in  std_logic;
        retire_i       : in  std_logic;
        pipe_en_i      : in  std_logic;
        exi_trap_i     : in  std_logic;
        tmi_trap_i     : in  std_logic;
        swi_trap_i     : in  std_logic;
        regwr_en_i     : in  std_logic;
        csrwr_en_i     : in  std_logic;

        ready_o        : out std_logic;
        flush_o        : out std_logic;
        taken_o        : out std_logic;
        target_o       : out std_logic_vector(XLEN-1 downto 0);
        res_o          : out std_logic_vector(XLEN-1 downto 0);
        pc_next_o      : out std_logic_vector(XLEN-1 downto 0);
        csrwr_data_o   : out std_logic_vector(XLEN-1 downto 0);
        dmld_data_o    : out std_logic_vector(XLEN-1 downto 0);

        exc_taken_o    : out std_logic;
        mcause_exc_o   : out std_logic_vector(4 downto 0);
        mtval_o        : out std_logic_vector(XLEN-1 downto 0);
        mepc_o         : out std_logic_vector(XLEN-1 downto 2);
        regwr_en_o     : out std_logic;
        csrwr_en_o     : out std_logic;
        retire_o       : out std_logic;

        data_cyc_o     : out std_logic;
        data_stb_o     : out std_logic;
        data_we_o      : out std_logic;
        data_sel_o     : out std_logic_vector(3      downto 0);
        data_adr_o     : out std_logic_vector(XLEN-1 downto 2);
        data_dat_o     : out std_logic_vector(XLEN-1 downto 0);
        data_dat_i     : in  std_logic_vector(XLEN-1 downto 0);
        data_ack_i     : in  std_logic;
        data_err_i     : in  std_logic;
        data_stall_i   : in  std_logic
    );
end entity ex_block;

architecture ex_block_arch of ex_block is

    signal alu_res       : std_logic_vector(XLEN-1 downto 0);
    signal alu_arith_res : std_logic_vector(XLEN-1 downto 0);
    signal alu_pc_next   : std_logic_vector(XLEN-1 downto 0);

    signal br_detector_taken      : std_logic;
    signal br_detector_target     : std_logic_vector(XLEN-1 downto 0);
    signal br_detector_imrd_malgn : std_logic;

    signal trap_ctrl_exc_taken  : std_logic;
    signal trap_ctrl_target     : std_logic_vector(XLEN-1 downto 0);
    signal trap_ctrl_taken      : std_logic;
    signal trap_ctrl_mcause_exc : std_logic_vector(4 downto 0);
    signal trap_ctrl_mtval      : std_logic_vector(XLEN-1 downto 0);
    signal trap_ctrl_mepc       : std_logic_vector(XLEN-1 downto 2);
    signal trap_ctrl_regwr_en   : std_logic;
    signal trap_ctrl_csrwr_en   : std_logic;
    signal trap_ctrl_csrwr_data : std_logic_vector(XLEN-1 downto 0);
    signal trap_ctrl_retire     : std_logic;

    signal dmls_block_dmls_ready : std_logic;
    signal dmls_block_dmld_data  : std_logic_vector(XLEN-1 downto 0);
    signal dmls_block_dmld_malgn : std_logic;
    signal dmls_block_dmld_fault : std_logic;
    signal dmls_block_dmst_malgn : std_logic;
    signal dmls_block_dmst_fault : std_logic;
    signal dmls_block_data_cyc   : std_logic;
    signal dmls_block_data_stb   : std_logic;
    signal dmls_block_data_we    : std_logic;
    signal dmls_block_data_sel   : std_logic_vector(3      downto 0);
    signal dmls_block_data_adr   : std_logic_vector(XLEN-1 downto 2);
    signal dmls_block_data_dat   : std_logic_vector(XLEN-1 downto 0);

begin

    exec_alu: alu port map (
        pc_i          => pc_i,
        reg0_i        => reg0_i,
        reg1_i        => reg1_i,
        immwr_data_i  => immwr_data_i,
        opd_src_sel_i => opd_src_sel_i,
        opd_pass_i    => opd_pass_i,
        op_i          => alu_op_i,
        res_o         => alu_res,
        arith_res_o   => alu_arith_res,
        pc_next_o     => alu_pc_next
    );

    exec_br_detector: br_detector port map (
        clk_i          => clk_i,
        reset_i        => reset_i,
        redirect_ack_i => redirect_ack_i,
        reg0_i         => reg0_i,
        reg1_i         => reg1_i,
        mode_i         => func3_i,
        en_i           => branch_op_i(0),
        jmp_i          => branch_op_i(1),
        arith_res_i    => alu_arith_res,
        trap_taken_i   => trap_ctrl_taken,
        trap_target_i  => trap_ctrl_target,
        taken_o        => br_detector_taken,
        target_o       => br_detector_target,
        imrd_malgn_o   => br_detector_imrd_malgn
    );

    exec_dmls_block: dmls_block port map (
        clk_i        => clk_i,
        reset_i      => reset_i,
        dmls_ctrl_i  => dmls_ctrl_i,
        dmls_dtype_i => func3_i,
        dmst_data_i  => reg1_i,
        arith_res_i  => alu_arith_res,
        data_dat_i   => data_dat_i,
        data_ack_i   => data_ack_i,
        data_err_i   => data_err_i,
        data_stall_i => data_stall_i,
        data_cyc_o   => dmls_block_data_cyc,
        data_stb_o   => dmls_block_data_stb,
        data_dat_o   => dmls_block_data_dat,
        data_adr_o   => dmls_block_data_adr,
        data_sel_o   => dmls_block_data_sel,
        data_we_o    => dmls_block_data_we,
        dmls_ready_o => dmls_block_dmls_ready,
        dmld_malgn_o => dmls_block_dmld_malgn,
        dmld_fault_o => dmls_block_dmld_fault,
        dmst_malgn_o => dmls_block_dmst_malgn,
        dmst_fault_o => dmls_block_dmst_fault,
        dmld_data_o  => dmls_block_dmld_data
    );

    exec_trap_ctrl: trap_ctrl port map (
        mepc_reg_i     => mepc_reg_i,
        mtvec_reg_i    => mtvec_reg_i,
        instr_err_i    => instr_err_i,
        fetch_fault_i  => fetch_fault_i,
        ecall_i        => ecall_i,
        ebreak_i       => ebreak_i,
        mret_i         => mret_i,
        wfi_i          => wfi_i,
        int_trap_i     => int_trap_i,
        retire_i       => retire_i,
        pipe_en_i      => pipe_en_i,
        exi_trap_i     => exi_trap_i,
        tmi_trap_i     => tmi_trap_i,
        swi_trap_i     => swi_trap_i,
        imrd_malgn_i   => br_detector_imrd_malgn,
        dmld_malgn_i   => dmls_block_dmld_malgn,
        dmld_fault_i   => dmls_block_dmld_fault,
        dmst_malgn_i   => dmls_block_dmst_malgn,
        dmst_fault_i   => dmls_block_dmst_fault,
        exec_res_i     => alu_res,
        pc_i           => pc_i,
        pc_next_i      => alu_pc_next(XLEN-1 downto 2),
        regwr_en_i     => regwr_en_i,
        csrwr_en_i     => csrwr_en_i,
        csrwr_mode_i   => func3_i,
        csrrd_data_i   => csrrd_data_i,
        regwr_data_i   => reg0_i,
        immwr_data_i   => immwr_data_i,
        exc_taken_o    => trap_ctrl_exc_taken,
        taken_o        => trap_ctrl_taken,
        target_o       => trap_ctrl_target,
        mcause_exc_o   => trap_ctrl_mcause_exc,
        mtval_o        => trap_ctrl_mtval,
        mepc_o         => trap_ctrl_mepc,
        regwr_en_o     => trap_ctrl_regwr_en,
        csrwr_en_o     => trap_ctrl_csrwr_en,
        csrwr_data_o   => trap_ctrl_csrwr_data,
        retire_o       => trap_ctrl_retire
    );

    ready_o      <= dmls_block_dmls_ready;
    flush_o      <= br_detector_taken;
    taken_o      <= br_detector_taken;
    target_o     <= br_detector_target;
    res_o        <= alu_res;
    pc_next_o    <= alu_pc_next;
    csrwr_data_o <= trap_ctrl_csrwr_data;
    dmld_data_o  <= dmls_block_dmld_data;

    exc_taken_o  <= trap_ctrl_exc_taken;
    mcause_exc_o <= trap_ctrl_mcause_exc;
    mtval_o      <= trap_ctrl_mtval;
    mepc_o       <= trap_ctrl_mepc;
    regwr_en_o   <= trap_ctrl_regwr_en;
    csrwr_en_o   <= trap_ctrl_csrwr_en;
    retire_o     <= trap_ctrl_retire;

    data_cyc_o   <= dmls_block_data_cyc;
    data_stb_o   <= dmls_block_data_stb;
    data_we_o    <= dmls_block_data_we;
    data_sel_o   <= dmls_block_data_sel;
    data_adr_o   <= dmls_block_data_adr;
    data_dat_o   <= dmls_block_data_dat;

end architecture ex_block_arch;
