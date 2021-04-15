library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity id_ex_stage is
    
    port (
        clk: in std_logic;
        pc: in std_logic_vector(31 downto 0);
        next_pc: in std_logic_vector(31 downto 0);
        instr: in std_logic_vector(31 downto 0);
        rd_mem_data: in std_logic_vector(31 downto 0);
        rd_mem_en: out std_logic;
        wr_mem_data: out std_logic_vector(31 downto 0);
        wr_mem_en: out std_logic;
        branch, jal, jalr: out std_logic;
        target: out std_logic_vector(31 downto 0)
    );

end entity id_ex_stage;

architecture id_ex_stage_arch of id_ex_stage is

    signal opcode: std_logic_vector(6 downto 0);
    signal func3: std_logic_vector(2 downto 0);
    signal func7: std_logic_vector(6 downto 0);
    
    signal imm: std_logic_vector(31 downto 0);

    signal rf_rd_reg_addr0, rf_rd_reg_addr1, rf_wr_reg_addr: std_logic_vector(4 downto 0);
    signal rf_wr_reg_data: std_logic_vector(31 downto 0);
    signal rf_wr_reg_en: std_logic;
    signal rf_rd_reg_data0, rf_rd_reg_data1: std_logic_vector(31 downto 0);
    
    signal rf_write_src: std_logic;

    signal branch_en, jal_i, jalr_i: std_logic;

    signal branch_mode: std_logic_vector(2 downto 0);
    signal branch_i: std_logic;

    signal alu_src0, alu_src1: std_logic;

    signal alu_opd0, alu_opd1: std_logic_vector(31 downto 0);
    signal alu_op: std_logic_vector(3 downto 0);
    signal alu_rslt: std_logic_vector(31 downto 0);

    signal lsu_mode, lsu_en: std_logic;
    signal lsu_data_type: std_logic_vector(2 downto 0);
    signal lsu_rd_data: std_logic_vector(31 downto 0);

    signal wb_data: std_logic_vector(31 downto 0);

begin

    opcode <= instr(6 downto 0);
    func3 <= instr(14 downto 12);
    func7 <= instr(31 downto 25);

    rf_rd_reg_addr0 <= instr(19 downto 15);
    rf_rd_reg_addr1 <= instr(24 downto 20);
    rf_wr_reg_addr <= instr(11 downto 7);

    rf_wr_reg_data <= next_pc when jal_i = '1' or jalr_i = '1' else wb_data;

    alu_opd0 <= pc when alu_src0 = '1' else rf_rd_reg_data0;
    alu_opd1 <= imm when alu_src1 = '1' else rf_rd_reg_data1;

    branch_mode <= instr(14 downto 12);

    wb_data <= lsu_rd_data when rf_write_src = '1' else alu_rslt;

    stage_imm_gen: imm_gen port map (
        instr => instr,
        imm => imm
    );

    stage_reg_file: reg_file port map (
        clk => clk,
        rd_reg_addr0 => rf_rd_reg_addr0,
        rd_reg_addr1 => rf_rd_reg_addr1,
        wr_reg_addr => rf_wr_reg_addr,
        wr_reg_data => rf_wr_reg_data,
        wr_reg_en => rf_wr_reg_en,
        rd_reg_data0 => rf_rd_reg_data0, 
        rd_reg_data1 => rf_rd_reg_data1
    );

    stage_main_ctrl: main_ctrl port map (
        opcode => opcode,
        rf_write_en => rf_wr_reg_en, 
        rf_write_src => rf_write_src,
        lsu_mode => lsu_mode, 
        lsu_en => lsu_en,
        branch => branch_en, 
        jal => jal_i,
        jalr => jalr_i
    );

    stage_branch_dtct: branch_dtct port map (
        reg0 => rf_rd_reg_data0, 
        reg1 => rf_rd_reg_data1,
        mode => branch_mode,
        branch => branch_i
    );

    stage_alu_ctrl: alu_ctrl port map (
        opcode => opcode,
        func3 => func3,
        func7 => func7,
        alu_src0 => alu_src0,
        alu_src1 => alu_src1,
        alu_op => alu_op
    );

    stage_alu: alu port map (
        opd0 => alu_opd0, 
        opd1 => alu_opd1,
        op => alu_op,
        rslt => alu_rslt
    );

    stage_lsu: lsu port map (
        rd_mem_data => rd_mem_data,
        wr_data => rf_rd_reg_data1,
        data_type => lsu_data_type,
        mode => lsu_mode,
        en => lsu_en,
        rd_mem_en => rd_mem_en,
        wr_mem_en => wr_mem_en,
        wr_mem_data => wr_mem_data,
        rd_data => lsu_rd_data
    );

    branch <= branch_i and branch_en;

    jal <= jal_i;

    jalr <= jalr_i;

    target <= alu_rslt;

end architecture id_ex_stage_arch;