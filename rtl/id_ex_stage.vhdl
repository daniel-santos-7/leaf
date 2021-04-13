library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity id_ex_stage is
    
    port (
        clk: in std_logic;
        instr: in std_logic_vector(31 downto 0);
        ex_rslt: out std_logic_vector(31 downto 0)
    );

end entity id_ex_stage;

architecture id_ex_stage_arch of id_ex_stage is

    signal opcode: std_logic_vector(6 downto 0);
    signal func3: std_logic_vector(2 downto 0);
    signal func7: std_logic_vector(6 downto 0);

    signal rf_reg_wr: std_logic;
    signal rf_rd_reg0, rf_rd_reg1, rf_wr_reg: std_logic_vector(4 downto 0);

    signal se_in_num: std_logic_vector(11 downto 0);

    signal alu_mux_src0, alu_mux_src1: std_logic_vector(31 downto 0);
    signal alu_mux_slt: std_logic;

    signal alu_op: std_logic_vector(3 downto 0);
    signal alu_opd0, alu_opd1: std_logic_vector(31 downto 0);

    signal ex_rslt_i: std_logic_vector(31 downto 0);

    signal alu_zero: std_logic;

begin

    opcode <= instr(6 downto 0);
    func3 <= instr(14 downto 12);
    func7 <= instr(31 downto 25);
    se_in_num <= instr(31 downto 20);

    rf_rd_reg0 <= instr(19 downto 15);
    rf_rd_reg1 <= instr(24 downto 20);
    rf_wr_reg <= instr(11 downto 7);

    ex_rslt <= ex_rslt_i;

    stage_main_ctrl: main_ctrl port map (
        clk => clk,
        opcode => opcode,
        rf_write => rf_reg_wr
    );

    stage_rf: reg_file port map (
        clk => clk,
        rd_reg0 => rf_rd_reg0,
        rd_reg1 => rf_rd_reg1,
        wr_reg => rf_wr_reg,
        wr_data => ex_rslt_i,
        reg_wr => rf_reg_wr,
        rd_data0 => alu_opd0,
        rd_data1 => alu_mux_src0
    );

    stage_alu_ctrl: alu_ctrl port map (
        opcode => opcode,
        func3 => func3,
        func7 => func7,
        alu_op => alu_op
    ); 

    stage_alu: alu port map (
        opd0 => alu_opd0, 
        opd1 => alu_opd1,
	    op => alu_op,
	    rslt => ex_rslt_i,
        zero => alu_zero
    ); 

end architecture id_ex_stage_arch;