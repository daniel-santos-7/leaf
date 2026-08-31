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
        clk_i          : in  std_logic;
        reset_i        : in  std_logic;
        -- Trap redirect, already resolved in id_stage. Exception versus mret
        -- only matters for picking mtvec over mepc, and both registers live in
        -- csrs, so that mux stays next to them.
        trap_taken_i   : in  std_logic;
        trap_target_i  : in  std_logic_vector(XLEN-1 downto 0);
        func3_i        : in  std_logic_vector(2  downto 0);
        reg0_i         : in  std_logic_vector(XLEN-1 downto 0);
        reg1_i         : in  std_logic_vector(XLEN-1 downto 0);
        pc_i           : in  std_logic_vector(XLEN-1 downto 0);
        immwr_data_i   : in  std_logic_vector(XLEN-1 downto 0);
        opd_src_sel_i  : in  std_logic_vector(1  downto 0);
        opd_pass_i     : in  std_logic_vector(1  downto 0);
        branch_op_i    : in  std_logic_vector(1  downto 0);
        alu_op_i       : in  std_logic_vector(5  downto 0);
        dmls_ctrl_i    : in  std_logic_vector(1  downto 0);
        redirect_ack_i : in  std_logic;

        ready_o        : out std_logic;
        flush_o        : out std_logic;
        taken_o        : out std_logic;
        target_o       : out std_logic_vector(XLEN-1 downto 0);
        res_o          : out std_logic_vector(XLEN-1 downto 0);
        -- pc+4, out of the alu's own incrementer: the JAL/JALR link address,
        -- and the mepc a wfi trap stacks -- csrs reads this one instead of
        -- building a second.
        pc_next_o      : out std_logic_vector(XLEN-1 downto 0);
        imrd_malgn_o   : out std_logic;
        dmld_malgn_o   : out std_logic;
        dmld_fault_o   : out std_logic;
        dmst_malgn_o   : out std_logic;
        dmst_fault_o   : out std_logic;
        dmld_data_o    : out std_logic_vector(XLEN-1 downto 0);

        data_cyc_o     : out std_logic;
        data_stb_o     : out std_logic;
        data_we_o      : out std_logic;
        data_sel_o     : out std_logic_vector(3      downto 0);
        data_adr_o     : out std_logic_vector(XLEN-1 downto 2);
        data_dat_o     : out std_logic_vector(XLEN-1 downto 0);
        data_dat_i     : in  std_logic_vector(XLEN-1 downto 0);
        data_ack_i     : in  std_logic;
        data_err_i     : in  std_logic;
        data_stall_i   : in  std_logic
    );
end entity ex_block;

architecture ex_block_arch of ex_block is

    signal alu_res       : std_logic_vector(XLEN-1 downto 0);
    signal alu_arith_res : std_logic_vector(XLEN-1 downto 0);
    signal alu_pc_next   : std_logic_vector(XLEN-1 downto 0);

    signal br_detector_taken      : std_logic;
    signal br_detector_target     : std_logic_vector(XLEN-1 downto 0);
    signal br_detector_imrd_malgn : std_logic;

    signal dmls_block_dmls_ready : std_logic;
    signal dmls_block_dmld_data  : std_logic_vector(XLEN-1 downto 0);
    signal dmls_block_dmld_malgn : std_logic;
    signal dmls_block_dmld_fault : std_logic;
    signal dmls_block_dmst_malgn : std_logic;
    signal dmls_block_dmst_fault : std_logic;
    signal dmls_block_data_cyc   : std_logic;
    signal dmls_block_data_stb   : std_logic;
    signal dmls_block_data_we    : std_logic;
    signal dmls_block_data_sel   : std_logic_vector(3      downto 0);
    signal dmls_block_data_adr   : std_logic_vector(XLEN-1 downto 2);
    signal dmls_block_data_dat   : std_logic_vector(XLEN-1 downto 0);

begin

    exec_alu: alu port map (
        pc_i          => pc_i,
        reg0_i        => reg0_i,
        reg1_i        => reg1_i,
        immwr_data_i  => immwr_data_i,
        opd_src_sel_i => opd_src_sel_i,
        opd_pass_i    => opd_pass_i,
        op_i          => alu_op_i,
        res_o         => alu_res,
        arith_res_o   => alu_arith_res,
        pc_next_o     => alu_pc_next
    );

    exec_br_detector: br_detector port map (
        clk_i          => clk_i,
        reset_i        => reset_i,
        redirect_ack_i => redirect_ack_i,
        reg0_i         => reg0_i,
        reg1_i         => reg1_i,
        mode_i         => func3_i,
        en_i           => branch_op_i(0),
        jmp_i          => branch_op_i(1),
        arith_res_i    => alu_arith_res,
        trap_taken_i   => trap_taken_i,
        trap_target_i  => trap_target_i,
        taken_o        => br_detector_taken,
        target_o       => br_detector_target,
        imrd_malgn_o   => br_detector_imrd_malgn
    );

    exec_dmls_block: dmls_block port map (
        clk_i        => clk_i,
        reset_i      => reset_i,
        dmls_ctrl_i  => dmls_ctrl_i,
        dmls_dtype_i => func3_i,
        dmst_data_i  => reg1_i,
        arith_res_i  => alu_arith_res,
        data_dat_i   => data_dat_i,
        data_ack_i   => data_ack_i,
        data_err_i   => data_err_i,
        data_stall_i => data_stall_i,
        data_cyc_o   => dmls_block_data_cyc,
        data_stb_o   => dmls_block_data_stb,
        data_dat_o   => dmls_block_data_dat,
        data_adr_o   => dmls_block_data_adr,
        data_sel_o   => dmls_block_data_sel,
        data_we_o    => dmls_block_data_we,
        dmls_ready_o => dmls_block_dmls_ready,
        dmld_malgn_o => dmls_block_dmld_malgn,
        dmld_fault_o => dmls_block_dmld_fault,
        dmst_malgn_o => dmls_block_dmst_malgn,
        dmst_fault_o => dmls_block_dmst_fault,
        dmld_data_o  => dmls_block_dmld_data
    );

    ready_o      <= dmls_block_dmls_ready;
    flush_o      <= br_detector_taken;
    taken_o      <= br_detector_taken;
    target_o     <= br_detector_target;
    res_o        <= alu_res;
    pc_next_o    <= alu_pc_next;

    imrd_malgn_o <= br_detector_imrd_malgn;
    dmld_malgn_o <= dmls_block_dmld_malgn;
    dmld_fault_o <= dmls_block_dmld_fault;
    dmst_malgn_o <= dmls_block_dmst_malgn;
    dmst_fault_o <= dmls_block_dmst_fault;
    dmld_data_o  <= dmls_block_dmld_data;

    data_cyc_o   <= dmls_block_data_cyc;
    data_stb_o   <= dmls_block_data_stb;
    data_we_o    <= dmls_block_data_we;
    data_sel_o   <= dmls_block_data_sel;
    data_adr_o   <= dmls_block_data_adr;
    data_dat_o   <= dmls_block_data_dat;

end architecture ex_block_arch;
