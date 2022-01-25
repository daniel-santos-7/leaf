library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity id_ex_stage is
    
    port (
        clk:   in std_logic;
        reset: in std_logic;
        
        pc:         in std_logic_vector(31 downto 0);
        next_pc:    in std_logic_vector(31 downto 0);
        instr:      in std_logic_vector(31 downto 0);
        flush:      in std_logic;
        
        rd_mem_data:    in  std_logic_vector(31 downto 0);
        wr_mem_data:    out std_logic_vector(31 downto 0);
        rd_mem_en:      out std_logic;
        wr_mem_en:      out std_logic;
        rd_wr_mem_addr: out std_logic_vector(31 downto 0);
        wr_mem_byte_en: out std_logic_vector(3 downto 0);

        ex_irq: in std_logic;
        sw_irq: in std_logic;
        tm_irq: in std_logic;
        
        branch:  out std_logic; 
        jmp:     out std_logic; 
        trap:    out std_logic;
        
        target: out std_logic_vector(31 downto 0)
    );

end entity id_ex_stage;

architecture id_ex_stage_arch of id_ex_stage is
    
    signal imm:      std_logic_vector(31 downto 0);

    signal regs_addr: std_logic_vector(14 downto 0);

    signal int_strg_ctrl: std_logic_vector(2 downto 0);

    signal rf_wr_reg_data:  std_logic_vector(31 downto 0);
    signal rf_rd_reg_data0: std_logic_vector(31 downto 0);
    signal rf_rd_reg_data1: std_logic_vector(31 downto 0);

    signal brd_reg0:   std_logic_vector(31 downto 0);
    signal brd_reg1:   std_logic_vector(31 downto 0);
    signal brde_mode:   std_logic_vector(2 downto 0);
    signal brde_ctrl: std_logic_vector(1 downto 0);
    signal brd_branch: std_logic;

    signal csrs_mode: std_logic_vector(2 downto 0);

    signal csrs_ctrl: std_logic;

    signal csrs_addr: std_logic_vector(11 downto 0);

    signal csrs_wr_reg_data: std_logic_vector(31 downto 0);
    signal csrs_wr_imm_data: std_logic_vector(31 downto 0);
    signal csrs_rd_data:     std_logic_vector(31 downto 0);

    signal ex_ctrl: std_logic_vector(5 downto 0);
    signal ex_func: std_logic_vector(9 downto 0);

    signal alu_opd0: std_logic_vector(31 downto 0);
    signal alu_opd1: std_logic_vector(31 downto 0);
    signal alu_res:  std_logic_vector(31 downto 0);

    signal dmls_addr:  std_logic_vector(31 downto 0);
    signal dmst_data:  std_logic_vector(31 downto 0);
    signal dmls_dtype: std_logic_vector(2 downto 0);
    signal dmls_ctrl:  std_logic_vector(1 downto 0);
    signal dmld_data:  std_logic_vector(31 downto 0);

begin

    brd_reg0 <= rf_rd_reg_data0;
    brd_reg1 <= rf_rd_reg_data1;
    
    csrs_wr_reg_data <= rf_rd_reg_data0;
    csrs_wr_imm_data <= imm;

    uut: id_block port map (
        instr         => instr,
        flush         => flush,
        regs_addr     => regs_addr,
        csrs_addr     => csrs_addr,
        ex_func       => ex_func,
        csrs_mode     => csrs_mode,
        brde_mode     => brde_mode,
        dmls_dtype    => dmls_dtype,
        imm           => imm,
        int_strg_ctrl => int_strg_ctrl,
        ex_ctrl       => ex_ctrl,
        dmls_ctrl     => dmls_ctrl,
        brde_ctrl     => brde_ctrl,
        csrs_ctrl     => csrs_ctrl
    );

    stage_int_strg: int_strg port map (
        clk        => clk,
        wr_src0    => alu_res,
        wr_src1    => dmld_data,
        wr_src2    => next_pc,
        wr_src3    => csrs_rd_data,
        regs_addr  => regs_addr,
        int_strg_ctrl => int_strg_ctrl,
        rd_data0   => rf_rd_reg_data0,
        rd_data1   => rf_rd_reg_data1
    );

    stage_br_detector: br_detector port map (
        reg0   => brd_reg0, 
        reg1   => brd_reg1,
        mode   => brde_mode,
        en     => brde_ctrl(1),
        branch => brd_branch
    );

    stage_csrs: csrs port map (
        clk         => clk,
        reset       => reset,
        ex_irq      => ex_irq,
        sw_irq      => sw_irq,
        tm_irq      => tm_irq,
        wr_mode     => csrs_mode,
        wr_en       => csrs_ctrl,
        rd_wr_addr  => csrs_addr,
        wr_reg_data => csrs_wr_reg_data,
        wr_imm_data => csrs_wr_imm_data,
        rd_data     => csrs_rd_data
    );

    stage_ex_block: ex_block port map (
        opd0_src0 => rf_rd_reg_data0,
        opd0_src1 => pc,
        opd1_src0 => rf_rd_reg_data1,
        opd1_src1 => imm,
        ex_ctrl   => ex_ctrl,
        ex_func   => ex_func,
        res       => alu_res
    );

    dmst_data <= rf_rd_reg_data1;
    dmls_addr <= alu_res;

    stage_lsu: lsu port map (
        dmld_data      => dmld_data,
        dmst_data      => dmst_data,
        dmls_addr      => dmls_addr,
        dmls_dtype     => dmls_dtype,
        dmls_ctrl      => dmls_ctrl,
        dmrd_data    => rd_mem_data,
        dmwr_data    => wr_mem_data,
        dmrd_en      => rd_mem_en, 
        dmwr_en      => wr_mem_en,
        dmrw_addr => rd_wr_mem_addr,
        dm_byte_en => wr_mem_byte_en
    );

    branch <= brd_branch;
    target <= alu_res;
    trap   <= '0';

    jmp <= brde_ctrl(0);

end architecture id_ex_stage_arch;