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
        func3_o       : out std_logic_vector(2  downto 0);
        branch_op_o   : out std_logic_vector(1  downto 0);
        alu_op_o      : out std_logic_vector(5  downto 0);
        dmls_ctrl_o   : out std_logic_vector(1  downto 0);
        cop_dat_i     : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o     : out std_logic_vector(5 downto 0);
        cop_dat_o     : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o      : out std_logic;
        trap_taken_o  : out std_logic;
        trap_target_o : out std_logic_vector(XLEN-1 downto 0);
        rd_data0_o    : out std_logic_vector(XLEN-1 downto 0);
        rd_data1_o    : out std_logic_vector(XLEN-1 downto 0);
        csrrd_data_o  : out std_logic_vector(XLEN-1 downto 0);
        imm_o         : out std_logic_vector(XLEN-1 downto 0);
        csrwr_data_i  : in  std_logic_vector(XLEN-1 downto 0);
        opd0_src_sel_o : out std_logic;
        opd1_src_sel_o : out std_logic;
        opd0_pass_o    : out std_logic;
        opd1_pass_o    : out std_logic;
        pc_o          : out std_logic_vector(XLEN-1 downto 2);
        wfi_o         : out std_logic;
        int_taken_o   : out std_logic;
        pc_full_o     : out std_logic_vector(XLEN-1 downto 0)
    );
end entity id_stage;

architecture rtl of id_stage is

    signal instr_err : std_logic;
    signal ecall     : std_logic;
    signal ebreak    : std_logic;
    signal mret      : std_logic;
    signal wfi       : std_logic;
    signal csrs_addr : std_logic_vector(11 downto 0);

    signal imm   : std_logic_vector(XLEN-1 downto 0);
    signal func3 : std_logic_vector(2  downto 0);

    signal regwr_en    : std_logic;
    signal regwr_addr  : std_logic_vector(4  downto 0);
    signal regrd_addr0 : std_logic_vector(4  downto 0);
    signal regrd_addr1 : std_logic_vector(4  downto 0);
    signal regwr_sel   : std_logic_vector(1  downto 0);
    signal regrd_data0 : std_logic_vector(XLEN-1 downto 0);
    signal regrd_data1 : std_logic_vector(XLEN-1 downto 0);

    signal csrwr_en     : std_logic;
    signal csrrd_data : std_logic_vector(XLEN-1 downto 0);

    signal opd0_src_sel : std_logic;
    signal opd1_src_sel : std_logic;
    signal opd0_pass    : std_logic;
    signal opd1_pass    : std_logic;

    signal pc_full     : std_logic_vector(XLEN-1 downto 0);
    signal next_pc_full : std_logic_vector(XLEN-1 downto 0);

    signal exc_taken   : std_logic;
    signal int_taken   : std_logic;
    signal exi_taken   : std_logic;
    signal tmi_taken   : std_logic;
    signal swi_taken   : std_logic;
    signal mie_meie    : std_logic;
    signal mie_mtie    : std_logic;
    signal mie_msie    : std_logic;
    signal mstatus_mie : std_logic;
    signal mip_meip    : std_logic;
    signal mip_mtip    : std_logic;
    signal mip_msip    : std_logic;
    signal mepc        : std_logic_vector(XLEN-1 downto 2);
    signal mtvec_base  : std_logic_vector(XLEN-1 downto 2);

begin

    pc_full     <= pc_i & b"00";
    next_pc_full <= next_pc_i & b"00";

    pc_o    <= pc_i;
    pc_full_o <= pc_full;

    id_stage_main_ctrl: main_ctrl port map (
        imrd_malgn_i   => imrd_malgn_i,
        imrd_fault_i   => fault_i,
        dmld_malgn_i   => dmld_malgn_i,
        dmld_fault_i   => dmld_fault_i,
        dmst_malgn_i   => dmst_malgn_i,
        dmst_fault_i   => dmst_fault_i,
        instr_i        => instr_i,
        valid_i        => valid_i,
        mip_meip_i     => mip_meip,
        mip_msip_i     => mip_msip,
        mip_mtip_i     => mip_mtip,
        mie_meie_i     => mie_meie,
        mie_mtie_i     => mie_mtie,
        mie_msie_i     => mie_msie,
        mstatus_mie_i  => mstatus_mie,
        mepc_i         => mepc,
        mtvec_base_i   => mtvec_base,
        instr_err_o    => instr_err,
        ecall_o        => ecall,
        ebreak_o       => ebreak,
        mret_o         => mret,
        wfi_o          => wfi,
        csrwr_en_o     => csrwr_en,
        regwr_en_o     => regwr_en,
        regwr_sel_o    => regwr_sel,
        dmls_ctrl_o    => dmls_ctrl_o,
        branch_op_o    => branch_op_o,
        opd0_src_sel_o => opd0_src_sel,
        opd1_src_sel_o => opd1_src_sel,
        opd0_pass_o    => opd0_pass,
        opd1_pass_o    => opd1_pass,
        alu_op_o       => alu_op_o,
        imm_o          => imm,
        func3_o        => func3,
        regwr_addr_o   => regwr_addr,
        regrd_addr0_o  => regrd_addr0,
        regrd_addr1_o  => regrd_addr1,
        csrs_addr_o    => csrs_addr,
        exc_taken_o    => exc_taken,
        int_taken_o    => int_taken,
        exi_taken_o    => exi_taken,
        tmi_taken_o    => tmi_taken,
        swi_taken_o    => swi_taken,
        trap_taken_o   => trap_taken_o,
        trap_target_o  => trap_target_o
    );

    id_stage_reg_file: reg_file generic map (
        SIZE => REG_FILE_SIZE
    ) port map (
        clk_i      => clk_i,
        we_i       => regwr_en,
        wr_sel_i   => regwr_sel,
        wr_addr_i  => regwr_addr,
        wr_data0_i => exec_res_i,
        wr_data1_i => dmld_data_i,
        wr_data2_i => next_pc_full,
        wr_data3_i => csrrd_data,
        rd_addr0_i => regrd_addr0,
        rd_addr1_i => regrd_addr1,
        rd_data0_o => regrd_data0,
        rd_data1_o => regrd_data1
    );


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
        instr_err_i  => instr_err,
        dmld_malgn_i => dmld_malgn_i,
        dmld_fault_i => dmld_fault_i,
        dmst_malgn_i => dmst_malgn_i,
        dmst_fault_i => dmst_fault_i,
        ecall_i      => ecall,
        ebreak_i     => ebreak,
        mret_i       => mret,
        wfi_i        => wfi,
        exc_taken_i  => exc_taken,
        int_taken_i  => int_taken,
        exi_taken_i  => exi_taken,
        tmi_taken_i  => tmi_taken,
        swi_taken_i  => swi_taken,
        wr_en_i      => csrwr_en,
        rw_addr_i    => csrs_addr,
        wr_data_i    => csrwr_data_i,
        exec_res_i   => exec_res_i,
        pc_i         => pc_full,
        next_pc_i    => next_pc_full,
        cycle_i      => cycle_i,
        timer_i      => timer_i,
        instret_i    => instret_i,
        cop_dat_i    => cop_dat_i,
        cop_adr_o    => cop_adr_o,
        cop_dat_o    => cop_dat_o,
        cop_we_o     => cop_we_o,
        mie_meie_o   => mie_meie,
        mie_mtie_o   => mie_mtie,
        mie_msie_o   => mie_msie,
        mstatus_mie_o=> mstatus_mie,
        mip_meip_o   => mip_meip,
        mip_mtip_o   => mip_mtip,
        mip_msip_o   => mip_msip,
        mepc_o       => mepc,
        mtvec_base_o => mtvec_base,
        rd_data_o    => csrrd_data
    );

    func3_o        <= func3;
    rd_data0_o     <= regrd_data0;
    rd_data1_o     <= regrd_data1;
    csrrd_data_o   <= csrrd_data;
    opd0_src_sel_o <= opd0_src_sel;
    opd1_src_sel_o <= opd1_src_sel;
    opd0_pass_o    <= opd0_pass;
    opd1_pass_o    <= opd1_pass;
    imm_o          <= imm;

    wfi_o       <= wfi;
    int_taken_o <= int_taken;

end architecture rtl;
