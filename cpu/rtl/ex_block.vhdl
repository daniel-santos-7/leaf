----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: execution block
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

entity ex_block is
    port (
        trap_taken  : in  std_logic;
        trap_target : in  std_logic_vector(31 downto 0);
        func3       : in  std_logic_vector(2  downto 0);
        func7       : in  std_logic_vector(6  downto 0);
        reg0        : in  std_logic_vector(31 downto 0);
        reg1        : in  std_logic_vector(31 downto 0);
        pc          : in  std_logic_vector(31 downto 0);
        imm         : in  std_logic_vector(31 downto 0);
        exec_ctrl   : in  std_logic_vector(7  downto 0);
        dmls_ctrl   : in  std_logic_vector(1  downto 0);
        dmrd_err    : in  std_logic;
        dmwr_err    : in  std_logic;
        dmrd_data   : in  std_logic_vector(31 downto 0);
        imrd_malgn  : out std_logic;
        dmld_malgn  : out std_logic;
        dmld_fault  : out std_logic;
        dmst_malgn  : out std_logic;
        dmst_fault  : out std_logic;
        dmrd_en     : out std_logic;
        dmwr_en     : out std_logic;
        dmwr_data   : out std_logic_vector(31 downto 0);
        dmrw_addr   : out std_logic_vector(31 downto 0);
        dm_byte_en  : out std_logic_vector(3  downto 0);
        dmld_data   : out std_logic_vector(31 downto 0);
        taken       : out std_logic;
        target      : out std_logic_vector(31 downto 0);
        res         : out std_logic_vector(31 downto 0)
    );
end entity ex_block;

architecture ex_block_arch of ex_block is

    signal jmp   : std_logic;
    signal br_en : std_logic;

    signal opd0_src_sel : std_logic;
    signal opd1_src_sel : std_logic;
    signal opd0_pass    : std_logic;
    signal opd1_pass    : std_logic;
    signal ftype        : std_logic;
    signal op_en        : std_logic;

    signal opd0     : std_logic_vector(31 downto 0);
    signal opd1     : std_logic_vector(31 downto 0);
    signal gtd_opd0 : std_logic_vector(31 downto 0);
    signal gtd_opd1 : std_logic_vector(31 downto 0);
    signal alu_op   : std_logic_vector(5  downto 0);
    signal alu_res  : std_logic_vector(31 downto 0);
    signal branch   : std_logic;

begin
    
    jmp   <= exec_ctrl(7);
    br_en <= exec_ctrl(6);

    opd0_src_sel <= exec_ctrl(5);
    opd1_src_sel <= exec_ctrl(4);
    opd0_pass    <= exec_ctrl(3);
    opd1_pass    <= exec_ctrl(2);
    ftype        <= exec_ctrl(1);
    op_en        <= exec_ctrl(0);

    opd0 <= pc  when opd0_src_sel = '1' else reg0;
    opd1 <= imm when opd1_src_sel = '1' else reg1;

    gtd_opd0 <= opd0 and (31 downto 0 => opd0_pass);
    gtd_opd1 <= opd1 and (31 downto 0 => opd1_pass);

    exec_alu_ctrl: alu_ctrl port map (
        op_en => op_en,
        ftype => ftype,
        func3 => func3,
        func7 => func7,
        op    => alu_op
    );

    exec_alu: alu port map (
        opd0 => gtd_opd0, 
        opd1 => gtd_opd1,
        op   => alu_op,
        res  => alu_res
    );

    exec_br_detector: br_detector port map (
        reg0   => reg0,
        reg1   => reg1,
        mode   => func3,
        en     => br_en,
        branch => branch
    );

    imrd_malgn <= alu_res(1) and (branch or jmp);

    taken  <= branch or jmp or trap_taken;
    target <= trap_target when trap_taken = '1' else alu_res(31 downto 1) & b"0";
    res    <= alu_res;

    exec_dmls_block: dmls_block port map (
        dmrd_err   => dmrd_err,
        dmwr_err   => dmwr_err,
        dmls_ctrl  => dmls_ctrl,
        dmls_dtype => func3,
        dmst_data  => reg1,
        dmls_addr  => alu_res,
        dmrd_data  => dmrd_data,
        dmld_malgn => dmld_malgn,
        dmld_fault => dmld_fault,
        dmst_malgn => dmst_malgn,
        dmst_fault => dmst_fault,
        dmrd_en    => dmrd_en,
        dmwr_en    => dmwr_en,
        dmwr_data  => dmwr_data,
        dmrw_addr  => dmrw_addr,
        dm_byte_en => dm_byte_en,
        dmld_data  => dmld_data
    );
    
end architecture ex_block_arch;
