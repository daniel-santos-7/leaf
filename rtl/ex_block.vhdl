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
        reg0_i        : in  std_logic_vector(XLEN-1 downto 0);
        reg1_i        : in  std_logic_vector(XLEN-1 downto 0);
        opd0_i        : in  std_logic_vector(XLEN-1 downto 0);
        opd1_i        : in  std_logic_vector(XLEN-1 downto 0);
        jmp_i         : in  std_logic;
        br_en_i       : in  std_logic;
        alu_op_i      : in  std_logic_vector(5  downto 0);
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
        taken_o       : out std_logic;
        target_o      : out std_logic_vector(XLEN-1 downto 0);
        res_o         : out std_logic_vector(XLEN-1 downto 0)
    );
end entity ex_block;

architecture ex_block_arch of ex_block is

    signal alu_res  : std_logic_vector(XLEN-1 downto 0);
    signal branch   : std_logic;

begin

    exec_alu: alu port map (
        opd0_i => opd0_i,
        opd1_i => opd1_i,
        op_i   => alu_op_i,
        res_o  => alu_res
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
        dmrd_err_i   => dmrd_err_i,
        dmwr_err_i   => dmwr_err_i,
        dmls_mode_i  => dmls_mode_i,
        dmls_en_i    => dmls_en_i,
        dmls_dtype_i => func3_i,
        dmst_data_i  => reg1_i,
        dmls_addr_i  => alu_res,
        dmrd_data_i  => dmrd_data_i,
        dmld_malgn_o => dmld_malgn_o,
        dmld_fault_o => dmld_fault_o,
        dmst_malgn_o => dmst_malgn_o,
        dmst_fault_o => dmst_fault_o,
        dmrd_en_o    => dmrd_en_o,
        dmwr_en_o    => dmwr_en_o,
        dmwr_data_o  => dmwr_data_o,
        dmrw_addr_o  => dmrw_addr_o,
        dm_byte_en_o => dm_byte_en_o,
        dmld_data_o  => dmld_data_o
    );

end architecture ex_block_arch;
