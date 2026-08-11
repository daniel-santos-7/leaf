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
        -- Fully resolved trap redirect for ex_block. mepc/mtvec never leave
        -- this stage: csrs owns both, so the 2:1 mux between them belongs
        -- here rather than 60 bits of CSR content crossing into EX.
        trap_taken_o  : out std_logic;
        trap_target_o : out std_logic_vector(XLEN-1 downto 0);
        rd_data0_o    : out std_logic_vector(XLEN-1 downto 0);
        rd_data1_o    : out std_logic_vector(XLEN-1 downto 0);
        imm_o         : out std_logic_vector(XLEN-1 downto 0);
        opd_src_sel_o  : out std_logic_vector(1  downto 0);
        opd_pass_o     : out std_logic_vector(1  downto 0);
        pc_full_o     : out std_logic_vector(XLEN-1 downto 0);
        retire_o      : out std_logic
    );
end entity id_stage;

architecture rtl of id_stage is

    -- Trap causes, all registered in main_ctrl: csrs commits the trap at EX
    -- time, so these arrive together with exc_taken and with the PC they
    -- belong to.
    signal main_ctrl_instr_err   : std_logic;
    signal main_ctrl_ecall       : std_logic;
    signal main_ctrl_ebreak      : std_logic;
    signal main_ctrl_wfi         : std_logic;
    signal main_ctrl_fetch_fault : std_logic;

    -- The five EX faults ORed together, and that OR plus the registered cause
    -- set. Single copies: ex_block hands over the five individually because
    -- csrs discriminates between them for mcause and mtval, and everything
    -- built on top of them is consumed here.
    signal exc_fault      : std_logic;
    signal csrs_exc_taken : std_logic;

    signal pc_full     : std_logic_vector(XLEN-1 downto 0);

    -- csrs owns the interrupt decision (all of mie/mip/mstatus live there);
    -- main_ctrl only consumes it, to squash the decode and to wake a wfi.
    signal csrs_int_taken : std_logic;

    -- Registered outputs from reg_file/csrs (ID -> EX). None of these has a
    -- same-cycle combinational twin reaching id_stage, so plain
    -- driver-prefixed names are enough. csrs also owns the PC pipeline
    -- register: pc_full below is its combinational (same-cycle) input.
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
    signal main_ctrl_opd_src_sel : std_logic_vector(1 downto 0);
    signal main_ctrl_opd_pass    : std_logic_vector(1 downto 0);
    signal main_ctrl_regwr_en    : std_logic;
    signal main_ctrl_regwr_sel   : std_logic_vector(1 downto 0);
    signal main_ctrl_regwr_addr  : std_logic_vector(4 downto 0);
    signal main_ctrl_csrwr_en    : std_logic;
    signal main_ctrl_retire      : std_logic;
    -- main_ctrl_mret feeds both ex_block (redirect target) and csrs (mstatus
    -- unstacking); a single registered copy serves both now that csrs commits
    -- at EX time.
    signal main_ctrl_csrs_addr   : std_logic_vector(11 downto 0);
    signal main_ctrl_exc_taken   : std_logic;
    signal main_ctrl_mret        : std_logic;

    signal csrs_wr_data : std_logic_vector(XLEN-1 downto 0);

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
        int_taken_i    => csrs_int_taken,
        ready_i        => ready_i,
        flush_i        => flush_i,
        ready_o        => main_ctrl_ready,
        -- registered (pipeline) outputs
        instr_err_o   => main_ctrl_instr_err,
        ecall_o       => main_ctrl_ecall,
        ebreak_o      => main_ctrl_ebreak,
        wfi_o         => main_ctrl_wfi,
        fetch_fault_o => main_ctrl_fetch_fault,
        func3_o       => main_ctrl_func3,
        branch_op_o   => main_ctrl_branch_op,
        alu_op_o      => main_ctrl_alu_op,
        dmls_ctrl_o   => main_ctrl_dmls_ctrl,
        imm_o         => main_ctrl_imm,
        opd_src_sel_o => main_ctrl_opd_src_sel,
        opd_pass_o    => main_ctrl_opd_pass,
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
        -- rs1/rs2, straight off the instruction: main_ctrl relayed these
        -- unmodified, so the slice is taken where it is consumed.
        rd_addr0_i => instr_i(19 downto 15),
        rd_addr1_i => instr_i(24 downto 20),
        re_i       => main_ctrl_ready,
        rd_data0_o => reg_file_rd0,
        rd_data1_o => reg_file_rd1
    );


    exc_fault      <= imrd_malgn_i or dmld_malgn_i or dmld_fault_i or
                      dmst_malgn_i or dmst_fault_i;

    -- Both terms are EX-aligned: main_ctrl_exc_taken is the registered cause
    -- set, exc_fault the live EX fault. They commit in the same cycle.
    csrs_exc_taken <= main_ctrl_exc_taken or exc_fault;

    -- EX-time faults only, matching the stage main_ctrl_regwr_en/csrwr_en come
    -- from. A fetch fault is inhibited one stage earlier: main_ctrl's squash
    -- clears both enables on imrd_fault_i and the zero rides the ID/EX register,
    -- so it lands on the instruction that actually faulted. Repeating that term
    -- live here would instead block the older instruction sitting in EX.
    rf_we_int <= main_ctrl_regwr_en and not exc_fault;
    csr_we_int <= main_ctrl_csrwr_en and not exc_fault;

    id_stage_csrs: csrs generic map (
        MHART_ID => CSRS_MHART_ID
    ) port map (
        clk_i        => clk_i,
        reset_i      => reset_i,
        ex_irq_i     => ex_irq_i,
        sw_irq_i     => sw_irq_i,
        tm_irq_i     => tm_irq_i,
        imrd_malgn_i => imrd_malgn_i,
        imrd_fault_i => main_ctrl_fetch_fault,
        instr_err_i  => main_ctrl_instr_err,
        dmld_malgn_i => dmld_malgn_i,
        dmld_fault_i => dmld_fault_i,
        dmst_malgn_i => dmst_malgn_i,
        dmst_fault_i => dmst_fault_i,
        ecall_i      => main_ctrl_ecall,
        ebreak_i     => main_ctrl_ebreak,
        mret_i       => main_ctrl_mret,
        wfi_i        => main_ctrl_wfi,
        exc_taken_i  => csrs_exc_taken,
        wr_en_i      => csr_we_int,
        wr_addr_i    => main_ctrl_csrs_addr,
        rw_addr_i    => instr_i(31 downto 20),
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
        int_taken_o  => csrs_int_taken,
        mepc_o       => csrs_mepc,
        mtvec_base_o => csrs_mtvec_base,
        csrrd_data_o => csrs_csrrd_data,
        pc_o         => csrs_pc
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
    -- An mret redirects the fetch too, but commits nothing in csrs beyond the
    -- mstatus unstacking, so it joins only here and not in csrs_exc_taken.
    trap_taken_o  <= csrs_exc_taken or main_ctrl_mret;
    trap_target_o <= csrs_mepc & b"00" when main_ctrl_mret = '1' else
                     csrs_mtvec_base & b"00";
    func3_o       <= main_ctrl_func3;
    branch_op_o   <= main_ctrl_branch_op;
    alu_op_o      <= main_ctrl_alu_op;
    dmls_ctrl_o   <= main_ctrl_dmls_ctrl;
    rd_data0_o    <= reg_file_rd0;
    rd_data1_o    <= reg_file_rd1;
    imm_o         <= main_ctrl_imm;
    opd_src_sel_o <= main_ctrl_opd_src_sel;
    opd_pass_o    <= main_ctrl_opd_pass;
    pc_full_o     <= csrs_pc;
    ready_o       <= main_ctrl_ready;

    -- minstret: count at the commit point, one pulse per instruction as it
    -- leaves EX. A fault detected in EX cancels the retirement.
    --
    -- The qualifier is main_ctrl_ready, not ready_i: the two are the same signal
    -- except while a wfi is parked, and there ready_i still reads '1' (EX is
    -- idle) while retire_reg keeps holding the bit of the instruction ahead of
    -- the wfi -- which would then be counted once per parked cycle. Covered by
    -- verif/tests/wfi_timer.
    retire_o      <= main_ctrl_retire and main_ctrl_ready and not exc_fault;

end architecture rtl;
