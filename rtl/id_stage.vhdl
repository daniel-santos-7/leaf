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
        dmld_data_i   : in  std_logic_vector(XLEN-1 downto 0);
        pc_i          : in  std_logic_vector(XLEN-1 downto 2);
        next_pc_i     : in  std_logic_vector(XLEN-1 downto 2);
        instr_i       : in  std_logic_vector(XLEN-1 downto 0);
        fault_i       : in  std_logic;
        valid_i       : in  std_logic;
        stale_i       : in  std_logic;
        cop_dat_i     : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o     : out std_logic_vector(5 downto 0);
        cop_dat_o     : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o      : out std_logic;
        csr_wr_data_i : in  std_logic_vector(XLEN-1 downto 0);
        flush_i       : in  std_logic;
        ready_i       : in  std_logic;
        exc_fault_i   : in  std_logic;
        rf_we_i       : in  std_logic;
        csr_we_i      : in  std_logic;
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
        csrrd_data_o  : out std_logic_vector(XLEN-1 downto 0);
        imm_o         : out std_logic_vector(XLEN-1 downto 0);
        opd0_src_sel_o : out std_logic;
        opd1_src_sel_o : out std_logic;
        opd0_pass_o    : out std_logic;
        opd1_pass_o    : out std_logic;
        pc_full_o     : out std_logic_vector(XLEN-1 downto 0);
        ex_regwr_en_o : out std_logic;
        ex_csrwr_en_o : out std_logic
    );
end entity id_stage;

architecture rtl of id_stage is

    signal main_ctrl_instr_err : std_logic;
    signal main_ctrl_ecall     : std_logic;
    signal main_ctrl_ebreak    : std_logic;
    signal main_ctrl_mret      : std_logic;
    signal main_ctrl_wfi       : std_logic;
    signal csrs_exc_taken : std_logic;

    signal main_ctrl_regrd_addr0 : std_logic_vector(4  downto 0);
    signal main_ctrl_regrd_addr1 : std_logic_vector(4  downto 0);

    signal pc_full     : std_logic_vector(XLEN-1 downto 0);
    signal next_pc_full : std_logic_vector(XLEN-1 downto 0);

    signal main_ctrl_exc_taken : std_logic;
    signal main_ctrl_int_taken : std_logic;
    signal main_ctrl_exi_taken : std_logic;
    signal main_ctrl_tmi_taken : std_logic;
    signal main_ctrl_swi_taken : std_logic;
    signal csrs_mie_meie    : std_logic;
    signal csrs_mie_mtie    : std_logic;
    signal csrs_mie_msie    : std_logic;
    signal csrs_mstatus_mie : std_logic;
    signal csrs_mip_meip    : std_logic;
    signal csrs_mip_mtip    : std_logic;
    signal csrs_mip_msip    : std_logic;
    signal csrs_mepc        : std_logic_vector(XLEN-1 downto 2);
    signal csrs_mtvec_base  : std_logic_vector(XLEN-1 downto 2);

    -- Combinatorial decode outputs (to pipeline register)
    signal main_ctrl_func3       : std_logic_vector(2  downto 0);
    signal main_ctrl_branch_op   : std_logic_vector(1  downto 0);
    signal main_ctrl_alu_op      : std_logic_vector(5  downto 0);
    signal main_ctrl_dmls_ctrl   : std_logic_vector(1  downto 0);
    signal reg_file_rd0         : std_logic_vector(XLEN-1 downto 0);
    signal reg_file_rd1         : std_logic_vector(XLEN-1 downto 0);
    signal csrs_csrrd_data  : std_logic_vector(XLEN-1 downto 0);
    signal main_ctrl_imm         : std_logic_vector(XLEN-1 downto 0);
    signal main_ctrl_opd0_src_sel : std_logic;
    signal main_ctrl_opd1_src_sel : std_logic;
    signal main_ctrl_opd0_pass   : std_logic;
    signal main_ctrl_opd1_pass   : std_logic;
    signal main_ctrl_regwr_en    : std_logic;
    signal main_ctrl_regwr_sel   : std_logic_vector(1 downto 0);
    signal main_ctrl_regwr_addr  : std_logic_vector(4 downto 0);
    signal main_ctrl_csrwr_en    : std_logic;
    signal main_ctrl_csrs_addr   : std_logic_vector(11 downto 0);

    -- Pipeline register outputs (ID -> EX)
    signal ex_func3_reg       : std_logic_vector(2  downto 0);
    signal ex_branch_op_reg   : std_logic_vector(1  downto 0);
    signal ex_alu_op_reg      : std_logic_vector(5  downto 0);
    signal ex_dmls_ctrl_reg   : std_logic_vector(1  downto 0);
    signal ex_exc_taken_reg   : std_logic;
    signal ex_mret_reg        : std_logic;
    signal ex_mepc_reg        : std_logic_vector(XLEN-1 downto 2);
    signal ex_mtvec_base_reg  : std_logic_vector(XLEN-1 downto 2);
    signal ex_rd0_reg         : std_logic_vector(XLEN-1 downto 0);
    signal ex_rd1_reg         : std_logic_vector(XLEN-1 downto 0);
    signal ex_csrrd_data_reg  : std_logic_vector(XLEN-1 downto 0);
    signal ex_imm_reg         : std_logic_vector(XLEN-1 downto 0);
    signal ex_opd0_src_sel_reg : std_logic;
    signal ex_opd1_src_sel_reg : std_logic;
    signal ex_opd0_pass_reg   : std_logic;
    signal ex_opd1_pass_reg   : std_logic;
    signal ex_pc_full_reg     : std_logic_vector(XLEN-1 downto 0);
    signal ex_regwr_en_reg    : std_logic;
    signal ex_regwr_sel_reg   : std_logic_vector(1 downto 0);
    signal ex_regwr_addr_reg  : std_logic_vector(4 downto 0);
    signal ex_csrwr_en_reg    : std_logic;
    signal ex_csrs_addr_reg   : std_logic_vector(11 downto 0);
    signal ex_next_pc_full_reg : std_logic_vector(XLEN-1 downto 0);

    signal main_ctrl_ready : std_logic;

    signal csrs_cop_adr : std_logic_vector(5 downto 0);
    signal csrs_cop_dat : std_logic_vector(XLEN-1 downto 0);
    signal csrs_cop_we  : std_logic;

begin

    pc_full     <= pc_i & b"00";
    next_pc_full <= next_pc_i & b"00";

    id_stage_main_ctrl: main_ctrl port map (
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
        mepc_i         => csrs_mepc,
        mtvec_base_i   => csrs_mtvec_base,
        instr_err_o    => main_ctrl_instr_err,
        ecall_o        => main_ctrl_ecall,
        ebreak_o       => main_ctrl_ebreak,
        mret_o         => main_ctrl_mret,
        wfi_o          => main_ctrl_wfi,
        csrwr_en_o     => main_ctrl_csrwr_en,
        regwr_en_o     => main_ctrl_regwr_en,
        regwr_sel_o    => main_ctrl_regwr_sel,
        dmls_ctrl_o    => main_ctrl_dmls_ctrl,
        branch_op_o    => main_ctrl_branch_op,
        opd0_src_sel_o => main_ctrl_opd0_src_sel,
        opd1_src_sel_o => main_ctrl_opd1_src_sel,
        opd0_pass_o    => main_ctrl_opd0_pass,
        opd1_pass_o    => main_ctrl_opd1_pass,
        alu_op_o       => main_ctrl_alu_op,
        imm_o          => main_ctrl_imm,
        func3_o        => main_ctrl_func3,
        regwr_addr_o   => main_ctrl_regwr_addr,
        regrd_addr0_o  => main_ctrl_regrd_addr0,
        regrd_addr1_o  => main_ctrl_regrd_addr1,
        csrs_addr_o    => main_ctrl_csrs_addr,
        ready_i        => ready_i,
        flush_i        => flush_i,
        ready_o        => main_ctrl_ready,
        exc_taken_o    => main_ctrl_exc_taken,
        int_taken_o    => main_ctrl_int_taken,
        exi_taken_o    => main_ctrl_exi_taken,
        tmi_taken_o    => main_ctrl_tmi_taken,
        swi_taken_o    => main_ctrl_swi_taken
    );

    id_stage_reg_file: reg_file generic map (
        SIZE => REG_FILE_SIZE
    ) port map (
        clk_i      => clk_i,
        we_i       => rf_we_i,
        wr_sel_i   => ex_regwr_sel_reg,
        wr_addr_i  => ex_regwr_addr_reg,
        wr_data0_i => exec_res_i,
        wr_data1_i => dmld_data_i,
        wr_data2_i => ex_next_pc_full_reg,
        wr_data3_i => ex_csrrd_data_reg,
        rd_addr0_i => main_ctrl_regrd_addr0,
        rd_addr1_i => main_ctrl_regrd_addr1,
        rd_data0_o => reg_file_rd0,
        rd_data1_o => reg_file_rd1
    );


    csrs_exc_taken <= main_ctrl_exc_taken or exc_fault_i;

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
        mret_i       => main_ctrl_mret,
        wfi_i        => main_ctrl_wfi,
        exc_taken_i  => csrs_exc_taken,
        int_taken_i  => main_ctrl_int_taken,
        exi_taken_i  => main_ctrl_exi_taken,
        tmi_taken_i  => main_ctrl_tmi_taken,
        swi_taken_i  => main_ctrl_swi_taken,
        wr_en_i      => csr_we_i,
        wr_addr_i    => ex_csrs_addr_reg,
        rw_addr_i    => main_ctrl_csrs_addr,
        wr_data_i    => csr_wr_data_i,
        exec_res_i   => exec_res_i,
        pc_i         => pc_full,
        fault_pc_i   => ex_pc_full_reg,
        next_pc_i    => next_pc_full,
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
        mepc_o       => csrs_mepc,
        mtvec_base_o => csrs_mtvec_base,
        rd_data_o    => csrs_csrrd_data
    );

    pipeline_reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                ex_func3_reg        <= (others => '0');
                ex_branch_op_reg    <= BR_NONE;
                ex_alu_op_reg       <= (others => '0');
                ex_dmls_ctrl_reg    <= DMLS_IDLE;
                ex_exc_taken_reg    <= '0';
                ex_mret_reg         <= '0';
                ex_mepc_reg         <= (others => '0');
                ex_mtvec_base_reg   <= (others => '0');
                ex_rd0_reg          <= (others => '0');
                ex_rd1_reg          <= (others => '0');
                ex_csrrd_data_reg   <= (others => '0');
                ex_imm_reg          <= (others => '0');
                ex_opd0_src_sel_reg <= '0';
                ex_opd1_src_sel_reg <= '0';
                ex_opd0_pass_reg    <= '0';
                ex_opd1_pass_reg    <= '0';
                ex_pc_full_reg      <= (others => '0');
                ex_regwr_en_reg     <= '0';
                ex_regwr_sel_reg    <= (others => '0');
                ex_regwr_addr_reg   <= (others => '0');
                ex_csrwr_en_reg     <= '0';
                ex_csrs_addr_reg    <= (others => '0');
                ex_next_pc_full_reg <= (others => '0');
            elsif main_ctrl_ready = '1' then
                ex_func3_reg        <= main_ctrl_func3;
                ex_alu_op_reg       <= main_ctrl_alu_op;
                ex_exc_taken_reg    <= main_ctrl_exc_taken;
                ex_mret_reg         <= main_ctrl_mret;
                ex_mepc_reg         <= csrs_mepc;
                ex_mtvec_base_reg   <= csrs_mtvec_base;
                ex_rd0_reg          <= reg_file_rd0;
                ex_rd1_reg          <= reg_file_rd1;
                ex_csrrd_data_reg   <= csrs_csrrd_data;
                ex_imm_reg          <= main_ctrl_imm;
                ex_opd0_src_sel_reg <= main_ctrl_opd0_src_sel;
                ex_opd1_src_sel_reg <= main_ctrl_opd1_src_sel;
                ex_opd0_pass_reg    <= main_ctrl_opd0_pass;
                ex_opd1_pass_reg    <= main_ctrl_opd1_pass;
                ex_pc_full_reg      <= pc_full;
                ex_regwr_sel_reg    <= main_ctrl_regwr_sel;
                ex_regwr_addr_reg   <= main_ctrl_regwr_addr;
                ex_csrs_addr_reg    <= main_ctrl_csrs_addr;
                ex_next_pc_full_reg <= next_pc_full;
                ex_branch_op_reg    <= main_ctrl_branch_op;
                ex_dmls_ctrl_reg    <= main_ctrl_dmls_ctrl;
                ex_regwr_en_reg     <= main_ctrl_regwr_en;
                ex_csrwr_en_reg     <= main_ctrl_csrwr_en;
            end if;
        end if;
    end process pipeline_reg;

    -- Output assignments at end
    cop_adr_o     <= csrs_cop_adr;
    cop_dat_o     <= csrs_cop_dat;
    cop_we_o      <= csrs_cop_we;
    exc_taken_o   <= ex_exc_taken_reg;
    mret_o        <= ex_mret_reg;
    mepc_o        <= ex_mepc_reg;
    mtvec_base_o  <= ex_mtvec_base_reg;
    func3_o       <= ex_func3_reg;
    branch_op_o   <= ex_branch_op_reg;
    alu_op_o      <= ex_alu_op_reg;
    dmls_ctrl_o   <= ex_dmls_ctrl_reg;
    rd_data0_o    <= ex_rd0_reg;
    rd_data1_o    <= ex_rd1_reg;
    csrrd_data_o  <= ex_csrrd_data_reg;
    imm_o         <= ex_imm_reg;
    opd0_src_sel_o <= ex_opd0_src_sel_reg;
    opd1_src_sel_o <= ex_opd1_src_sel_reg;
    opd0_pass_o   <= ex_opd0_pass_reg;
    opd1_pass_o   <= ex_opd1_pass_reg;
    pc_full_o     <= ex_pc_full_reg;
    ready_o       <= main_ctrl_ready;
    ex_regwr_en_o <= ex_regwr_en_reg;
    ex_csrwr_en_o <= ex_csrwr_en_reg;

end architecture rtl;
