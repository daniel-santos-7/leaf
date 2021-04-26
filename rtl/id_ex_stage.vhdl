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
        no_op: in std_logic;
        rd_mem_data: in std_logic_vector(31 downto 0);
        rd_mem_en: out std_logic;
        wr_mem_en: out std_logic;
        rd_wr_mem_addr: out std_logic_vector(31 downto 0);
        wr_mem_data: out std_logic_vector(31 downto 0);
        branch, jmp, target_shift: out std_logic;
        target: out std_logic_vector(31 downto 0)
    );

end entity id_ex_stage;

architecture id_ex_stage_arch of id_ex_stage is
    
    signal ig_imm_type: std_logic_vector(2 downto 0);
    signal imm: std_logic_vector(31 downto 0);

    signal rf_wr_reg_src: std_logic_vector(1 downto 0);
    signal rf_wr_reg_data: std_logic_vector(31 downto 0);
    signal rf_wr_reg_en: std_logic;
    signal rf_rd_reg_data0, rf_rd_reg_data1: std_logic_vector(31 downto 0);

    signal alu_src0, alu_src1, alu_src0_pass: std_logic;
    signal alu_la_op, alu_imm_op: std_logic;
    signal alu_func: std_logic_vector(9 downto 0);
    signal alu_opd0, alu_opd1: std_logic_vector(31 downto 0);
    signal alu_op: std_logic_vector(3 downto 0);
    signal alu_rslt: std_logic_vector(31 downto 0);

    signal lsu_rd_data: std_logic_vector(31 downto 0);

    signal lsu_mode, lsu_en: std_logic;

    signal br_detector_en: std_logic;

begin

    with rf_wr_reg_src select rf_wr_reg_data <= alu_rslt when b"00", lsu_rd_data when b"01", next_pc when b"10", (31 downto 0 => '-') when others;

    alu_opd0 <= pc when alu_src0 = '1' and alu_src0_pass = '1' else rf_rd_reg_data0 when alu_src1 = '1' and alu_src0_pass = '1' else (31 downto 0 => '0');
    
    alu_opd1 <= imm when alu_src1 = '1' else rf_rd_reg_data1;

    stage_mc: main_ctrl port map (
        opcode => instr(6 downto 0),
        no_op => no_op,
        rf_write_src => rf_wr_reg_src,
        rf_write_en => rf_wr_reg_en,
        ig_imm_type => ig_imm_type,
        alu_src0 => alu_src0, 
        alu_src1 => alu_src1, 
        alu_src0_pass => alu_src0_pass,
        alu_la_op => alu_la_op, 
        alu_imm_op => alu_imm_op,
        lsu_mode => lsu_mode, 
        lsu_en => lsu_en,
        br_detector_en => br_detector_en,
        if_jmp => jmp, 
        if_target_shift => target_shift
    );

    stage_ig: imm_gen port map (
        instr_payload => instr(31 downto 7),
        imm_type => ig_imm_type,
        imm => imm
    );

    stage_rf: reg_file port map (
        clk => clk,
        rd_reg_addr0 => instr(19 downto 15),
        rd_reg_addr1 => instr(24 downto 20),
        wr_reg_addr => instr(11 downto 7),
        wr_reg_data => rf_wr_reg_data,
        wr_reg_en => rf_wr_reg_en,
        rd_reg_data0 => rf_rd_reg_data0, 
        rd_reg_data1 => rf_rd_reg_data1
    );

    stage_br_detector: branch_detector port map (
        reg0 => rf_rd_reg_data0, 
        reg1 => rf_rd_reg_data1,
        mode => instr(14 downto 12),
        en => br_detector_en,
        branch => branch
    );

    stage_alu_ctrl: alu_ctrl port map (
        la_op => alu_la_op,
        imm_op => alu_imm_op,
        func => alu_func,
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
        rd_wr_addr => alu_rslt,
        wr_data => rf_rd_reg_data1,
        data_type => instr(14 downto 12),
        mode => lsu_mode, 
        en => lsu_en,
        rd_mem_en => rd_mem_en, 
        wr_mem_en => wr_mem_en,
        rd_wr_mem_addr => rd_wr_mem_addr, 
        wr_mem_data => wr_mem_data,
        rd_data => lsu_rd_data
    );

    target <= alu_rslt;

end architecture id_ex_stage_arch;