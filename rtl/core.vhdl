----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: cpu core
-- 2026
----------------------------------------------------------------------

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
        data_sel_o  : out std_logic_vector(3         downto 0);
        data_adr_o  : out std_logic_vector(XLEN-1 downto 2);
        data_dat_o  : out std_logic_vector(XLEN-1 downto 0)
    );
end entity core;

architecture rtl of core is

    -- internal signals --

    signal ex_ready            : std_logic;
    signal ex_taken            : std_logic;
    signal ex_target           : std_logic_vector(XLEN-1 downto 0);
    signal ex_branch           : std_logic;
    signal id_wfi, id_int_taken : std_logic;

    -- IF stage combinatorial outputs (before pipeline register)
    signal if_pc      : std_logic_vector(XLEN-1 downto 2);
    signal if_next_pc : std_logic_vector(XLEN-1 downto 2);
    signal if_instr   : std_logic_vector(XLEN-1 downto 0);
    signal if_imrd_fault : std_logic;
    signal if_valid   : std_logic;

    signal id_pc_full : std_logic_vector(XLEN-1 downto 0);
    signal id_func3      : std_logic_vector(2  downto 0);
    signal id_jmp        : std_logic;
    signal id_br_en      : std_logic;
    signal id_alu_op     : std_logic_vector(5  downto 0);
    signal id_dmls_mode  : std_logic;
    signal id_dmls_en    : std_logic;

    signal id_trap_taken  : std_logic;
    signal id_trap_target : std_logic_vector(XLEN-1 downto 0);

    signal id_rd0      : std_logic_vector(XLEN-1 downto 0);
    signal id_rd1      : std_logic_vector(XLEN-1 downto 0);
    signal ex_res      : std_logic_vector(XLEN-1 downto 0);
    signal ex_dmld_data : std_logic_vector(XLEN-1 downto 0);

    signal ex_imrd_malgn : std_logic;
    signal ex_dmld_malgn : std_logic;
    signal ex_dmld_fault : std_logic;
    signal ex_dmst_malgn : std_logic;
    signal ex_dmst_fault : std_logic;

    signal id_csrrd_data  : std_logic_vector(XLEN-1 downto 0);
    signal id_imm         : std_logic_vector(XLEN-1 downto 0);
    signal ex_csrwr_data  : std_logic_vector(XLEN-1 downto 0);
    signal id_opd0_src_sel : std_logic;
    signal id_opd1_src_sel : std_logic;
    signal id_opd0_pass    : std_logic;
    signal id_opd1_pass    : std_logic;

begin

    -- instruction fetch stage --

    core_if_stage: if_stage generic map (
        RESET_ADDR => RESET_ADDR
    ) port map (
        clk_i        => clk_i,
        reset_i      => reset_i,
        ready_i      => ex_ready,
        inst_ack_i   => inst_ack_i,
        inst_err_i   => inst_err_i,
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
        retire_o     => retire_o
    );

    -- instruction decode and execute stage --

    core_id_stage: id_stage generic map (
        REG_FILE_SIZE => REG_FILE_SIZE,
        CSRS_MHART_ID => CSRS_MHART_ID
    ) port map (
        clk_i         => clk_i,
        reset_i       => reset_i,
        ex_irq_i      => ex_irq_i,
        sw_irq_i      => sw_irq_i,
        tm_irq_i      => tm_irq_i,
        imrd_malgn_i  => ex_imrd_malgn,
        dmld_malgn_i  => ex_dmld_malgn,
        dmld_fault_i  => ex_dmld_fault,
        dmst_malgn_i  => ex_dmst_malgn,
        dmst_fault_i  => ex_dmst_fault,
        cycle_i       => cycle_i,
        timer_i       => timer_i,
        instret_i     => instret_i,
        exec_res_i    => ex_res,
        dmld_data_i   => ex_dmld_data,
        pc_i          => if_pc,
        next_pc_i     => if_next_pc,
        instr_i       => if_instr,
        fault_i       => if_imrd_fault,
        valid_i       => if_valid,
        func3_o       => id_func3,
        jmp_o         => id_jmp,
        br_en_o       => id_br_en,
        alu_op_o      => id_alu_op,
        dmls_mode_o   => id_dmls_mode,
        dmls_en_o     => id_dmls_en,
        cop_dat_i     => cop_dat_i,
        cop_adr_o     => cop_adr_o,
        cop_dat_o     => cop_dat_o,
        cop_we_o      => cop_we_o,
        trap_taken_o  => id_trap_taken,
        trap_target_o => id_trap_target,
        rd_data0_o    => id_rd0,
        rd_data1_o    => id_rd1,
        csrrd_data_o  => id_csrrd_data,
        imm_o         => id_imm,
        csrwr_data_i  => ex_csrwr_data,
        opd0_src_sel_o => id_opd0_src_sel,
        opd1_src_sel_o => id_opd1_src_sel,
        opd0_pass_o    => id_opd0_pass,
        opd1_pass_o    => id_opd1_pass,
        wfi_o         => id_wfi,
        int_taken_o   => id_int_taken,
        pc_full_o     => id_pc_full
    );

    core_ex_block: ex_block port map (
        clk_i          => clk_i,
        reset_i        => reset_i,
        trap_taken_i   => id_trap_taken,
        trap_target_i  => id_trap_target,
        func3_i        => id_func3,
        reg0_i         => id_rd0,
        reg1_i         => id_rd1,
        jmp_i          => id_jmp,
        br_en_i        => id_br_en,
        alu_op_i       => id_alu_op,
        dmls_mode_i    => id_dmls_mode,
        dmls_en_i      => id_dmls_en,
        data_dat_i     => data_dat_i,
        data_ack_i     => data_ack_i,
        data_err_i     => data_err_i,
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
        branch_o       => ex_branch,
        res_o          => ex_res,
        csrrd_data_i   => id_csrrd_data,
        immwr_data_i   => id_imm,
        csrwr_data_o   => ex_csrwr_data,
        wfi_i          => id_wfi,
        int_taken_i    => id_int_taken,
        ready_o        => ex_ready,
        pc_i           => id_pc_full,
        opd0_src_sel_i => id_opd0_src_sel,
        opd1_src_sel_i => id_opd1_src_sel,
        opd0_pass_i    => id_opd0_pass,
        opd1_pass_i    => id_opd1_pass,
        valid_i        => if_valid
    );

end architecture rtl;
