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

    signal id_ready    : std_logic;
    signal taken : std_logic;
    signal target : std_logic_vector(XLEN-1 downto 0);
    signal branch     : std_logic;
    signal dmls_ready : std_logic;

    -- IF stage combinatorial outputs (before pipeline register)
    signal if_inst_adr : std_logic_vector(XLEN-1 downto 2);
    signal if_pc      : std_logic_vector(XLEN-1 downto 2);
    signal if_next_pc : std_logic_vector(XLEN-1 downto 2);
    signal if_instr   : std_logic_vector(XLEN-1 downto 0);
    signal if_imrd_fault : std_logic;
    signal if_valid   : std_logic;

    signal id_pc_full : std_logic_vector(XLEN-1 downto 0);
    signal func3      : std_logic_vector(2  downto 0);
    signal jmp          : std_logic;
    signal br_en        : std_logic;
    signal alu_op       : std_logic_vector(5  downto 0);
    signal dmls_mode : std_logic;
    signal dmls_en   : std_logic;

    signal trap_taken  : std_logic;
    signal trap_target : std_logic_vector(XLEN-1 downto 0);

    signal reg0_data : std_logic_vector(XLEN-1 downto 0);
    signal reg1_data : std_logic_vector(XLEN-1 downto 0);
    signal exec_res  : std_logic_vector(XLEN-1 downto 0);
    signal dmld_data : std_logic_vector(XLEN-1 downto 0);

    signal imrd_malgn : std_logic;
    signal dmld_malgn : std_logic;
    signal dmld_fault : std_logic;
    signal dmst_malgn : std_logic;
    signal dmst_fault : std_logic;

    signal csrrd_data : std_logic_vector(XLEN-1 downto 0);
    signal imm        : std_logic_vector(XLEN-1 downto 0);
    signal csrwr_data : std_logic_vector(XLEN-1 downto 0);
    signal opd0_src_sel : std_logic;
    signal opd1_src_sel : std_logic;
    signal opd0_pass    : std_logic;
    signal opd1_pass    : std_logic;

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
        taken_i => taken,
        target_i => target,
        inst_dat_i   => inst_dat_i,
        inst_cyc_o   => inst_cyc_o,
        inst_stb_o   => inst_stb_o,
        inst_err_o   => if_imrd_fault,
        inst_adr_o   => if_inst_adr,
        pc_o         => if_pc,
        next_pc_o    => if_next_pc,
        inst_o       => if_instr,
        valid_o      => if_valid
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
        imrd_malgn_i  => imrd_malgn,
        dmld_malgn_i  => dmld_malgn,
        dmld_fault_i  => dmld_fault,
        dmst_malgn_i  => dmst_malgn,
        dmst_fault_i  => dmst_fault,
        cycle_i       => cycle_i,
        timer_i       => timer_i,
        instret_i     => instret_i,
        exec_res_i    => exec_res,
        dmld_data_i   => dmld_data,
        pc_i          => if_pc,
        next_pc_i     => if_next_pc,
        instr_i       => if_instr,
        fault_i       => if_imrd_fault,
        valid_i       => if_valid,
        inst_adr_i    => if_inst_adr,
        branch_i      => branch,
        dmls_ready_i  => dmls_ready,
        func3_o       => func3,
        jmp_o         => jmp,
        br_en_o       => br_en,
        alu_op_o      => alu_op,
        dmls_mode_o   => dmls_mode,
        dmls_en_o     => dmls_en,
        cop_dat_i     => cop_dat_i,
        cop_adr_o     => cop_adr_o,
        cop_dat_o     => cop_dat_o,
        cop_we_o      => cop_we_o,
        ready_o       => id_ready,
        trap_taken_o  => trap_taken,
        trap_target_o => trap_target,
        rd_data0_o    => reg0_data,
        rd_data1_o    => reg1_data,
        csrrd_data_o  => csrrd_data,
        imm_o         => imm,
        csrwr_data_i  => csrwr_data,
        opd0_src_sel_o => opd0_src_sel,
        opd1_src_sel_o => opd1_src_sel,
        opd0_pass_o    => opd0_pass,
        opd1_pass_o    => opd1_pass,
        retire_o      => retire_o,
        pc_full_o     => id_pc_full
    );

    core_ex_block: ex_block port map (
        clk_i          => clk_i,
        reset_i        => reset_i,
        trap_taken_i   => trap_taken,
        trap_target_i  => trap_target,
        func3_i        => func3,
        reg0_i         => reg0_data,
        reg1_i         => reg1_data,
        jmp_i          => jmp,
        br_en_i        => br_en,
        alu_op_i       => alu_op,
        dmls_mode_i    => dmls_mode,
        dmls_en_i      => dmls_en,
        data_dat_i    => data_dat_i,
        data_ack_i    => data_ack_i,
        data_err_i    => data_err_i,
        imrd_malgn_o   => imrd_malgn,
        dmld_malgn_o   => dmld_malgn,
        dmld_fault_o   => dmld_fault,
        dmst_malgn_o   => dmst_malgn,
        dmst_fault_o   => dmst_fault,
        data_cyc_o     => data_cyc_o,
        data_stb_o     => data_stb_o,
        data_we_o      => data_we_o,
        data_dat_o    => data_dat_o,
        data_adr_o    => data_adr_o,
        data_sel_o   => data_sel_o,
        dmld_data_o    => dmld_data,
        taken_o   => taken,
        target_o  => target,
        branch_o       => branch,
        res_o          => exec_res,
        dmls_ready_o   => dmls_ready,
        csrrd_data_i   => csrrd_data,
        immwr_data_i   => imm,
        csrwr_data_o   => csrwr_data,
        pc_i           => id_pc_full,
        opd0_src_sel_i => opd0_src_sel,
        opd1_src_sel_i => opd1_src_sel,
        opd0_pass_i    => opd0_pass,
        opd1_pass_i    => opd1_pass,
        valid_i        => if_valid
    );

    inst_adr_o <= if_inst_adr;

end architecture rtl;
