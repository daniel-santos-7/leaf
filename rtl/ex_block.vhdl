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
        -- The trap redirect target, resolved in csrs: exception versus mret
        -- only picks mtvec over mepc, and both registers live over there. Its
        -- taken side is decided here, in trap_ctrl.
        trap_target_i  : in  std_logic_vector(XLEN-1 downto 0);
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

        -- The trap cause set, decoded and registered in trap_decode, plus the
        -- pipeline advance and the interrupts it ranks. trap_ctrl below closes
        -- the decision over the faults raised here.
        instr_err_i    : in  std_logic;
        fetch_fault_i  : in  std_logic;
        ebreak_i       : in  std_logic;
        mret_i         : in  std_logic;
        wfi_i          : in  std_logic;
        exc_cause_i    : in  std_logic;
        retire_i       : in  std_logic;
        pipe_en_i      : in  std_logic;
        exi_taken_i    : in  std_logic;
        tmi_taken_i    : in  std_logic;
        swi_taken_i    : in  std_logic;
        -- main_ctrl's write enables, registered there; they leave gated by the
        -- EX faults below.
        regwr_en_i     : in  std_logic;
        csrwr_en_i     : in  std_logic;

        ready_o        : out std_logic;
        flush_o        : out std_logic;
        taken_o        : out std_logic;
        target_o       : out std_logic_vector(XLEN-1 downto 0);
        res_o          : out std_logic_vector(XLEN-1 downto 0);
        -- pc+4, out of the alu's own incrementer: the JAL/JALR link address,
        -- and the mepc a wfi trap stacks -- csrs reads this one instead of
        -- building a second.
        pc_next_o      : out std_logic_vector(XLEN-1 downto 0);
        -- The funct3 mux over csrrd_data/reg0/imm, handed straight back to the
        -- csrs write port in id_stage: its operands are the same post-pipeline
        -- values the alu reads, so the mux belongs on this side of the register.
        csrwr_data_o   : out std_logic_vector(XLEN-1 downto 0);
        dmld_data_o    : out std_logic_vector(XLEN-1 downto 0);

        -- What the trap commits, for csrs and the register file back in
        -- id_stage. The five faults these are resolved from stay here: nothing
        -- outside trap_ctrl reads them apart.
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

    signal csrs_logic_csrwr_data : std_logic_vector(XLEN-1 downto 0);

    signal trap_ctrl_exc_taken  : std_logic;
    signal trap_ctrl_taken      : std_logic;
    signal trap_ctrl_mcause_exc : std_logic_vector(4 downto 0);
    signal trap_ctrl_mtval      : std_logic_vector(XLEN-1 downto 0);
    signal trap_ctrl_mepc       : std_logic_vector(XLEN-1 downto 2);
    signal trap_ctrl_regwr_en   : std_logic;
    signal trap_ctrl_csrwr_en   : std_logic;
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
        trap_target_i  => trap_target_i,
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
        instr_err_i    => instr_err_i,
        fetch_fault_i  => fetch_fault_i,
        ebreak_i       => ebreak_i,
        mret_i         => mret_i,
        wfi_i          => wfi_i,
        exc_cause_i    => exc_cause_i,
        retire_i       => retire_i,
        pipe_en_i      => pipe_en_i,
        exi_taken_i    => exi_taken_i,
        tmi_taken_i    => tmi_taken_i,
        swi_taken_i    => swi_taken_i,
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
        exc_taken_o    => trap_ctrl_exc_taken,
        taken_o        => trap_ctrl_taken,
        mcause_exc_o   => trap_ctrl_mcause_exc,
        mtval_o        => trap_ctrl_mtval,
        mepc_o         => trap_ctrl_mepc,
        regwr_en_o     => trap_ctrl_regwr_en,
        csrwr_en_o     => trap_ctrl_csrwr_en,
        retire_o       => trap_ctrl_retire
    );

    exec_csrs_logic: csrs_logic port map (
        csrwr_mode_i => func3_i,
        csrrd_data_i => csrrd_data_i,
        regwr_data_i => reg0_i,
        immwr_data_i => immwr_data_i,
        csrwr_data_o => csrs_logic_csrwr_data
    );

    ready_o      <= dmls_block_dmls_ready;
    flush_o      <= br_detector_taken;
    taken_o      <= br_detector_taken;
    target_o     <= br_detector_target;
    res_o        <= alu_res;
    pc_next_o    <= alu_pc_next;
    csrwr_data_o <= csrs_logic_csrwr_data;
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
