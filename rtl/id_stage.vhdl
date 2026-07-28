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
        imrd_malgn_i  : in  std_logic;
        dmld_malgn_i  : in  std_logic;
        dmld_fault_i  : in  std_logic;
        dmst_malgn_i  : in  std_logic;
        dmst_fault_i  : in  std_logic;
        cycle_i       : in  std_logic_vector(63 downto 0);
        timer_i       : in  std_logic_vector(63 downto 0);
        instret_i     : in  std_logic_vector(63 downto 0);
        exec_res_i    : in  std_logic_vector(XLEN-1 downto 0);
        link_i        : in  std_logic_vector(XLEN-1 downto 0);
        dmld_data_i   : in  std_logic_vector(XLEN-1 downto 0);
        pc_i          : in  std_logic_vector(XLEN-1 downto 2);
        instr_i       : in  std_logic_vector(XLEN-1 downto 0);
        fault_i       : in  std_logic;
        valid_i       : in  std_logic;
        stale_i       : in  std_logic;
        cop_dat_i     : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o     : out std_logic_vector(5 downto 0);
        cop_dat_o     : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o      : out std_logic;
        flush_i       : in  std_logic;
        ready_i       : in  std_logic;
        ready_o       : out std_logic;
        func3_o       : out std_logic_vector(2  downto 0);
        branch_op_o   : out std_logic_vector(1  downto 0);
        alu_op_o      : out std_logic_vector(5  downto 0);
        dmls_ctrl_o   : out std_logic_vector(1  downto 0);
        exc_taken_o   : out std_logic;
        mret_o        : out std_logic;
        mepc_o        : out std_logic_vector(XLEN-1 downto 2);
        mtvec_base_o  : out std_logic_vector(XLEN-1 downto 2);
        rd_data0_o    : out std_logic_vector(XLEN-1 downto 0);
        rd_data1_o    : out std_logic_vector(XLEN-1 downto 0);
        imm_o         : out std_logic_vector(XLEN-1 downto 0);
        opd0_src_sel_o : out std_logic;
        opd1_src_sel_o : out std_logic;
        opd0_pass_o    : out std_logic;
        opd1_pass_o    : out std_logic;
        pc_full_o     : out std_logic_vector(XLEN-1 downto 0);
        retire_o      : out std_logic
    );
end entity id_stage;

architecture rtl of id_stage is

    signal main_ctrl_instr_err : std_logic;
    signal main_ctrl_ecall     : std_logic;
    signal main_ctrl_ebreak    : std_logic;
    signal main_ctrl_id_mret   : std_logic;
    signal main_ctrl_wfi       : std_logic;
    signal csrs_exc_taken : std_logic;

    signal main_ctrl_regrd_addr0 : std_logic_vector(4  downto 0);
    signal main_ctrl_regrd_addr1 : std_logic_vector(4  downto 0);

    signal pc_full     : std_logic_vector(XLEN-1 downto 0);

    signal main_ctrl_id_exc_taken : std_logic;
    signal main_ctrl_int_taken : std_logic;
    signal main_ctrl_exi_taken : std_logic;
    signal main_ctrl_tmi_taken : std_logic;
    signal main_ctrl_swi_taken : std_logic;
    signal csrs_mie_meie      : std_logic;
    signal csrs_mie_mtie      : std_logic;
    signal csrs_mie_msie      : std_logic;
    signal csrs_mstatus_mie   : std_logic;
    signal csrs_mip_meip      : std_logic;
    signal csrs_mip_mtip      : std_logic;
    signal csrs_mip_msip      : std_logic;
    signal csrs_id_mepc       : std_logic_vector(XLEN-1 downto 2);
    signal csrs_id_mtvec_base : std_logic_vector(XLEN-1 downto 2);

    -- Combinatorial decode outputs (to pipeline register)
    signal main_ctrl_id_csrs_addr   : std_logic_vector(11 downto 0);

    -- Registered outputs from reg_file/csrs (ID -> EX). csrs_mepc/
    -- csrs_mtvec_base (registered) each have a same-cycle combinational twin
    -- above (csrs_id_mepc/csrs_id_mtvec_base), hence the id_ prefix there
    -- instead; reg_file_rd0/rd1, csrs_csrrd_data and csrs_pc have no such
    -- twin reaching id_stage, so plain driver-prefixed names are enough.
    -- csrs also owns the PC pipeline register: pc_full below is its
    -- combinational (same-cycle) input.
    signal reg_file_rd0    : std_logic_vector(XLEN-1 downto 0);
    signal reg_file_rd1    : std_logic_vector(XLEN-1 downto 0);
    signal csrs_mepc       : std_logic_vector(XLEN-1 downto 2);
    signal csrs_mtvec_base : std_logic_vector(XLEN-1 downto 2);
    signal csrs_csrrd_data : std_logic_vector(XLEN-1 downto 0);
    signal csrs_pc         : std_logic_vector(XLEN-1 downto 0);

    signal main_ctrl_ready  : std_logic;

    -- main_ctrl registered (pipeline) outputs
    signal main_ctrl_func3       : std_logic_vector(2  downto 0);
    signal main_ctrl_branch_op   : std_logic_vector(1  downto 0);
    signal main_ctrl_alu_op      : std_logic_vector(5  downto 0);
    signal main_ctrl_dmls_ctrl   : std_logic_vector(1  downto 0);
    signal main_ctrl_imm         : std_logic_vector(XLEN-1 downto 0);
    signal main_ctrl_opd0_src_sel : std_logic;
    signal main_ctrl_opd1_src_sel : std_logic;
    signal main_ctrl_opd0_pass   : std_logic;
    signal main_ctrl_opd1_pass   : std_logic;
    signal main_ctrl_regwr_en    : std_logic;
    signal main_ctrl_regwr_sel   : std_logic_vector(1 downto 0);
    signal main_ctrl_regwr_addr  : std_logic_vector(4 downto 0);
    signal main_ctrl_csrwr_en    : std_logic;
    signal main_ctrl_retire      : std_logic;
    -- main_ctrl_csrs_addr/exc_taken/mret (registered, EX-facing) each have a
    -- same-cycle combinational twin above (main_ctrl_id_csrs_addr/id_exc_taken/
    -- id_mret), hence the id_ prefix on the combinational side instead.
    signal main_ctrl_csrs_addr   : std_logic_vector(11 downto 0);
    signal main_ctrl_exc_taken   : std_logic;
    signal main_ctrl_mret        : std_logic;

    signal csrs_wr_data : std_logic_vector(XLEN-1 downto 0);

    signal exc_fault_int : std_logic;
    signal exc_inhibit   : std_logic;
    signal rf_we_int     : std_logic;
    signal csr_we_int    : std_logic;

    signal csrs_cop_adr : std_logic_vector(5 downto 0);
    signal csrs_cop_dat : std_logic_vector(XLEN-1 downto 0);
    signal csrs_cop_we  : std_logic;

begin

    pc_full     <= pc_i & b"00";

    id_stage_main_ctrl: main_ctrl port map (
        clk_i          => clk_i,
        reset_i        => reset_i,
        imrd_fault_i   => fault_i,
        instr_i        => instr_i,
        valid_i        => valid_i,
        stale_i        => stale_i,
        mip_meip_i     => csrs_mip_meip,
        mip_msip_i     => csrs_mip_msip,
        mip_mtip_i     => csrs_mip_mtip,
        mie_meie_i     => csrs_mie_meie,
        mie_mtie_i     => csrs_mie_mtie,
        mie_msie_i     => csrs_mie_msie,
        mstatus_mie_i  => csrs_mstatus_mie,
        mepc_i         => csrs_id_mepc,
        mtvec_base_i   => csrs_id_mtvec_base,
        instr_err_o    => main_ctrl_instr_err,
        ecall_o        => main_ctrl_ecall,
        ebreak_o       => main_ctrl_ebreak,
        id_mret_o      => main_ctrl_id_mret,
        wfi_o          => main_ctrl_wfi,
        regrd_addr0_o  => main_ctrl_regrd_addr0,
        regrd_addr1_o  => main_ctrl_regrd_addr1,
        id_csrs_addr_o => main_ctrl_id_csrs_addr,
        ready_i        => ready_i,
        flush_i        => flush_i,
        ready_o        => main_ctrl_ready,
        id_exc_taken_o => main_ctrl_id_exc_taken,
        int_taken_o    => main_ctrl_int_taken,
        exi_taken_o    => main_ctrl_exi_taken,
        tmi_taken_o    => main_ctrl_tmi_taken,
        swi_taken_o    => main_ctrl_swi_taken,
        -- registered (pipeline) outputs
        func3_o       => main_ctrl_func3,
        branch_op_o   => main_ctrl_branch_op,
        alu_op_o      => main_ctrl_alu_op,
        dmls_ctrl_o   => main_ctrl_dmls_ctrl,
        imm_o         => main_ctrl_imm,
        opd0_src_sel_o => main_ctrl_opd0_src_sel,
        opd1_src_sel_o => main_ctrl_opd1_src_sel,
        opd0_pass_o   => main_ctrl_opd0_pass,
        opd1_pass_o   => main_ctrl_opd1_pass,
        regwr_en_o    => main_ctrl_regwr_en,
        regwr_sel_o   => main_ctrl_regwr_sel,
        regwr_addr_o  => main_ctrl_regwr_addr,
        csrwr_en_o    => main_ctrl_csrwr_en,
        retire_o      => main_ctrl_retire,
        csrs_addr_o    => main_ctrl_csrs_addr,
        exc_taken_o    => main_ctrl_exc_taken,
        mret_o         => main_ctrl_mret
    );

    id_stage_reg_file: reg_file generic map (
        SIZE => REG_FILE_SIZE
    ) port map (
        clk_i      => clk_i,
        reset_i    => reset_i,
        we_i       => rf_we_int,
        wr_sel_i   => main_ctrl_regwr_sel,
        wr_addr_i  => main_ctrl_regwr_addr,
        wr_data0_i => exec_res_i,
        wr_data1_i => dmld_data_i,
        wr_data2_i => link_i,
        wr_data3_i => csrs_csrrd_data,
        rd_addr0_i => main_ctrl_regrd_addr0,
        rd_addr1_i => main_ctrl_regrd_addr1,
        re_i       => main_ctrl_ready,
        rd_data0_o => reg_file_rd0,
        rd_data1_o => reg_file_rd1
    );


    exc_fault_int <= imrd_malgn_i or dmld_malgn_i or dmld_fault_i or dmst_malgn_i or dmst_fault_i;
    csrs_exc_taken <= main_ctrl_id_exc_taken or exc_fault_int;
    -- fault_i is combinational from the (possibly empty) instruction FIFO;
    -- only meaningful when this cycle actually holds a real, in-order
    -- instruction. Left ungated it can read 'U' and propagate through the
    -- OR (no zero-dominance the way main_ctrl's kill-gated AND has),
    -- silently disabling rf_we_int/csr_we_int.
    exc_inhibit <= exc_fault_int or (fault_i and valid_i and not stale_i and not flush_i);
    rf_we_int <= main_ctrl_regwr_en and not exc_inhibit;
    csr_we_int <= main_ctrl_csrwr_en and not exc_inhibit;

    id_stage_csrs: csrs generic map (
        MHART_ID => CSRS_MHART_ID
    ) port map (
        clk_i        => clk_i,
        reset_i      => reset_i,
        ex_irq_i     => ex_irq_i,
        sw_irq_i     => sw_irq_i,
        tm_irq_i     => tm_irq_i,
        imrd_malgn_i => imrd_malgn_i,
        imrd_fault_i => fault_i,
        instr_err_i  => main_ctrl_instr_err,
        dmld_malgn_i => dmld_malgn_i,
        dmld_fault_i => dmld_fault_i,
        dmst_malgn_i => dmst_malgn_i,
        dmst_fault_i => dmst_fault_i,
        ecall_i      => main_ctrl_ecall,
        ebreak_i     => main_ctrl_ebreak,
        mret_i       => main_ctrl_id_mret,
        wfi_i        => main_ctrl_wfi,
        exc_taken_i  => csrs_exc_taken,
        int_taken_i  => main_ctrl_int_taken,
        exi_taken_i  => main_ctrl_exi_taken,
        tmi_taken_i  => main_ctrl_tmi_taken,
        swi_taken_i  => main_ctrl_swi_taken,
        wr_en_i      => csr_we_int,
        wr_addr_i    => main_ctrl_csrs_addr,
        rw_addr_i    => main_ctrl_id_csrs_addr,
        wr_data_i    => csrs_wr_data,
        pipe_en_i    => main_ctrl_ready,
        exec_res_i   => exec_res_i,
        pc_i         => pc_full,
        cycle_i      => cycle_i,
        timer_i      => timer_i,
        instret_i    => instret_i,
        cop_dat_i    => cop_dat_i,
        cop_adr_o    => csrs_cop_adr,
        cop_dat_o    => csrs_cop_dat,
        cop_we_o     => csrs_cop_we,
        mie_meie_o   => csrs_mie_meie,
        mie_mtie_o   => csrs_mie_mtie,
        mie_msie_o   => csrs_mie_msie,
        mstatus_mie_o=> csrs_mstatus_mie,
        mip_meip_o   => csrs_mip_meip,
        mip_mtip_o   => csrs_mip_mtip,
        mip_msip_o   => csrs_mip_msip,
        id_mepc_o       => csrs_id_mepc,
        id_mtvec_base_o => csrs_id_mtvec_base,
        mepc_o          => csrs_mepc,
        mtvec_base_o    => csrs_mtvec_base,
        csrrd_data_o    => csrs_csrrd_data,
        pc_o            => csrs_pc
    );

    -- CSR write data mux (uses post-pipeline register values, same timing as before)
    id_stage_csrs_logic: csrs_logic port map (
        csrwr_mode_i => main_ctrl_func3,
        csrrd_data_i => csrs_csrrd_data,
        regwr_data_i => reg_file_rd0,
        immwr_data_i => main_ctrl_imm,
        csrwr_data_o => csrs_wr_data
    );

    -- Output assignments at end
    cop_adr_o     <= csrs_cop_adr;
    cop_dat_o     <= csrs_cop_dat;
    cop_we_o      <= csrs_cop_we;
    exc_taken_o   <= main_ctrl_exc_taken;
    mret_o        <= main_ctrl_mret;
    mepc_o        <= csrs_mepc;
    mtvec_base_o  <= csrs_mtvec_base;
    func3_o       <= main_ctrl_func3;
    branch_op_o   <= main_ctrl_branch_op;
    alu_op_o      <= main_ctrl_alu_op;
    dmls_ctrl_o   <= main_ctrl_dmls_ctrl;
    rd_data0_o    <= reg_file_rd0;
    rd_data1_o    <= reg_file_rd1;
    imm_o         <= main_ctrl_imm;
    opd0_src_sel_o <= main_ctrl_opd0_src_sel;
    opd1_src_sel_o <= main_ctrl_opd1_src_sel;
    opd0_pass_o   <= main_ctrl_opd0_pass;
    opd1_pass_o   <= main_ctrl_opd1_pass;
    pc_full_o     <= csrs_pc;
    ready_o       <= main_ctrl_ready;

    -- minstret: count at the commit point, one pulse per instruction as it
    -- leaves EX. A fault detected in EX cancels the retirement.
    retire_o      <= main_ctrl_retire and ready_i and not exc_fault_int;

end architecture rtl;
