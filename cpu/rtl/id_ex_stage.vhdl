----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: instruction decode and execute stage
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity id_ex_stage is
    generic (
        REG_FILE_SIZE : natural := 32;
        CSRS_MHART_ID : std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        ex_irq     : in  std_logic;
        sw_irq     : in  std_logic;
        tm_irq     : in  std_logic;
        flush      : in  std_logic;
        instr      : in  std_logic_vector(31 downto 0);
        pc         : in  std_logic_vector(31 downto 0);
        next_pc    : in  std_logic_vector(31 downto 0);
        dmrd_data  : in  std_logic_vector(31 downto 0);
        cycle      : in  std_logic_vector(63 downto 0);
        timer      : in  std_logic_vector(63 downto 0);
        instret    : in  std_logic_vector(63 downto 0);
        dmrd_en    : out std_logic;
        dmwr_en    : out std_logic;
        taken      : out std_logic;
        target     : out std_logic_vector(31 downto 0);
        dmwr_data  : out std_logic_vector(31 downto 0);
        dmrw_addr  : out std_logic_vector(31 downto 0);
        dm_byte_en : out std_logic_vector(3  downto 0)
    );
end entity id_ex_stage;

architecture id_ex_stage_arch of id_ex_stage is
    
    signal instr_err : std_logic;
    signal func3     : std_logic_vector(2  downto 0);
    signal func7     : std_logic_vector(6  downto 0);
    signal imm       : std_logic_vector(31 downto 0);
    signal regs_addr : std_logic_vector(14 downto 0);
    signal csrs_addr : std_logic_vector(11 downto 0);
    signal istg_ctrl : std_logic_vector(3  downto 0);
    signal exec_ctrl : std_logic_vector(7  downto 0);
    signal dmls_ctrl : std_logic_vector(1  downto 0);
    
    signal reg0_data : std_logic_vector(31 downto 0);
    signal reg1_data : std_logic_vector(31 downto 0);
    signal exec_res  : std_logic_vector(31 downto 0);
    signal dmld_data : std_logic_vector(31 downto 0);

begin

    stage_id_block: id_block port map (
        flush     => flush,
        instr     => instr,
        instr_err => instr_err,
        func3     => func3,
        func7     => func7,
        imm       => imm,
        regs_addr => regs_addr,
        csrs_addr => csrs_addr,
        istg_ctrl => istg_ctrl,
        exec_ctrl => exec_ctrl,
        dmls_ctrl => dmls_ctrl
    );

    stage_istg_block: int_strg generic map(
        REG_FILE_SIZE => REG_FILE_SIZE,
        CSRS_MHART_ID => CSRS_MHART_ID
    ) port map (
        clk       => clk,
        reset     => reset,
        ex_irq    => ex_irq,
        sw_irq    => sw_irq,
        tm_irq    => tm_irq,
        instr_err => instr_err,
        cycle     => cycle,
        timer     => timer,
        instret   => instret,
        exec_res  => exec_res,
        dmld_data => dmld_data,
        pc        => pc,
        next_pc   => next_pc,
        imm       => imm,
        func3     => func3,
        regs_addr => regs_addr,
        csrs_addr => csrs_addr,
        istg_ctrl => istg_ctrl,
        rd_data0  => reg0_data,
        rd_data1  => reg1_data
    );

    stage_ex_block: ex_block port map (
        reg0      => reg0_data,
        reg1      => reg1_data,
        pc        => pc,
        imm       => imm,
        func3     => func3,
        func7     => func7,
        exec_ctrl => exec_ctrl,
        res       => exec_res,
        target    => target,
        taken     => taken
    );

    stage_lsu: lsu port map (
        dmld_data  => dmld_data,
        dmst_data  => reg1_data,
        dmls_addr  => exec_res,
        dmls_dtype => func3,
        dmls_ctrl  => dmls_ctrl,
        dmrd_data  => dmrd_data,
        dmwr_data  => dmwr_data,
        dmrd_en    => dmrd_en, 
        dmwr_en    => dmwr_en,
        dmrw_addr  => dmrw_addr,
        dm_byte_en => dm_byte_en
    );

end architecture id_ex_stage_arch;