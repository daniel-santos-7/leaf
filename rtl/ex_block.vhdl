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
        clk_i         : in  std_logic;
        reset_i       : in  std_logic;
        exc_taken_i   : in  std_logic;
        mret_i        : in  std_logic;
        mepc_i        : in  std_logic_vector(XLEN-1 downto 2);
        mtvec_base_i  : in  std_logic_vector(XLEN-1 downto 2);
        func3_i       : in  std_logic_vector(2  downto 0);
        reg0_i        : in  std_logic_vector(XLEN-1 downto 0);
        reg1_i        : in  std_logic_vector(XLEN-1 downto 0);
        pc_i          : in  std_logic_vector(XLEN-1 downto 0);
        opd0_src_sel_i : in  std_logic;
        opd1_src_sel_i : in  std_logic;
        opd0_pass_i    : in  std_logic;
        opd1_pass_i    : in  std_logic;
        branch_op_i   : in  std_logic_vector(1  downto 0);
        alu_op_i      : in  std_logic_vector(5  downto 0);
        dmls_ctrl_i   : in  std_logic_vector(1  downto 0);
        data_dat_i   : in  std_logic_vector(XLEN-1 downto 0);
        data_ack_i   : in  std_logic;
        data_err_i   : in  std_logic;
        data_stall_i : in  std_logic;
        redirect_ack_i : in  std_logic;
        immwr_data_i  : in  std_logic_vector(XLEN-1 downto 0);
        imrd_malgn_o  : out std_logic;
        dmld_malgn_o  : out std_logic;
        dmld_fault_o  : out std_logic;
        dmst_malgn_o  : out std_logic;
        dmst_fault_o  : out std_logic;
        data_cyc_o    : out std_logic;
        data_stb_o    : out std_logic;
        data_dat_o    : out std_logic_vector(XLEN-1 downto 0);
        data_adr_o    : out std_logic_vector(XLEN-1 downto 2);
        data_sel_o    : out std_logic_vector(3  downto 0);
        data_we_o     : out std_logic;
        dmld_data_o   : out std_logic_vector(XLEN-1 downto 0);
        taken_o  : out std_logic;
        target_o : out std_logic_vector(XLEN-1 downto 0);
        ready_o       : out std_logic;
        flush_o       : out std_logic;
        res_o         : out std_logic_vector(XLEN-1 downto 0)
    );
end entity ex_block;

architecture ex_block_arch of ex_block is

    signal alu_res       : std_logic_vector(XLEN-1 downto 0);
    signal alu_arith_res : std_logic_vector(XLEN-1 downto 0);

    signal dmls_ready : std_logic;

    signal dmls_cyc : std_logic;
    signal dmls_stb : std_logic;
    signal dmls_adr : std_logic_vector(XLEN-1 downto 2);
    signal dmls_dat : std_logic_vector(XLEN-1 downto 0);
    signal dmls_sel : std_logic_vector(3 downto 0);
    signal dmls_we  : std_logic;

    signal br_detector_imrd_malgn : std_logic;
    signal dmls_dmld_malgn : std_logic;
    signal dmls_dmld_fault : std_logic;
    signal dmls_dmst_malgn : std_logic;
    signal dmls_dmst_fault : std_logic;

    signal ex_trap_taken  : std_logic;
    signal ex_trap_target : std_logic_vector(XLEN-1 downto 0);

    signal taken_int      : std_logic;

begin

    exec_alu: alu port map (
        pc_i           => pc_i,
        reg0_i         => reg0_i,
        reg1_i         => reg1_i,
        immwr_data_i   => immwr_data_i,
        opd0_src_sel_i => opd0_src_sel_i,
        opd1_src_sel_i => opd1_src_sel_i,
        opd0_pass_i    => opd0_pass_i,
        opd1_pass_i    => opd1_pass_i,
        op_i           => alu_op_i,
        res_o          => alu_res,
        arith_res_o    => alu_arith_res
    );

    exec_br_detector: br_detector port map (
        clk_i         => clk_i,
        reset_i       => reset_i,
        redirect_ack_i => redirect_ack_i,
        reg0_i        => reg0_i,
        reg1_i        => reg1_i,
        mode_i        => func3_i,
        en_i          => branch_op_i(0),
        jmp_i         => branch_op_i(1),
        arith_res_i   => alu_arith_res,
        trap_taken_i  => ex_trap_taken,
        trap_target_i => ex_trap_target,
        taken_o       => taken_int,
        target_o      => target_o,
        imrd_malgn_o  => br_detector_imrd_malgn
    );

    exec_dmls_block: dmls_block port map (
        clk_i         => clk_i,
        reset_i       => reset_i,
        dmls_ctrl_i   => dmls_ctrl_i,
        dmls_dtype_i  => func3_i,
        dmst_data_i   => reg1_i,
        arith_res_i   => alu_arith_res,
        data_dat_i    => data_dat_i,
        data_ack_i    => data_ack_i,
        data_err_i    => data_err_i,
        data_stall_i  => data_stall_i,
        data_cyc_o    => dmls_cyc,
        data_stb_o    => dmls_stb,
        data_dat_o    => dmls_dat,
        data_adr_o    => dmls_adr,
        data_sel_o    => dmls_sel,
        data_we_o     => dmls_we,
        dmls_ready_o  => dmls_ready,
        dmld_malgn_o  => dmls_dmld_malgn,
        dmld_fault_o  => dmls_dmld_fault,
        dmst_malgn_o  => dmls_dmst_malgn,
        dmst_fault_o  => dmls_dmst_fault,
        dmld_data_o   => dmld_data_o
    );

    imrd_malgn_o <= br_detector_imrd_malgn;
    dmld_malgn_o <= dmls_dmld_malgn;
    dmld_fault_o <= dmls_dmld_fault;
    dmst_malgn_o <= dmls_dmst_malgn;
    dmst_fault_o <= dmls_dmst_fault;

    ex_trap_taken  <= exc_taken_i or mret_i or
                      br_detector_imrd_malgn or dmls_dmld_malgn or dmls_dmst_malgn or
                      dmls_dmld_fault or dmls_dmst_fault;
    ex_trap_target <= mepc_i & b"00" when mret_i = '1' else mtvec_base_i & b"00";

    data_cyc_o <= dmls_cyc;
    data_stb_o <= dmls_stb;
    data_dat_o <= dmls_dat;
    data_adr_o <= dmls_adr;
    data_sel_o <= dmls_sel;
    data_we_o  <= dmls_we;
    res_o      <= alu_res;
    ready_o    <= dmls_ready;
    taken_o    <= taken_int;
    flush_o    <= taken_int;

end architecture ex_block_arch;