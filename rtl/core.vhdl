library IEEE;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

entity core is
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
        inst_stall_i : in  std_logic;
        inst_dat_i  : in  std_logic_vector(XLEN-1 downto 0);
        inst_cyc_o  : out std_logic;
        inst_stb_o  : out std_logic;
        inst_adr_o  : out std_logic_vector(XLEN-1 downto 2);
        data_dat_i : in  std_logic_vector(XLEN-1 downto 0);
        data_ack_i : in  std_logic;
        data_err_i : in  std_logic;
        data_stall_i : in  std_logic;
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
        data_sel_o  : out std_logic_vector(3         downto 0);
        data_adr_o  : out std_logic_vector(XLEN-1 downto 2);
        data_dat_o  : out std_logic_vector(XLEN-1 downto 0)
    );
end entity core;

architecture rtl of core is

    signal ex_ready            : std_logic;
    signal id_ready            : std_logic;
    signal ex_taken            : std_logic;
    signal ex_target           : std_logic_vector(XLEN-1 downto 0);
    signal ex_flush            : std_logic;

    -- IF stage outputs
    signal if_pc      : std_logic_vector(XLEN-1 downto 2);
    signal if_next_pc : std_logic_vector(XLEN-1 downto 2);
    signal if_instr   : std_logic_vector(XLEN-1 downto 0);
    signal if_imrd_fault : std_logic;
    signal if_valid   : std_logic;
    signal if_stale   : std_logic;

    -- ID stage -> EX stage (pipeline register inside id_stage)
    signal ex_func3       : std_logic_vector(2  downto 0);
    signal ex_branch_op   : std_logic_vector(1  downto 0);
    signal ex_alu_op      : std_logic_vector(5  downto 0);
    signal ex_dmls_ctrl   : std_logic_vector(1  downto 0);
    signal ex_exc_taken   : std_logic;
    signal ex_mret        : std_logic;
    signal ex_mepc        : std_logic_vector(XLEN-1 downto 2);
    signal ex_mtvec_base  : std_logic_vector(XLEN-1 downto 2);
    signal ex_rd0         : std_logic_vector(XLEN-1 downto 0);
    signal ex_rd1         : std_logic_vector(XLEN-1 downto 0);
    signal ex_imm         : std_logic_vector(XLEN-1 downto 0);
    signal ex_opd0_src_sel : std_logic;
    signal ex_opd1_src_sel : std_logic;
    signal ex_opd0_pass    : std_logic;
    signal ex_opd1_pass    : std_logic;
    signal ex_pc_full     : std_logic_vector(XLEN-1 downto 0);
    signal ex_regwr_en    : std_logic;
    signal ex_csrwr_en    : std_logic;

    -- EX block outputs (loop back to ID stage)
    signal ex_res         : std_logic_vector(XLEN-1 downto 0);
    signal ex_dmld_data   : std_logic_vector(XLEN-1 downto 0);
    signal ex_imrd_malgn  : std_logic;
    signal ex_dmld_malgn  : std_logic;
    signal ex_dmld_fault  : std_logic;
    signal ex_dmst_malgn  : std_logic;
    signal ex_dmst_fault  : std_logic;
    signal ex_exc_fault   : std_logic;
    signal ex_rf_we       : std_logic;
    signal ex_csr_we      : std_logic;

begin

    -- instruction fetch stage --

    core_if_stage: if_stage generic map (
        RESET_ADDR => RESET_ADDR
    ) port map (
        clk_i        => clk_i,
        reset_i      => reset_i,
        ready_i      => id_ready,
        inst_ack_i   => inst_ack_i,
        inst_err_i   => inst_err_i,
        inst_stall_i => inst_stall_i,
        taken_i      => ex_taken,
        target_i     => ex_target,
        inst_dat_i   => inst_dat_i,
        inst_cyc_o   => inst_cyc_o,
        inst_stb_o   => inst_stb_o,
        inst_err_o   => if_imrd_fault,
        inst_adr_o   => inst_adr_o,
        pc_o         => if_pc,
        next_pc_o    => if_next_pc,
        inst_o       => if_instr,
        valid_o      => if_valid,
        stale_o      => if_stale,
        retire_o     => retire_o
    );

    -- instruction decode stage (contains pipeline register internally) --

    core_id_stage: id_stage generic map (
        REG_FILE_SIZE => REG_FILE_SIZE,
        CSRS_MHART_ID => CSRS_MHART_ID
    ) port map (
        clk_i          => clk_i,
        reset_i        => reset_i,
        ex_irq_i       => ex_irq_i,
        sw_irq_i       => sw_irq_i,
        tm_irq_i       => tm_irq_i,
        imrd_malgn_i   => ex_imrd_malgn,
        dmld_malgn_i   => ex_dmld_malgn,
        dmld_fault_i   => ex_dmld_fault,
        dmst_malgn_i   => ex_dmst_malgn,
        dmst_fault_i   => ex_dmst_fault,
        cycle_i        => cycle_i,
        timer_i        => timer_i,
        instret_i      => instret_i,
        exec_res_i     => ex_res,
        dmld_data_i    => ex_dmld_data,
        pc_i           => if_pc,
        next_pc_i      => if_next_pc,
        instr_i        => if_instr,
        fault_i        => if_imrd_fault,
        valid_i        => if_valid,
        stale_i        => if_stale,
        cop_dat_i      => cop_dat_i,
        cop_adr_o      => cop_adr_o,
        cop_dat_o      => cop_dat_o,
        cop_we_o       => cop_we_o,
        flush_i        => ex_flush,
        ready_i        => ex_ready,
        exc_fault_i    => ex_exc_fault,
        rf_we_i        => ex_rf_we,
        csr_we_i       => ex_csr_we,
        ready_o        => id_ready,
        func3_o        => ex_func3,
        branch_op_o    => ex_branch_op,
        alu_op_o       => ex_alu_op,
        dmls_ctrl_o    => ex_dmls_ctrl,
        exc_taken_o    => ex_exc_taken,
        mret_o         => ex_mret,
        mepc_o         => ex_mepc,
        mtvec_base_o   => ex_mtvec_base,
        rd_data0_o     => ex_rd0,
        rd_data1_o     => ex_rd1,
        imm_o          => ex_imm,
        opd0_src_sel_o => ex_opd0_src_sel,
        opd1_src_sel_o => ex_opd1_src_sel,
        opd0_pass_o    => ex_opd0_pass,
        opd1_pass_o    => ex_opd1_pass,
        pc_full_o      => ex_pc_full,
        ex_regwr_en_o  => ex_regwr_en,
        ex_csrwr_en_o  => ex_csrwr_en
    );

    -- execute stage --

    core_ex_block: ex_block port map (
        clk_i          => clk_i,
        reset_i        => reset_i,
        exc_taken_i    => ex_exc_taken,
        mret_i         => ex_mret,
        mepc_i         => ex_mepc,
            mtvec_base_i   => ex_mtvec_base,
        func3_i        => ex_func3,
        reg0_i         => ex_rd0,
        reg1_i         => ex_rd1,
        branch_op_i    => ex_branch_op,
        alu_op_i       => ex_alu_op,
        dmls_ctrl_i    => ex_dmls_ctrl,
        data_dat_i     => data_dat_i,
        data_ack_i     => data_ack_i,
        data_err_i     => data_err_i,
        data_stall_i   => data_stall_i,
        imrd_malgn_o   => ex_imrd_malgn,
        dmld_malgn_o   => ex_dmld_malgn,
        dmld_fault_o   => ex_dmld_fault,
        dmst_malgn_o   => ex_dmst_malgn,
        dmst_fault_o   => ex_dmst_fault,
        data_cyc_o     => data_cyc_o,
        data_stb_o     => data_stb_o,
        data_we_o      => data_we_o,
        data_dat_o     => data_dat_o,
        data_adr_o     => data_adr_o,
        data_sel_o     => data_sel_o,
        dmld_data_o    => ex_dmld_data,
        taken_o        => ex_taken,
        target_o       => ex_target,
        res_o          => ex_res,
        immwr_data_i   => ex_imm,
        ready_o        => ex_ready,
        pc_i           => ex_pc_full,
        opd0_src_sel_i => ex_opd0_src_sel,
        opd1_src_sel_i => ex_opd1_src_sel,
        opd0_pass_i    => ex_opd0_pass,
        opd1_pass_i    => ex_opd1_pass,
        valid_i        => if_valid,
        fault_i        => if_imrd_fault,
        regwr_en_i     => ex_regwr_en,
        csrwr_en_i     => ex_csrwr_en,
        exc_fault_o    => ex_exc_fault,
        rf_we_o        => ex_rf_we,
        csr_we_o       => ex_csr_we,
        flush_o        => ex_flush
    );

end architecture rtl;
