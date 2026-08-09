----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: execution block
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_pkg.all;

entity ex_block is
    port (
        clk_i         : in  std_logic;
        reset_i       : in  std_logic;
        -- Trap redirect, already resolved in id_stage: whether a trap commits
        -- this cycle and where it goes. The distinction between an exception
        -- and an mret only matters for picking mtvec over mepc, and both of
        -- those registers live in csrs -- so the mux stays next to them.
        trap_taken_i  : in  std_logic;
        trap_target_i : in  std_logic_vector(XLEN-1 downto 0);
        func3_i       : in  std_logic_vector(2  downto 0);
        reg0_i        : in  std_logic_vector(XLEN-1 downto 0);
        reg1_i        : in  std_logic_vector(XLEN-1 downto 0);
        pc_i          : in  std_logic_vector(XLEN-1 downto 0);
        opd_src_sel_i : in  std_logic_vector(1  downto 0);
        opd_pass_i    : in  std_logic_vector(1  downto 0);
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
        res_o         : out std_logic_vector(XLEN-1 downto 0);
        -- JAL/JALR link address (pc+4). The ALU cannot produce it: its single
        -- adder is already computing the jump target for those very
        -- instructions, so the link needs its own incrementer.
        link_o        : out std_logic_vector(XLEN-1 downto 0)
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

    signal taken_int      : std_logic;

begin

    exec_alu: alu port map (
        pc_i           => pc_i,
        reg0_i         => reg0_i,
        reg1_i         => reg1_i,
        immwr_data_i   => immwr_data_i,
        opd_src_sel_i  => opd_src_sel_i,
        opd_pass_i     => opd_pass_i,
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
        trap_taken_i  => trap_taken_i,
        trap_target_i => trap_target_i,
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
    -- pc_i is word-aligned, so +4 is an increment of the word address
    link_o     <= std_logic_vector(unsigned(pc_i(XLEN-1 downto 2)) + 1) & b"00";

end architecture ex_block_arch;