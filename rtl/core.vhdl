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
        cop_dat_i : in  std_logic_vector(31 downto 0) := (others => '0');
        cop_adr_o : out std_logic_vector(5 downto 0);
        cop_dat_o : out std_logic_vector(31 downto 0);
        cop_we_o  : out std_logic;
        retire_o  : out std_logic;
        imrd_en   : out std_logic;
        dmrd_en   : out std_logic;
        dmwr_en   : out std_logic;
        dmwr_be   : out std_logic_vector(3  downto 0);
        imrd_addr : out std_logic_vector(31 downto 0);
        dmrw_addr : out std_logic_vector(31 downto 0);
        dmwr_data : out std_logic_vector(31 downto 0)
    );
end entity core;

architecture rtl of core is

    -- internal signals --

    signal pcwr_en    : std_logic;
    signal taken      : std_logic;
    signal target     : std_logic_vector(31 downto 0);
    signal imrd_fault : std_logic;
    signal flush      : std_logic;
    signal pc         : std_logic_vector(31 downto 0);
    signal next_pc    : std_logic_vector(31 downto 0);
    signal instr      : std_logic_vector(31 downto 0);

    signal func3     : std_logic_vector(2  downto 0);
    signal func7     : std_logic_vector(6  downto 0);
    signal imm       : std_logic_vector(31 downto 0);
    signal jmp          : std_logic;
    signal br_en        : std_logic;
    signal opd0_src_sel : std_logic;
    signal opd1_src_sel : std_logic;
    signal opd0_pass    : std_logic;
    signal opd1_pass    : std_logic;
    signal ftype        : std_logic;
    signal op_en        : std_logic;
    signal dmls_ctrl : std_logic_vector(1  downto 0);

    signal trap_taken  : std_logic;
    signal trap_target : std_logic_vector(31 downto 0);

    signal reg0_data : std_logic_vector(31 downto 0);
    signal reg1_data : std_logic_vector(31 downto 0);
    signal exec_res  : std_logic_vector(31 downto 0);
    signal dmld_data : std_logic_vector(31 downto 0);
    signal csrrd_data : std_logic_vector(31 downto 0);
    signal csrwr_data : std_logic_vector(31 downto 0);

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
        clk_i        => clk,
        reset_i      => reset,
        pcwr_en_i    => pcwr_en,
        imrd_err_i   => imrd_err,
        taken_i      => taken,
        target_i     => target,
        imrd_data_i  => imrd_data,
        imrd_en_o    => imrd_en,
        imrd_fault_o => imrd_fault,
        flush_o      => flush,
        imrd_addr_o  => imrd_addr,
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
        clk_i         => clk,
        reset_i       => reset,
        ex_irq_i      => ex_irq,
        sw_irq_i      => sw_irq,
        tm_irq_i      => tm_irq,
        imrd_malgn_i  => imrd_malgn,
        imrd_fault_i  => imrd_fault,
        dmld_malgn_i  => dmld_malgn,
        dmld_fault_i  => dmld_fault,
        dmst_malgn_i  => dmst_malgn,
        dmst_fault_i  => dmst_fault,
        cycle_i       => cycle,
        timer_i       => timer,
        instret_i     => instret,
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
        opd0_src_sel_o=> opd0_src_sel,
        opd1_src_sel_o=> opd1_src_sel,
        opd0_pass_o   => opd0_pass,
        opd1_pass_o   => opd1_pass,
        ftype_o       => ftype,
        op_en_o       => op_en,
        dmls_ctrl_o   => dmls_ctrl,
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
        trap_taken  => trap_taken,
        trap_target => trap_target,
        func3       => func3,
        func7       => func7,
        reg0        => reg0_data,
        reg1        => reg1_data,
        pc          => pc,
        imm         => imm,
        csrrd_data  => csrrd_data,
        jmp         => jmp,
        br_en       => br_en,
        opd0_src_sel=> opd0_src_sel,
        opd1_src_sel=> opd1_src_sel,
        opd0_pass   => opd0_pass,
        opd1_pass   => opd1_pass,
        ftype       => ftype,
        op_en       => op_en,
        dmls_ctrl   => dmls_ctrl,
        dmrd_err    => dmrd_err,
        dmwr_err    => dmwr_err,
        dmrd_data   => dmrd_data,
        imrd_malgn  => imrd_malgn,
        dmld_malgn  => dmld_malgn,
        dmld_fault  => dmld_fault,
        dmst_malgn  => dmst_malgn,
        dmst_fault  => dmst_fault,
        dmrd_en     => dmrd_en,
        dmwr_en     => dmwr_en,
        dmwr_data   => dmwr_data,
        dmrw_addr   => dmrw_addr,
        dm_byte_en  => dmwr_be,
        dmld_data   => dmld_data,
        csrwr_data  => csrwr_data,
        taken       => taken,
        target      => target,
        res         => exec_res
    );

end architecture rtl;
