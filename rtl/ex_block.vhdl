----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: execution block
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

entity ex_block is
    port (
        trap_taken_i  : in  std_logic;
        trap_target_i : in  std_logic_vector(XLEN-1 downto 0);
        func3_i       : in  std_logic_vector(2  downto 0);
        func7_i       : in  std_logic_vector(6  downto 0);
        reg0_i        : in  std_logic_vector(XLEN-1 downto 0);
        reg1_i        : in  std_logic_vector(XLEN-1 downto 0);
        pc_i          : in  std_logic_vector(XLEN-1 downto 0);
        imm_i         : in  std_logic_vector(XLEN-1 downto 0);
        csrrd_data_i  : in  std_logic_vector(XLEN-1 downto 0);
        jmp_i         : in  std_logic;
        br_en_i       : in  std_logic;
        opd0_src_sel_i: in  std_logic;
        opd1_src_sel_i: in  std_logic;
        opd0_pass_i   : in  std_logic;
        opd1_pass_i   : in  std_logic;
        ftype_i       : in  std_logic;
        op_en_i       : in  std_logic;
        dmls_mode_i   : in  std_logic;
        dmls_en_i     : in  std_logic;
        dmrd_err_i    : in  std_logic;
        dmwr_err_i    : in  std_logic;
        dmrd_data_i   : in  std_logic_vector(XLEN-1 downto 0);
        imrd_malgn_o  : out std_logic;
        dmld_malgn_o  : out std_logic;
        dmld_fault_o  : out std_logic;
        dmst_malgn_o  : out std_logic;
        dmst_fault_o  : out std_logic;
        dmrd_en_o     : out std_logic;
        dmwr_en_o     : out std_logic;
        dmwr_data_o   : out std_logic_vector(XLEN-1 downto 0);
        dmrw_addr_o   : out std_logic_vector(XLEN-1 downto 0);
        dm_byte_en_o  : out std_logic_vector(3  downto 0);
        dmld_data_o   : out std_logic_vector(XLEN-1 downto 0);
        csrwr_data_o  : out std_logic_vector(XLEN-1 downto 0);
        taken_o       : out std_logic;
        target_o      : out std_logic_vector(XLEN-1 downto 0);
        res_o         : out std_logic_vector(XLEN-1 downto 0)
    );
end entity ex_block;

architecture ex_block_arch of ex_block is

    signal opd0     : std_logic_vector(XLEN-1 downto 0);
    signal opd1     : std_logic_vector(XLEN-1 downto 0);
    signal gtd_opd0 : std_logic_vector(XLEN-1 downto 0);
    signal gtd_opd1 : std_logic_vector(XLEN-1 downto 0);
    signal alu_op   : std_logic_vector(5  downto 0);
    signal alu_res  : std_logic_vector(XLEN-1 downto 0);
    signal branch   : std_logic;

begin

    opd0 <= pc_i  when opd0_src_sel_i = '1' else reg0_i;
    opd1 <= imm_i when opd1_src_sel_i = '1' else reg1_i;

    gtd_opd0 <= opd0 and (XLEN-1 downto 0 => opd0_pass_i);
    gtd_opd1 <= opd1 and (XLEN-1 downto 0 => opd1_pass_i);

    exec_alu_ctrl: alu_ctrl port map (
        op_en_i => op_en_i,
        ftype_i => ftype_i,
        func3_i => func3_i,
        func7_i => func7_i,
        op_o    => alu_op
    );

    exec_alu: alu port map (
        opd0_i => gtd_opd0,
        opd1_i => gtd_opd1,
        op_i   => alu_op,
        res_o  => alu_res
    );

    exec_csrs_logic: csrs_logic port map (
        csrwr_mode_i => func3_i,
        csrrd_data_i => csrrd_data_i,
        regwr_data_i => reg0_i,
        immwr_data_i => imm_i,
        csrwr_data_o => csrwr_data_o
    );

    exec_br_detector: br_detector port map (
        reg0_i   => reg0_i,
        reg1_i   => reg1_i,
        mode_i   => func3_i,
        en_i     => br_en_i,
        branch_o => branch
    );

    imrd_malgn_o <= alu_res(1) and (branch or jmp_i);

    taken_o  <= branch or jmp_i or trap_taken_i;
    target_o <= trap_target_i when trap_taken_i = '1' else alu_res(XLEN-1 downto 1) & b"0";
    res_o    <= alu_res;

    exec_dmls_block: dmls_block port map (
        dmrd_err   => dmrd_err_i,
        dmwr_err   => dmwr_err_i,
        dmls_mode  => dmls_mode_i,
        dmls_en    => dmls_en_i,
        dmls_dtype => func3_i,
        dmst_data  => reg1_i,
        dmls_addr  => alu_res,
        dmrd_data  => dmrd_data_i,
        dmld_malgn => dmld_malgn_o,
        dmld_fault => dmld_fault_o,
        dmst_malgn => dmst_malgn_o,
        dmst_fault => dmst_fault_o,
        dmrd_en    => dmrd_en_o,
        dmwr_en    => dmwr_en_o,
        dmwr_data  => dmwr_data_o,
        dmrw_addr  => dmrw_addr_o,
        dm_byte_en => dm_byte_en_o,
        dmld_data  => dmld_data_o
    );

end architecture ex_block_arch;
