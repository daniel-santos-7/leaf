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
    
    signal opcode: std_logic_vector(6 downto 0);

    signal ig_payload:  std_logic_vector(24 downto 0);
    signal ig_imm_type: std_logic_vector(2  downto 0);
    signal ig_imm:      std_logic_vector(31 downto 0);

    signal rf_wr_reg_src:   std_logic_vector(1 downto 0);
    signal rf_rd_reg_addr0: std_logic_vector(4 downto 0);
    signal rf_rd_reg_addr1: std_logic_vector(4 downto 0);
    signal rf_wr_reg_addr:  std_logic_vector(4 downto 0);
    signal rf_wr_reg_en:    std_logic;
    signal rf_wr_reg_data:  std_logic_vector(31 downto 0);
    signal rf_rd_reg_data0: std_logic_vector(31 downto 0);
    signal rf_rd_reg_data1: std_logic_vector(31 downto 0);

    signal brd_reg0:   std_logic_vector(31 downto 0);
    signal brd_reg1:   std_logic_vector(31 downto 0);
    signal brd_mode:   std_logic_vector(2  downto 0);
    signal brd_en:     std_logic;
    signal brd_branch: std_logic;

    signal csrs_wr_mode:     std_logic_vector(2  downto 0);
    signal csrs_wr_en:       std_logic;
    signal csrs_rd_wr_addr:  std_logic_vector(11 downto 0);
    signal csrs_wr_reg_data: std_logic_vector(31 downto 0);
    signal csrs_wr_imm_data: std_logic_vector(31 downto 0);
    signal csrs_rd_data:     std_logic_vector(31 downto 0);

    signal alu_src0:      std_logic;
    signal alu_src1:      std_logic;
    signal alu_opd0_pass: std_logic;
    signal alu_opd1_pass: std_logic;
    
    signal alu_op_en:     std_logic;
    signal alu_func_type: std_logic;
    signal alu_func3:     std_logic_vector(2 downto 0);
    signal alu_func7:     std_logic_vector(6 downto 0);
    
    signal alu_opd0: std_logic_vector(31 downto 0);
    signal alu_opd1: std_logic_vector(31 downto 0);
    signal alu_res:  std_logic_vector(31 downto 0);

    signal lsu_rd_wr_addr: std_logic_vector(31 downto 0);
    signal lsu_wr_data:    std_logic_vector(31 downto 0);
    signal lsu_data_type:  std_logic_vector(2  downto 0);
    signal lsu_mode:       std_logic; 
    signal lsu_en:         std_logic;
    signal lsu_rd_data:    std_logic_vector(31 downto 0);

begin

    opcode <= instr(6 downto 0);

    ig_payload <= instr(31 downto 7);

    rf_rd_reg_addr0 <= instr(19 downto 15);
    rf_rd_reg_addr1 <= instr(24 downto 20);
    rf_wr_reg_addr  <= instr(11 downto  7);

    brd_reg0 <= rf_rd_reg_data0;
    brd_reg1 <= rf_rd_reg_data1;
    brd_mode <= instr(14 downto 12);
    
    csrs_wr_mode     <= instr(14 downto 12);
    csrs_rd_wr_addr  <= instr(31 downto 20);
    csrs_wr_reg_data <= rf_rd_reg_data0;
    csrs_wr_imm_data <= ig_imm;

    alu_func3 <= instr(14 downto 12);
    alu_func7 <= instr(31 downto 25);

    lsu_rd_wr_addr <= alu_res;
    lsu_wr_data    <= rf_rd_reg_data1;
    lsu_data_type  <= instr(14 downto 12);

    stage_mc: main_ctrl port map (
        opcode          => opcode,
        flush           => flush,
        rf_wr_reg_src   => rf_wr_reg_src,
        rf_wr_reg_en    => rf_wr_reg_en,
        ig_imm_type     => ig_imm_type,
        alu_src0        => alu_src0, 
        alu_src1        => alu_src1, 
        alu_opd0_pass   => alu_opd0_pass,
        alu_opd1_pass   => alu_opd1_pass,
        alu_op_en       => alu_op_en, 
        alu_func_type   => alu_func_type,
        lsu_mode        => lsu_mode, 
        lsu_en          => lsu_en,
        brd_en          => brd_en,
        csrs_wr_en      => csrs_wr_en,
        if_jmp          => jmp
    );

    stage_ig: imm_gen port map (
        payload  => ig_payload,
        imm_type => ig_imm_type,
        imm      => ig_imm
    );

    stage_int_strg: int_strg port map (
        clk        => clk,
        wr_en      => rf_wr_reg_en,
        wr_addr    => rf_wr_reg_addr,
        wr_src0    => alu_res,
        wr_src1    => lsu_rd_data,
        wr_src2    => next_pc,
        wr_src3    => csrs_rd_data,
        wr_src_sel => rf_wr_reg_src,
        rd_addr0   => rf_rd_reg_addr0,
        rd_addr1   => rf_rd_reg_addr1,
        rd_data0   => rf_rd_reg_data0,
        rd_data1   => rf_rd_reg_data1
    );

    stage_br_detector: br_detector port map (
        reg0   => brd_reg0, 
        reg1   => brd_reg1,
        mode   => brd_mode,
        en     => brd_en,
        branch => brd_branch
    );

    stage_csrs: csrs port map (
        clk         => clk,
        reset       => reset,
        ex_irq      => ex_irq,
        sw_irq      => sw_irq,
        tm_irq      => tm_irq,
        wr_mode     => csrs_wr_mode,
        wr_en       => csrs_wr_en,
        rd_wr_addr  => csrs_rd_wr_addr,
        wr_reg_data => csrs_wr_reg_data,
        wr_imm_data => csrs_wr_imm_data,
        rd_data     => csrs_rd_data
    );

    stage_ex_block: ex_block port map (
        opd0_src0    => rf_rd_reg_data0,
        opd0_src1    => pc,
        opd1_src0    => rf_rd_reg_data1,
        opd1_src1    => ig_imm,
        opd0_src_sel => alu_src0,
        opd1_src_sel => alu_src1,
        opd0_pass    => alu_opd0_pass,
        opd1_pass    => alu_opd1_pass,
        func_type    => alu_func_type,
        op_en        => alu_op_en,
        func3        => alu_func3,
        func7        => alu_func7,
        res          => alu_res
    );

    stage_lsu: lsu port map (
        rd_data        => lsu_rd_data,
        wr_data        => lsu_wr_data,
        rd_wr_addr     => lsu_rd_wr_addr,
        data_type      => lsu_data_type,
        mode           => lsu_mode, 
        en             => lsu_en,
        rd_mem_data    => rd_mem_data,
        wr_mem_data    => wr_mem_data,
        rd_mem_en      => rd_mem_en, 
        wr_mem_en      => wr_mem_en,
        rd_wr_mem_addr => rd_wr_mem_addr,
        wr_mem_byte_en => wr_mem_byte_en
    );

    branch <= brd_branch;
    target <= alu_res;
    trap   <= '0';

end architecture id_ex_stage_arch;