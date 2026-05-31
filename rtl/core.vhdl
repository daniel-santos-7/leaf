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
        imrd_err_i  : in  std_logic;
        dmrd_err_i  : in  std_logic;
        dmwr_err_i  : in  std_logic;
        imrd_data_i : in  std_logic_vector(XLEN-1 downto 0);
        dmrd_data_i : in  std_logic_vector(XLEN-1 downto 0);
        cycle_i     : in  std_logic_vector(63 downto 0);
        timer_i     : in  std_logic_vector(63 downto 0);
        instret_i   : in  std_logic_vector(63 downto 0);
        cop_dat_i   : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o   : out std_logic_vector(5 downto 0);
        cop_dat_o   : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o    : out std_logic;
        retire_o    : out std_logic;
        imrd_en_o   : out std_logic;
        dmrd_en_o   : out std_logic;
        dmwr_en_o   : out std_logic;
        dmwr_be_o   : out std_logic_vector(3         downto 0);
        imrd_addr_o : out std_logic_vector(XLEN-1 downto 0);
        dmrw_addr_o : out std_logic_vector(XLEN-1 downto 0);
        dmwr_data_o : out std_logic_vector(XLEN-1 downto 0)
    );
end entity core;

architecture rtl of core is

    -- internal signals --

    signal pcwr_en    : std_logic;
    signal taken      : std_logic;
    signal target     : std_logic_vector(XLEN-1 downto 0);
    signal imrd_fault : std_logic;
    signal flush      : std_logic;
    signal pc         : std_logic_vector(XLEN-1 downto 0);
    signal next_pc    : std_logic_vector(XLEN-1 downto 0);
    signal instr      : std_logic_vector(XLEN-1 downto 0);

    signal func3      : std_logic_vector(2  downto 0);
    signal func7      : std_logic_vector(6  downto 0);
    signal imm        : std_logic_vector(XLEN-1 downto 0);
    signal opd0       : std_logic_vector(XLEN-1 downto 0);
    signal opd1       : std_logic_vector(XLEN-1 downto 0);
    signal jmp          : std_logic;
    signal br_en        : std_logic;
    signal ftype        : std_logic;
    signal op_en        : std_logic;
    signal dmls_mode : std_logic;
    signal dmls_en   : std_logic;

    signal trap_taken  : std_logic;
    signal trap_target : std_logic_vector(XLEN-1 downto 0);

    signal reg0_data : std_logic_vector(XLEN-1 downto 0);
    signal reg1_data : std_logic_vector(XLEN-1 downto 0);
    signal exec_res  : std_logic_vector(XLEN-1 downto 0);
    signal dmld_data : std_logic_vector(XLEN-1 downto 0);
    signal csrrd_data : std_logic_vector(XLEN-1 downto 0);
    signal csrwr_data : std_logic_vector(XLEN-1 downto 0);

    signal imrd_malgn : std_logic;
    signal dmld_malgn : std_logic;
    signal dmld_fault : std_logic;
    signal dmst_malgn : std_logic;
    signal dmst_fault : std_logic;

begin

    -- instruction fetch stage --

    core_if_stage: if_stage generic map (
        RESET_ADDR => RESET_ADDR
    ) port map (
        clk_i        => clk_i,
        reset_i      => reset_i,
        pcwr_en_i    => pcwr_en,
        imrd_err_i   => imrd_err_i,
        taken_i      => taken,
        target_i     => target,
        imrd_data_i  => imrd_data_i,
        imrd_en_o    => imrd_en_o,
        imrd_fault_o => imrd_fault,
        flush_o      => flush,
        imrd_addr_o  => imrd_addr_o,
        pc_o         => pc,
        next_pc_o    => next_pc,
        instr_o      => instr,
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
        imrd_malgn_i  => imrd_malgn,
        imrd_fault_i  => imrd_fault,
        dmld_malgn_i  => dmld_malgn,
        dmld_fault_i  => dmld_fault,
        dmst_malgn_i  => dmst_malgn,
        dmst_fault_i  => dmst_fault,
        cycle_i       => cycle_i,
        timer_i       => timer_i,
        instret_i     => instret_i,
        exec_res_i    => exec_res,
        dmld_data_i   => dmld_data,
        pc_i          => pc,
        next_pc_i     => next_pc,
        instr_i       => instr,
        flush_i       => flush,
        func3_o       => func3,
        func7_o       => func7,
        imm_o         => imm,
        jmp_o         => jmp,
        br_en_o       => br_en,
        ftype_o       => ftype,
        op_en_o       => op_en,
        dmls_mode_o   => dmls_mode,
        dmls_en_o     => dmls_en,
        opd0_o        => opd0,
        opd1_o        => opd1,
        cop_dat_i     => cop_dat_i,
        cop_adr_o     => cop_adr_o,
        cop_dat_o     => cop_dat_o,
        cop_we_o      => cop_we_o,
        pcwr_en_o     => pcwr_en,
        trap_taken_o  => trap_taken,
        trap_target_o => trap_target,
        rd_data0_o    => reg0_data,
        rd_data1_o    => reg1_data,
        csrwr_data_i  => csrwr_data,
        csrrd_data_o  => csrrd_data
    );

    core_ex_block: ex_block port map (
        trap_taken_i   => trap_taken,
        trap_target_i  => trap_target,
        func3_i        => func3,
        func7_i        => func7,
        reg0_i         => reg0_data,
        reg1_i         => reg1_data,
        imm_i          => imm,
        csrrd_data_i   => csrrd_data,
        opd0_i         => opd0,
        opd1_i         => opd1,
        jmp_i          => jmp,
        br_en_i        => br_en,
        ftype_i        => ftype,
        op_en_i        => op_en,
        dmls_mode_i    => dmls_mode,
        dmls_en_i      => dmls_en,
        dmrd_err_i     => dmrd_err_i,
        dmwr_err_i     => dmwr_err_i,
        dmrd_data_i    => dmrd_data_i,
        imrd_malgn_o   => imrd_malgn,
        dmld_malgn_o   => dmld_malgn,
        dmld_fault_o   => dmld_fault,
        dmst_malgn_o   => dmst_malgn,
        dmst_fault_o   => dmst_fault,
        dmrd_en_o      => dmrd_en_o,
        dmwr_en_o      => dmwr_en_o,
        dmwr_data_o    => dmwr_data_o,
        dmrw_addr_o    => dmrw_addr_o,
        dm_byte_en_o   => dmwr_be_o,
        dmld_data_o    => dmld_data,
        csrwr_data_o   => csrwr_data,
        taken_o        => taken,
        target_o       => target,
        res_o          => exec_res
    );

end architecture rtl;
