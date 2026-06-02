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
        imrd_fault_i  : in  std_logic;
        dmld_malgn_i  : in  std_logic;
        dmld_fault_i  : in  std_logic;
        dmst_malgn_i  : in  std_logic;
        dmst_fault_i  : in  std_logic;
        cycle_i       : in  std_logic_vector(63 downto 0);
        timer_i       : in  std_logic_vector(63 downto 0);
        instret_i     : in  std_logic_vector(63 downto 0);
        exec_res_i    : in  std_logic_vector(XLEN-1 downto 0);
        dmld_data_i   : in  std_logic_vector(XLEN-1 downto 0);
        pc_i          : in  std_logic_vector(XLEN-1 downto 0);
        next_pc_i     : in  std_logic_vector(XLEN-1 downto 0);
        instr_i       : in  std_logic_vector(XLEN-1 downto 0);
        flush_i       : in  std_logic;
        func3_o       : out std_logic_vector(2  downto 0);
        jmp_o         : out std_logic;
        br_en_o       : out std_logic;
        alu_op_o      : out std_logic_vector(5  downto 0);
        dmls_mode_o   : out std_logic;
        dmls_en_o     : out std_logic;
        opd0_o        : out std_logic_vector(XLEN-1 downto 0);
        opd1_o        : out std_logic_vector(XLEN-1 downto 0);
        cop_dat_i     : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o     : out std_logic_vector(5 downto 0);
        cop_dat_o     : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o      : out std_logic;
        pcwr_en_o     : out std_logic;
        trap_taken_o  : out std_logic;
        trap_target_o : out std_logic_vector(XLEN-1 downto 0);
        rd_data0_o    : out std_logic_vector(XLEN-1 downto 0);
        rd_data1_o    : out std_logic_vector(XLEN-1 downto 0)
    );
end entity id_stage;

architecture rtl of id_stage is

    signal instr_err : std_logic;
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
    signal csrwr_data : std_logic_vector(XLEN-1 downto 0);

    signal opd0_src_sel : std_logic;
    signal opd1_src_sel : std_logic;
    signal opd0_pass    : std_logic;
    signal opd1_pass    : std_logic;
    signal opd0           : std_logic_vector(XLEN-1 downto 0);
    signal opd1           : std_logic_vector(XLEN-1 downto 0);
    signal gtd_opd0       : std_logic_vector(XLEN-1 downto 0);
    signal gtd_opd1       : std_logic_vector(XLEN-1 downto 0);

begin

    id_stage_main_ctrl: main_ctrl port map (
        imrd_malgn_i => imrd_malgn_i,
        dmld_malgn_i => dmld_malgn_i,
        dmld_fault_i => dmld_fault_i,
        flush_i      => flush_i,
        instr_i      => instr_i,
        instr_err_o  => instr_err,
        csrwr_en_o   => csrwr_en,
        regwr_en_o   => regwr_en,
        regwr_sel_o  => regwr_sel,
        dmls_mode_o  => dmls_mode_o,
        dmls_en_o    => dmls_en_o,
        jmp_o        => jmp_o,
        br_en_o      => br_en_o,
        opd0_src_sel_o => opd0_src_sel,
        opd1_src_sel_o => opd1_src_sel,
        opd0_pass_o  => opd0_pass,
        opd1_pass_o  => opd1_pass,
        alu_op_o     => alu_op_o,
        imm_o        => imm,
        func3_o       => func3,
        regwr_addr_o  => regwr_addr,
        regrd_addr0_o => regrd_addr0,
        regrd_addr1_o => regrd_addr1,
        csrs_addr_o   => csrs_addr
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
        wr_data2_i => next_pc_i,
        wr_data3_i => csrrd_data,
        rd_addr0_i => regrd_addr0,
        rd_addr1_i => regrd_addr1,
        rd_data0_o => regrd_data0,
        rd_data1_o => regrd_data1
    );

    id_stage_csrs_logic: csrs_logic port map (
        csrwr_mode_i => func3,
        csrrd_data_i => csrrd_data,
        regwr_data_i => regrd_data0,
        immwr_data_i => imm,
        csrwr_data_o => csrwr_data
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
        imrd_fault_i => imrd_fault_i,
        instr_err_i  => instr_err,
        dmld_malgn_i => dmld_malgn_i,
        dmld_fault_i => dmld_fault_i,
        dmst_malgn_i => dmst_malgn_i,
        dmst_fault_i => dmst_fault_i,
        wr_en_i      => csrwr_en,
        wr_mode_i    => func3,
        rw_addr_i    => csrs_addr,
        wr_data_i    => csrwr_data,
        exec_res_i   => exec_res_i,
        pc_i         => pc_i,
        next_pc_i    => next_pc_i,
        cycle_i      => cycle_i,
        timer_i      => timer_i,
        instret_i    => instret_i,
        cop_dat_i    => cop_dat_i,
        cop_adr_o    => cop_adr_o,
        cop_dat_o    => cop_dat_o,
        cop_we_o     => cop_we_o,
        pcwr_en_o    => pcwr_en_o,
        trap_taken_o => trap_taken_o,
        trap_target_o=> trap_target_o,
        rd_data_o    => csrrd_data
    );

    func3_o    <= func3;
    rd_data0_o <= regrd_data0;
    rd_data1_o <= regrd_data1;

    opd0     <= pc_i  when opd0_src_sel = '1' else regrd_data0;
    opd1     <= imm when opd1_src_sel = '1' else regrd_data1;
    gtd_opd0 <= opd0 and (XLEN-1 downto 0 => opd0_pass);
    gtd_opd1 <= opd1 and (XLEN-1 downto 0 => opd1_pass);

    opd0_o <= gtd_opd0;
    opd1_o <= gtd_opd1;

end architecture rtl;
