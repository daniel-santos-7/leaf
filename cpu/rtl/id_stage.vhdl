----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: instruction decode stage
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity id_stage is
    generic (
        REG_FILE_SIZE : natural := 32;
        CSRS_MHART_ID : std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        ex_irq      : in  std_logic;
        sw_irq      : in  std_logic;
        tm_irq      : in  std_logic;
        imrd_malgn  : in  std_logic;
        imrd_fault  : in  std_logic;
        dmld_malgn  : in  std_logic;
        dmld_fault  : in  std_logic;
        dmst_malgn  : in  std_logic;
        dmst_fault  : in  std_logic;
        cycle       : in  std_logic_vector(63 downto 0);
        timer       : in  std_logic_vector(63 downto 0);
        instret     : in  std_logic_vector(63 downto 0);
        exec_res    : in  std_logic_vector(31 downto 0);
        dmld_data   : in  std_logic_vector(31 downto 0);
        pc          : in  std_logic_vector(31 downto 0);
        next_pc     : in  std_logic_vector(31 downto 0);
        instr       : in  std_logic_vector(31 downto 0);
        flush       : in  std_logic;
        func3       : out std_logic_vector(2  downto 0);
        func7       : out std_logic_vector(6  downto 0);
        imm         : out std_logic_vector(31 downto 0);
        exec_ctrl   : out std_logic_vector(7  downto 0);
        dmls_ctrl   : out std_logic_vector(1  downto 0);
        pcwr_en     : out std_logic;
        trap_taken  : out std_logic;
        trap_target : out std_logic_vector(31 downto 0);
        rd_data0    : out std_logic_vector(31 downto 0);
        rd_data1    : out std_logic_vector(31 downto 0)
    );
end entity id_stage;

architecture rtl of id_stage is

    signal instr_err : std_logic;
    signal regs_addr : std_logic_vector(14 downto 0);
    signal csrs_addr : std_logic_vector(11 downto 0);
    signal istg_ctrl : std_logic_vector(3  downto 0);

    signal imm_value   : std_logic_vector(31 downto 0);
    signal func3_value : std_logic_vector(2  downto 0);

begin

    stage_main_ctrl: main_ctrl port map (
        flush     => flush,
        instr     => instr,
        instr_err => instr_err,
        func3     => func3_value,
        func7     => func7,
        dmls_ctrl => dmls_ctrl,
        istg_ctrl => istg_ctrl,
        exec_ctrl => exec_ctrl,
        csrs_addr => csrs_addr,
        regs_addr => regs_addr,
        imm       => imm_value
    );

    stage_istg_block: istg_block generic map (
        REG_FILE_SIZE => REG_FILE_SIZE,
        CSRS_MHART_ID => CSRS_MHART_ID
    ) port map (
        clk         => clk,
        reset       => reset,
        ex_irq      => ex_irq,
        sw_irq      => sw_irq,
        tm_irq      => tm_irq,
        instr_err   => instr_err,
        imrd_malgn  => imrd_malgn,
        imrd_fault  => imrd_fault,
        dmld_malgn  => dmld_malgn,
        dmld_fault  => dmld_fault,
        dmst_malgn  => dmst_malgn,
        dmst_fault  => dmst_fault,
        cycle       => cycle,
        timer       => timer,
        instret     => instret,
        exec_res    => exec_res,
        dmld_data   => dmld_data,
        pc          => pc,
        next_pc     => next_pc,
        imm         => imm_value,
        func3       => func3_value,
        regs_addr   => regs_addr,
        csrs_addr   => csrs_addr,
        istg_ctrl   => istg_ctrl,
        pcwr_en     => pcwr_en,
        trap_taken  => trap_taken,
        trap_target => trap_target,
        rd_data0    => rd_data0,
        rd_data1    => rd_data1
    );

    imm <= imm_value;
    func3 <= func3_value;

end architecture rtl;
