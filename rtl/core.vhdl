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
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        ex_irq_i     : in  std_logic;
        sw_irq_i     : in  std_logic;
        tm_irq_i     : in  std_logic;

        cycle_i      : in  std_logic_vector(63 downto 0);
        timer_i      : in  std_logic_vector(63 downto 0);
        instret_i    : in  std_logic_vector(63 downto 0);
        retire_o     : out std_logic;

        cop_dat_i    : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o    : out std_logic_vector(5      downto 0);
        cop_dat_o    : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o     : out std_logic;

        inst_cyc_o   : out std_logic;
        inst_stb_o   : out std_logic;
        inst_adr_o   : out std_logic_vector(XLEN-1 downto 2);
        inst_dat_i   : in  std_logic_vector(XLEN-1 downto 0);
        inst_ack_i   : in  std_logic;
        inst_err_i   : in  std_logic;
        inst_stall_i : in  std_logic;

        data_cyc_o   : out std_logic;
        data_stb_o   : out std_logic;
        data_we_o    : out std_logic;
        data_sel_o   : out std_logic_vector(3      downto 0);
        data_adr_o   : out std_logic_vector(XLEN-1 downto 2);
        data_dat_o   : out std_logic_vector(XLEN-1 downto 0);
        data_dat_i   : in  std_logic_vector(XLEN-1 downto 0);
        data_ack_i   : in  std_logic;
        data_err_i   : in  std_logic;
        data_stall_i : in  std_logic
    );
end entity core;

architecture rtl of core is

    signal if_stage_pc           : std_logic_vector(XLEN-1 downto 2);
    signal if_stage_inst         : std_logic_vector(XLEN-1 downto 0);
    signal if_stage_inst_err     : std_logic;
    signal if_stage_valid        : std_logic;
    signal if_stage_stale        : std_logic;
    signal if_stage_redirect_ack : std_logic;
    signal if_stage_inst_cyc     : std_logic;
    signal if_stage_inst_stb     : std_logic;
    signal if_stage_inst_adr     : std_logic_vector(XLEN-1 downto 2);

    -- The ID/EX pipeline register lives inside id_stage, so everything below
    -- except id_stage_ready is already registered.
    signal id_stage_ready       : std_logic;
    signal id_stage_func3       : std_logic_vector(2  downto 0);
    signal id_stage_branch_op   : std_logic_vector(1  downto 0);
    signal id_stage_alu_op      : std_logic_vector(5  downto 0);
    signal id_stage_dmls_ctrl   : std_logic_vector(1  downto 0);
    signal id_stage_trap_taken  : std_logic;
    signal id_stage_trap_target : std_logic_vector(XLEN-1 downto 0);
    signal id_stage_rd_data0    : std_logic_vector(XLEN-1 downto 0);
    signal id_stage_rd_data1    : std_logic_vector(XLEN-1 downto 0);
    signal id_stage_imm         : std_logic_vector(XLEN-1 downto 0);
    signal id_stage_opd_src_sel : std_logic_vector(1  downto 0);
    signal id_stage_opd_pass    : std_logic_vector(1  downto 0);
    signal id_stage_pc_full     : std_logic_vector(XLEN-1 downto 0);
    signal id_stage_retire      : std_logic;
    signal id_stage_cop_adr     : std_logic_vector(5      downto 0);
    signal id_stage_cop_dat     : std_logic_vector(XLEN-1 downto 0);
    signal id_stage_cop_we      : std_logic;

    signal ex_block_ready      : std_logic;
    signal ex_block_taken      : std_logic;
    signal ex_block_target     : std_logic_vector(XLEN-1 downto 0);
    signal ex_block_flush      : std_logic;
    signal ex_block_res        : std_logic_vector(XLEN-1 downto 0);
    signal ex_block_link       : std_logic_vector(XLEN-1 downto 0);
    signal ex_block_dmld_data  : std_logic_vector(XLEN-1 downto 0);
    signal ex_block_imrd_malgn : std_logic;
    signal ex_block_dmld_malgn : std_logic;
    signal ex_block_dmld_fault : std_logic;
    signal ex_block_dmst_malgn : std_logic;
    signal ex_block_dmst_fault : std_logic;
    signal ex_block_data_cyc   : std_logic;
    signal ex_block_data_stb   : std_logic;
    signal ex_block_data_we    : std_logic;
    signal ex_block_data_sel   : std_logic_vector(3      downto 0);
    signal ex_block_data_adr   : std_logic_vector(XLEN-1 downto 2);
    signal ex_block_data_dat   : std_logic_vector(XLEN-1 downto 0);

begin

    core_if_stage: if_stage generic map (
        RESET_ADDR => RESET_ADDR
    ) port map (
        clk_i          => clk_i,
        reset_i        => reset_i,
        ready_i        => id_stage_ready,
        inst_ack_i     => inst_ack_i,
        inst_err_i     => inst_err_i,
        inst_stall_i   => inst_stall_i,
        taken_i        => ex_block_taken,
        target_i       => ex_block_target,
        inst_dat_i     => inst_dat_i,
        inst_cyc_o     => if_stage_inst_cyc,
        inst_stb_o     => if_stage_inst_stb,
        inst_err_o     => if_stage_inst_err,
        inst_adr_o     => if_stage_inst_adr,
        pc_o           => if_stage_pc,
        inst_o         => if_stage_inst,
        valid_o        => if_stage_valid,
        stale_o        => if_stage_stale,
        redirect_ack_o => if_stage_redirect_ack
    );

    core_id_stage: id_stage generic map (
        REG_FILE_SIZE => REG_FILE_SIZE,
        CSRS_MHART_ID => CSRS_MHART_ID
    ) port map (
        clk_i         => clk_i,
        reset_i       => reset_i,
        ex_irq_i      => ex_irq_i,
        sw_irq_i      => sw_irq_i,
        tm_irq_i      => tm_irq_i,
        imrd_malgn_i  => ex_block_imrd_malgn,
        dmld_malgn_i  => ex_block_dmld_malgn,
        dmld_fault_i  => ex_block_dmld_fault,
        dmst_malgn_i  => ex_block_dmst_malgn,
        dmst_fault_i  => ex_block_dmst_fault,
        cycle_i       => cycle_i,
        timer_i       => timer_i,
        instret_i     => instret_i,
        exec_res_i    => ex_block_res,
        link_i        => ex_block_link,
        dmld_data_i   => ex_block_dmld_data,
        pc_i          => if_stage_pc,
        instr_i       => if_stage_inst,
        fault_i       => if_stage_inst_err,
        valid_i       => if_stage_valid,
        stale_i       => if_stage_stale,
        cop_dat_i     => cop_dat_i,
        cop_adr_o     => id_stage_cop_adr,
        cop_dat_o     => id_stage_cop_dat,
        cop_we_o      => id_stage_cop_we,
        flush_i       => ex_block_flush,
        ready_i       => ex_block_ready,
        ready_o       => id_stage_ready,
        func3_o       => id_stage_func3,
        branch_op_o   => id_stage_branch_op,
        alu_op_o      => id_stage_alu_op,
        dmls_ctrl_o   => id_stage_dmls_ctrl,
        trap_taken_o  => id_stage_trap_taken,
        trap_target_o => id_stage_trap_target,
        rd_data0_o    => id_stage_rd_data0,
        rd_data1_o    => id_stage_rd_data1,
        imm_o         => id_stage_imm,
        opd_src_sel_o => id_stage_opd_src_sel,
        opd_pass_o    => id_stage_opd_pass,
        pc_full_o     => id_stage_pc_full,
        retire_o      => id_stage_retire
    );

    core_ex_block: ex_block port map (
        clk_i          => clk_i,
        reset_i        => reset_i,
        trap_taken_i   => id_stage_trap_taken,
        trap_target_i  => id_stage_trap_target,
        func3_i        => id_stage_func3,
        reg0_i         => id_stage_rd_data0,
        reg1_i         => id_stage_rd_data1,
        branch_op_i    => id_stage_branch_op,
        alu_op_i       => id_stage_alu_op,
        dmls_ctrl_i    => id_stage_dmls_ctrl,
        immwr_data_i   => id_stage_imm,
        opd_src_sel_i  => id_stage_opd_src_sel,
        opd_pass_i     => id_stage_opd_pass,
        pc_i           => id_stage_pc_full,
        data_dat_i     => data_dat_i,
        data_ack_i     => data_ack_i,
        data_err_i     => data_err_i,
        data_stall_i   => data_stall_i,
        redirect_ack_i => if_stage_redirect_ack,
        imrd_malgn_o   => ex_block_imrd_malgn,
        dmld_malgn_o   => ex_block_dmld_malgn,
        dmld_fault_o   => ex_block_dmld_fault,
        dmst_malgn_o   => ex_block_dmst_malgn,
        dmst_fault_o   => ex_block_dmst_fault,
        data_cyc_o     => ex_block_data_cyc,
        data_stb_o     => ex_block_data_stb,
        data_we_o      => ex_block_data_we,
        data_dat_o     => ex_block_data_dat,
        data_adr_o     => ex_block_data_adr,
        data_sel_o     => ex_block_data_sel,
        dmld_data_o    => ex_block_dmld_data,
        taken_o        => ex_block_taken,
        target_o       => ex_block_target,
        res_o          => ex_block_res,
        link_o         => ex_block_link,
        ready_o        => ex_block_ready,
        flush_o        => ex_block_flush
    );

    retire_o     <= id_stage_retire;

    cop_adr_o    <= id_stage_cop_adr;
    cop_dat_o    <= id_stage_cop_dat;
    cop_we_o     <= id_stage_cop_we;

    inst_cyc_o   <= if_stage_inst_cyc;
    inst_stb_o   <= if_stage_inst_stb;
    inst_adr_o   <= if_stage_inst_adr;

    data_cyc_o   <= ex_block_data_cyc;
    data_stb_o   <= ex_block_data_stb;
    data_we_o    <= ex_block_data_we;
    data_sel_o   <= ex_block_data_sel;
    data_adr_o   <= ex_block_data_adr;
    data_dat_o   <= ex_block_data_dat;

end architecture rtl;
