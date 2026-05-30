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
        func7_o       : out std_logic_vector(6  downto 0);
        imm_o         : out std_logic_vector(XLEN-1 downto 0);
        jmp_o         : out std_logic;
        br_en_o       : out std_logic;
        opd0_src_sel_o: out std_logic;
        opd1_src_sel_o: out std_logic;
        opd0_pass_o   : out std_logic;
        opd1_pass_o   : out std_logic;
        ftype_o       : out std_logic;
        op_en_o       : out std_logic;
        dmls_mode_o   : out std_logic;
        dmls_en_o     : out std_logic;
        cop_dat_i     : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o     : out std_logic_vector(5 downto 0);
        cop_dat_o     : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o      : out std_logic;
        pcwr_en_o     : out std_logic;
        trap_taken_o  : out std_logic;
        trap_target_o : out std_logic_vector(XLEN-1 downto 0);
        rd_data0_o    : out std_logic_vector(XLEN-1 downto 0);
        rd_data1_o    : out std_logic_vector(XLEN-1 downto 0);
        csrwr_data_i  : in  std_logic_vector(XLEN-1 downto 0);
        csrrd_data_o  : out std_logic_vector(XLEN-1 downto 0)
    );
end entity id_stage;

architecture rtl of id_stage is

    signal instr_err : std_logic;
    signal csrs_addr : std_logic_vector(11 downto 0);

    signal imm_value   : std_logic_vector(XLEN-1 downto 0);
    signal func3_value : std_logic_vector(2  downto 0);

    signal regwr_en    : std_logic;
    signal regwr_addr  : std_logic_vector(4  downto 0);
    signal regrd_addr0 : std_logic_vector(4  downto 0);
    signal regrd_addr1 : std_logic_vector(4  downto 0);
    signal regwr_sel   : std_logic_vector(1  downto 0);
    signal regrd_data0 : std_logic_vector(XLEN-1 downto 0);
    signal regrd_data1 : std_logic_vector(XLEN-1 downto 0);

    signal csrwr_en     : std_logic;
    signal csrrd_data_s : std_logic_vector(XLEN-1 downto 0);

begin

    func3_value <= instr_i(14 downto 12);
    func7_o     <= instr_i(31 downto 25);
    regwr_addr  <= instr_i(11 downto  7);
    regrd_addr0 <= instr_i(19 downto 15);
    regrd_addr1 <= instr_i(24 downto 20);
    csrs_addr   <= instr_i(31 downto 20);

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
        opd0_src_sel_o => opd0_src_sel_o,
        opd1_src_sel_o => opd1_src_sel_o,
        opd0_pass_o  => opd0_pass_o,
        opd1_pass_o  => opd1_pass_o,
        ftype_o      => ftype_o,
        op_en_o      => op_en_o,
        imm_o        => imm_value
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
        wr_data3_i => csrrd_data_s,
        rd_addr0_i => regrd_addr0,
        rd_addr1_i => regrd_addr1,
        rd_data0_o => regrd_data0,
        rd_data1_o => regrd_data1
    );

    id_stage_csrs: csrs generic map (
        MHART_ID => CSRS_MHART_ID
    ) port map (
        clk         => clk_i,
        reset       => reset_i,
        ex_irq      => ex_irq_i,
        sw_irq      => sw_irq_i,
        tm_irq      => tm_irq_i,
        imrd_malgn  => imrd_malgn_i,
        imrd_fault  => imrd_fault_i,
        instr_err   => instr_err,
        dmld_malgn  => dmld_malgn_i,
        dmld_fault  => dmld_fault_i,
        dmst_malgn  => dmst_malgn_i,
        dmst_fault  => dmst_fault_i,
        wr_en       => csrwr_en,
        wr_mode     => func3_value,
        rw_addr     => csrs_addr,
        wr_data     => csrwr_data_i,
        exec_res    => exec_res_i,
        pc          => pc_i,
        next_pc     => next_pc_i,
        cycle       => cycle_i,
        timer       => timer_i,
        instret     => instret_i,
        cop_dat_i   => cop_dat_i,
        cop_adr_o   => cop_adr_o,
        cop_dat_o   => cop_dat_o,
        cop_we_o    => cop_we_o,
        pcwr_en     => pcwr_en_o,
        trap_taken  => trap_taken_o,
        trap_target => trap_target_o,
        rd_data     => csrrd_data_s
    );

    imm_o      <= imm_value;
    func3_o    <= func3_value;
    rd_data0_o <= regrd_data0;
    rd_data1_o <= regrd_data1;
    csrrd_data_o <= csrrd_data_s;

end architecture rtl;
