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

        -- What the trap commits, resolved in ex_block's trap_ctrl over the
        -- faults raised there and the cause set exported below. Only the
        -- register writes stay here, next to csrs and the register file.
        exc_taken_i   : in  std_logic;
        mcause_exc_i  : in  std_logic_vector(4 downto 0);
        mtval_i       : in  std_logic_vector(XLEN-1 downto 0);
        mepc_i        : in  std_logic_vector(XLEN-1 downto 2);
        regwr_en_i    : in  std_logic;
        csrwr_en_i    : in  std_logic;

        exec_res_i    : in  std_logic_vector(XLEN-1 downto 0);
        pc_next_i     : in  std_logic_vector(XLEN-1 downto 0);
        dmld_data_i   : in  std_logic_vector(XLEN-1 downto 0);
        -- The csr write data, muxed by funct3 out in ex_block off csrrd_data_o
        -- below. Only the register write itself stays here, next to csrs.
        csrwr_data_i  : in  std_logic_vector(XLEN-1 downto 0);

        flush_i       : in  std_logic;
        ready_i       : in  std_logic;
        ready_o       : out std_logic;

        func3_o       : out std_logic_vector(2  downto 0);
        branch_op_o   : out std_logic_vector(1  downto 0);
        alu_op_o      : out std_logic_vector(5  downto 0);
        dmls_ctrl_o   : out std_logic_vector(1  downto 0);
        -- The trap redirect target, resolved against mepc/mtvec in csrs. Its
        -- taken side is decided in ex_block, out of the cause set below.
        trap_target_o : out std_logic_vector(XLEN-1 downto 0);

        -- The cause set, decoded and registered in main_ctrl, and the
        -- interrupts csrs arms. trap_ctrl ranks them in ex_block, against the
        -- faults that are raised there.
        instr_err_o   : out std_logic;
        fetch_fault_o : out std_logic;
        ebreak_o      : out std_logic;
        mret_o        : out std_logic;
        wfi_o         : out std_logic;
        exc_cause_o   : out std_logic;
        exi_taken_o   : out std_logic;
        tmi_taken_o   : out std_logic;
        swi_taken_o   : out std_logic;
        -- main_ctrl's write enables, registered there and still ungated: the
        -- EX faults that gate them are raised in ex_block, so they come back
        -- as regwr_en_i/csrwr_en_i above.
        regwr_en_o    : out std_logic;
        csrwr_en_o    : out std_logic;
        rd_data0_o    : out std_logic_vector(XLEN-1 downto 0);
        rd_data1_o    : out std_logic_vector(XLEN-1 downto 0);
        csrrd_data_o  : out std_logic_vector(XLEN-1 downto 0);
        imm_o         : out std_logic_vector(XLEN-1 downto 0);
        opd_src_sel_o : out std_logic_vector(1  downto 0);
        opd_pass_o    : out std_logic_vector(1  downto 0);
        pc_full_o     : out std_logic_vector(XLEN-1 downto 0);
        -- The retire bit before the EX faults annul it; ex_block closes it.
        retire_o      : out std_logic;

        cop_dat_i     : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o     : out std_logic_vector(5      downto 0);
        cop_dat_o     : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o      : out std_logic
    );
end entity id_stage;

architecture rtl of id_stage is

    -- The ID slot holds a real instruction: not empty, not wrong-path, not
    -- flushed. main_ctrl squashes its decode with it, qualifies the trap decode
    -- with it and counts retirements by it.
    signal id_valid : std_logic;

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

    -- Registered outputs from reg_file/csrs (ID -> EX). csrs also owns the PC
    -- pipeline register, and widens the word address to a byte address.
    signal reg_file_rd_data0 : std_logic_vector(XLEN-1 downto 0);
    signal reg_file_rd_data1 : std_logic_vector(XLEN-1 downto 0);

    -- The three interrupt causes, already masked by mstatus.MIE in csrs, which
    -- owns mie/mip/mstatus, plus their OR. The OR stays here, for main_ctrl:
    -- it squashes the decode, takes the trap and wakes a parked wfi. trap_ctrl,
    -- over in ex_block, ranks the three apart to name the cause, so only the
    -- three leave.
    signal csrs_exi_taken   : std_logic;
    signal csrs_tmi_taken   : std_logic;
    signal csrs_swi_taken   : std_logic;
    signal csrs_int_taken   : std_logic;
    signal csrs_trap_target : std_logic_vector(XLEN-1 downto 0);
    signal csrs_csrrd_data  : std_logic_vector(XLEN-1 downto 0);
    signal csrs_pc          : std_logic_vector(XLEN-1 downto 0);
    signal csrs_cop_adr     : std_logic_vector(5      downto 0);
    signal csrs_cop_dat     : std_logic_vector(XLEN-1 downto 0);
    signal csrs_cop_we      : std_logic;

    -- The ID half of the trap unit, decoded and registered in main_ctrl beside
    -- the rest of the decode: trap_ctrl ranks the set in ex_block against the
    -- faults raised there. main_ctrl also owns the pipeline advance, since a
    -- parked wfi is an ID-time decision.
    signal main_ctrl_pipe_en     : std_logic;
    signal main_ctrl_instr_err   : std_logic;
    signal main_ctrl_fetch_fault : std_logic;
    signal main_ctrl_ebreak      : std_logic;
    signal main_ctrl_mret        : std_logic;
    signal main_ctrl_wfi         : std_logic;
    signal main_ctrl_exc_cause   : std_logic;
    signal main_ctrl_retire      : std_logic;

begin

    id_valid <= valid_i and not stale_i and not flush_i;

    id_stage_main_ctrl: main_ctrl port map (
        clk_i          => clk_i,
        reset_i        => reset_i,
        imrd_fault_i   => fault_i,
        instr_i        => instr_i,
        id_valid_i     => id_valid,
        int_taken_i    => csrs_int_taken,
        ready_i        => ready_i,
        pipe_en_o      => main_ctrl_pipe_en,
        instr_err_o    => main_ctrl_instr_err,
        fetch_fault_o  => main_ctrl_fetch_fault,
        ebreak_o       => main_ctrl_ebreak,
        mret_o         => main_ctrl_mret,
        wfi_o          => main_ctrl_wfi,
        exc_cause_o    => main_ctrl_exc_cause,
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
        clk_i        => clk_i,
        reset_i      => reset_i,
        ex_irq_i     => ex_irq_i,
        sw_irq_i     => sw_irq_i,
        tm_irq_i     => tm_irq_i,
        mcause_exc_i => mcause_exc_i,
        mtval_i      => mtval_i,
        mepc_i       => mepc_i,
        mret_i       => main_ctrl_mret,
        exc_taken_i  => exc_taken_i,
        wr_en_i      => csrwr_en_i,
        wr_addr_i    => main_ctrl_csrs_addr,
        rw_addr_i    => instr_i(31 downto 20),
        wr_data_i    => csrwr_data_i,
        pipe_en_i    => main_ctrl_pipe_en,
        pc_i         => pc_i,
        cycle_i      => cycle_i,
        timer_i      => timer_i,
        instret_i    => instret_i,
        cop_dat_i    => cop_dat_i,
        cop_adr_o    => csrs_cop_adr,
        cop_dat_o    => csrs_cop_dat,
        cop_we_o     => csrs_cop_we,
        exi_taken_o   => csrs_exi_taken,
        tmi_taken_o   => csrs_tmi_taken,
        swi_taken_o   => csrs_swi_taken,
        int_taken_o   => csrs_int_taken,
        trap_target_o => csrs_trap_target,
        csrrd_data_o => csrs_csrrd_data,
        pc_o         => csrs_pc
    );

    ready_o       <= main_ctrl_pipe_en;
    func3_o       <= main_ctrl_func3;
    branch_op_o   <= main_ctrl_branch_op;
    alu_op_o      <= main_ctrl_alu_op;
    dmls_ctrl_o   <= main_ctrl_dmls_ctrl;
    trap_target_o <= csrs_trap_target;

    instr_err_o   <= main_ctrl_instr_err;
    fetch_fault_o <= main_ctrl_fetch_fault;
    ebreak_o      <= main_ctrl_ebreak;
    mret_o        <= main_ctrl_mret;
    wfi_o         <= main_ctrl_wfi;
    exc_cause_o   <= main_ctrl_exc_cause;
    exi_taken_o   <= csrs_exi_taken;
    tmi_taken_o   <= csrs_tmi_taken;
    swi_taken_o   <= csrs_swi_taken;
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
