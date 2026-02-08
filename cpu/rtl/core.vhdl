----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: cpu core
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

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
    signal exec_ctrl : std_logic_vector(7  downto 0);
    signal dmls_ctrl : std_logic_vector(1  downto 0);

    signal trap_taken  : std_logic;
    signal trap_target : std_logic_vector(31 downto 0);

    signal reg0_data : std_logic_vector(31 downto 0);
    signal reg1_data : std_logic_vector(31 downto 0);
    signal exec_res  : std_logic_vector(31 downto 0);
    signal dmld_data : std_logic_vector(31 downto 0);

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
        clk        => clk,
        reset      => reset,
        pcwr_en    => pcwr_en,
        imrd_err   => imrd_err,
        taken      => taken,
        target     => target,
        imrd_data  => imrd_data,
        imrd_en    => imrd_en,
        imrd_fault => imrd_fault,
        flush      => flush,
        imrd_addr  => imrd_addr,
        pc         => pc,
        next_pc    => next_pc,
        instr      => instr
    );

    -- instruction decode and execute stage --

    core_id_stage: id_stage generic map (
        REG_FILE_SIZE => REG_FILE_SIZE,
        CSRS_MHART_ID => CSRS_MHART_ID
    ) port map (
        clk        => clk,
        reset      => reset,
        ex_irq     => ex_irq,
        sw_irq     => sw_irq,
        tm_irq     => tm_irq,
        imrd_malgn => imrd_malgn,
        imrd_fault => imrd_fault,
        dmld_malgn => dmld_malgn,
        dmld_fault => dmld_fault,
        dmst_malgn => dmst_malgn,
        dmst_fault => dmst_fault,
        cycle      => cycle,
        timer      => timer,
        instret    => instret,
        exec_res   => exec_res,
        dmld_data  => dmld_data,
        pc         => pc,
        next_pc    => next_pc,
        instr      => instr,
        flush      => flush,
        func3      => func3,
        func7      => func7,
        imm        => imm,
        exec_ctrl  => exec_ctrl,
        dmls_ctrl  => dmls_ctrl,
        pcwr_en    => pcwr_en,
        trap_taken => trap_taken,
        trap_target=> trap_target,
        rd_data0   => reg0_data,
        rd_data1   => reg1_data
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
        exec_ctrl   => exec_ctrl,
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
        taken       => taken,
        target      => target,
        res         => exec_res
    );

end architecture rtl;
