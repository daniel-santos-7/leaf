----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: instruction decode stage
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

entity id_stage is
    generic (
        REG_FILE_SIZE : natural := 32;
        CSRS_MHART_ID : std_logic_vector(XLEN-1 downto 0) := (others => '0')
    );
    port (
        clk_i         : in  std_logic;
        reset_i       : in  std_logic;
        ex_irq_i      : in  std_logic;
        sw_irq_i      : in  std_logic;
        tm_irq_i      : in  std_logic;
        cycle_i       : in  std_logic_vector(63 downto 0);
        timer_i       : in  std_logic_vector(63 downto 0);
        instret_i     : in  std_logic_vector(63 downto 0);

        pc_i          : in  std_logic_vector(XLEN-1 downto 2);
        instr_i       : in  std_logic_vector(XLEN-1 downto 0);
        fault_i       : in  std_logic;
        valid_i       : in  std_logic;
        stale_i       : in  std_logic;

        exc_taken_i   : in  std_logic;
        mcause_exc_i  : in  std_logic_vector(4 downto 0);
        mcause_int_i  : in  std_logic;
        mtval_i       : in  std_logic_vector(XLEN-1 downto 0);
        mepc_i        : in  std_logic_vector(XLEN-1 downto 2);
        regwr_en_i    : in  std_logic;
        csrwr_en_i    : in  std_logic;

        exec_res_i    : in  std_logic_vector(XLEN-1 downto 0);
        pc_next_i     : in  std_logic_vector(XLEN-1 downto 0);
        dmld_data_i   : in  std_logic_vector(XLEN-1 downto 0);
        csrwr_data_i  : in  std_logic_vector(XLEN-1 downto 0);

        flush_i       : in  std_logic;
        ready_i       : in  std_logic;
        ready_o       : out std_logic;

        func3_o       : out std_logic_vector(2  downto 0);
        branch_op_o   : out std_logic_vector(1  downto 0);
        alu_op_o      : out std_logic_vector(5  downto 0);
        dmls_ctrl_o   : out std_logic_vector(1  downto 0);
        mepc_reg_o    : out std_logic_vector(XLEN-1 downto 2);
        mtvec_reg_o   : out std_logic_vector(XLEN-1 downto 2);

        -- The cause set, ranked in ex_block's trap_ctrl.
        instr_err_o   : out std_logic;
        fetch_fault_o : out std_logic;
        ecall_o       : out std_logic;
        ebreak_o      : out std_logic;
        mret_o        : out std_logic;
        wfi_o         : out std_logic;
        exi_trap_o    : out std_logic;
        tmi_trap_o    : out std_logic;
        swi_trap_o    : out std_logic;
        -- Still ungated: the EX faults gate them into regwr_en_i/csrwr_en_i.
        regwr_en_o    : out std_logic;
        csrwr_en_o    : out std_logic;
        rd_data0_o    : out std_logic_vector(XLEN-1 downto 0);
        rd_data1_o    : out std_logic_vector(XLEN-1 downto 0);
        csrrd_data_o  : out std_logic_vector(XLEN-1 downto 0);
        imm_o         : out std_logic_vector(XLEN-1 downto 0);
        opd_src_sel_o : out std_logic_vector(1  downto 0);
        opd_pass_o    : out std_logic_vector(1  downto 0);
        pc_full_o     : out std_logic_vector(XLEN-1 downto 0);
        retire_o      : out std_logic;

        cop_dat_i     : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o     : out std_logic_vector(5      downto 0);
        cop_dat_o     : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o      : out std_logic
    );
end entity id_stage;

architecture rtl of id_stage is

    -- main_ctrl registered (pipeline) outputs
    signal main_ctrl_func3       : std_logic_vector(2  downto 0);
    signal main_ctrl_branch_op   : std_logic_vector(1  downto 0);
    signal main_ctrl_alu_op      : std_logic_vector(5  downto 0);
    signal main_ctrl_dmls_ctrl   : std_logic_vector(1  downto 0);
    signal main_ctrl_imm         : std_logic_vector(XLEN-1 downto 0);
    signal main_ctrl_opd_src_sel : std_logic_vector(1  downto 0);
    signal main_ctrl_opd_pass    : std_logic_vector(1  downto 0);
    signal main_ctrl_regwr_en    : std_logic;
    signal main_ctrl_regwr_sel   : std_logic_vector(1  downto 0);
    signal main_ctrl_regwr_addr  : std_logic_vector(4  downto 0);
    signal main_ctrl_csrwr_en    : std_logic;
    signal main_ctrl_csrs_addr   : std_logic_vector(11 downto 0);

    -- reg_file registered (pipeline) outputs
    signal reg_file_rd_data0 : std_logic_vector(XLEN-1 downto 0);
    signal reg_file_rd_data1 : std_logic_vector(XLEN-1 downto 0);

    -- csrs outputs. csrs arms and registers the interrupt itself, qualifying
    -- it with main_ctrl's id_valid; main_ctrl only reads back the wfi wake and
    -- the decode squash.
    signal csrs_int_pend    : std_logic;
    signal csrs_int_taken   : std_logic;
    signal csrs_exi_trap    : std_logic;
    signal csrs_tmi_trap    : std_logic;
    signal csrs_swi_trap    : std_logic;
    signal csrs_mepc_reg    : std_logic_vector(XLEN-1 downto 2);
    signal csrs_mtvec_reg   : std_logic_vector(XLEN-1 downto 2);
    signal csrs_csrrd_data  : std_logic_vector(XLEN-1 downto 0);
    signal csrs_pc          : std_logic_vector(XLEN-1 downto 0);
    signal csrs_cop_adr     : std_logic_vector(5      downto 0);
    signal csrs_cop_dat     : std_logic_vector(XLEN-1 downto 0);
    signal csrs_cop_we      : std_logic;

    -- main_ctrl's trap half, plus the pipeline advance a parked wfi holds
    signal main_ctrl_pipe_en     : std_logic;
    signal main_ctrl_instr_err   : std_logic;
    signal main_ctrl_fetch_fault : std_logic;
    signal main_ctrl_ecall       : std_logic;
    signal main_ctrl_ebreak      : std_logic;
    signal main_ctrl_mret        : std_logic;
    signal main_ctrl_wfi         : std_logic;
    signal main_ctrl_id_valid    : std_logic;
    signal main_ctrl_retire      : std_logic;

begin

    id_stage_main_ctrl: main_ctrl port map (
        clk_i          => clk_i,
        reset_i        => reset_i,
        imrd_fault_i   => fault_i,
        instr_i        => instr_i,
        valid_i        => valid_i,
        stale_i        => stale_i,
        flush_i        => flush_i,
        int_pend_i     => csrs_int_pend,
        int_taken_i    => csrs_int_taken,
        exc_taken_i    => exc_taken_i,
        ready_i        => ready_i,
        pipe_en_o      => main_ctrl_pipe_en,
        id_valid_o     => main_ctrl_id_valid,
        instr_err_o    => main_ctrl_instr_err,
        fetch_fault_o  => main_ctrl_fetch_fault,
        ecall_o        => main_ctrl_ecall,
        ebreak_o       => main_ctrl_ebreak,
        mret_o         => main_ctrl_mret,
        wfi_o          => main_ctrl_wfi,
        retire_o       => main_ctrl_retire,
        func3_o        => main_ctrl_func3,
        branch_op_o    => main_ctrl_branch_op,
        alu_op_o       => main_ctrl_alu_op,
        dmls_ctrl_o    => main_ctrl_dmls_ctrl,
        imm_o          => main_ctrl_imm,
        opd_src_sel_o  => main_ctrl_opd_src_sel,
        opd_pass_o     => main_ctrl_opd_pass,
        regwr_en_o     => main_ctrl_regwr_en,
        regwr_sel_o    => main_ctrl_regwr_sel,
        regwr_addr_o   => main_ctrl_regwr_addr,
        csrwr_en_o     => main_ctrl_csrwr_en,
        csrs_addr_o    => main_ctrl_csrs_addr
    );

    id_stage_reg_file: reg_file generic map (
        SIZE => REG_FILE_SIZE
    ) port map (
        clk_i      => clk_i,
        reset_i    => reset_i,
        we_i       => regwr_en_i,
        wr_sel_i   => main_ctrl_regwr_sel,
        wr_addr_i  => main_ctrl_regwr_addr,
        wr_data0_i => exec_res_i,
        wr_data1_i => dmld_data_i,
        wr_data2_i => pc_next_i,
        wr_data3_i => csrs_csrrd_data,
        rd_addr0_i => instr_i(19 downto 15),
        rd_addr1_i => instr_i(24 downto 20),
        re_i       => main_ctrl_pipe_en,
        rd_data0_o => reg_file_rd_data0,
        rd_data1_o => reg_file_rd_data1
    );

    id_stage_csrs: csrs generic map (
        MHART_ID => CSRS_MHART_ID
    ) port map (
        clk_i         => clk_i,
        reset_i       => reset_i,
        ex_irq_i      => ex_irq_i,
        sw_irq_i      => sw_irq_i,
        tm_irq_i      => tm_irq_i,
        mcause_exc_i  => mcause_exc_i,
        mtval_i       => mtval_i,
        mcause_int_i  => mcause_int_i,
        mepc_i        => mepc_i,
        mret_i        => main_ctrl_mret,
        exc_taken_i   => exc_taken_i,
        id_valid_i    => main_ctrl_id_valid,
        wr_en_i       => csrwr_en_i,
        wr_addr_i     => main_ctrl_csrs_addr,
        rw_addr_i     => instr_i(31 downto 20),
        wr_data_i     => csrwr_data_i,
        pipe_en_i     => main_ctrl_pipe_en,
        pc_i          => pc_i,
        cycle_i       => cycle_i,
        timer_i       => timer_i,
        instret_i     => instret_i,
        cop_dat_i     => cop_dat_i,
        cop_adr_o     => csrs_cop_adr,
        cop_dat_o     => csrs_cop_dat,
        cop_we_o      => csrs_cop_we,
        int_pend_o    => csrs_int_pend,
        int_taken_o   => csrs_int_taken,
        exi_trap_o    => csrs_exi_trap,
        tmi_trap_o    => csrs_tmi_trap,
        swi_trap_o    => csrs_swi_trap,
        mepc_reg_o    => csrs_mepc_reg,
        mtvec_reg_o   => csrs_mtvec_reg,
        csrrd_data_o  => csrs_csrrd_data,
        pc_o          => csrs_pc
    );

    ready_o       <= main_ctrl_pipe_en;
    func3_o       <= main_ctrl_func3;
    branch_op_o   <= main_ctrl_branch_op;
    alu_op_o      <= main_ctrl_alu_op;
    dmls_ctrl_o   <= main_ctrl_dmls_ctrl;
    mepc_reg_o    <= csrs_mepc_reg;
    mtvec_reg_o   <= csrs_mtvec_reg;

    instr_err_o   <= main_ctrl_instr_err;
    fetch_fault_o <= main_ctrl_fetch_fault;
    ecall_o       <= main_ctrl_ecall;
    ebreak_o      <= main_ctrl_ebreak;
    mret_o        <= main_ctrl_mret;
    wfi_o         <= main_ctrl_wfi;
    exi_trap_o    <= csrs_exi_trap;
    tmi_trap_o    <= csrs_tmi_trap;
    swi_trap_o    <= csrs_swi_trap;
    regwr_en_o    <= main_ctrl_regwr_en;
    csrwr_en_o    <= main_ctrl_csrwr_en;
    rd_data0_o    <= reg_file_rd_data0;
    rd_data1_o    <= reg_file_rd_data1;
    csrrd_data_o  <= csrs_csrrd_data;
    imm_o         <= main_ctrl_imm;
    opd_src_sel_o <= main_ctrl_opd_src_sel;
    opd_pass_o    <= main_ctrl_opd_pass;
    pc_full_o     <= csrs_pc;
    retire_o      <= main_ctrl_retire;

    cop_adr_o     <= csrs_cop_adr;
    cop_dat_o     <= csrs_cop_dat;
    cop_we_o      <= csrs_cop_we;

end architecture rtl;
