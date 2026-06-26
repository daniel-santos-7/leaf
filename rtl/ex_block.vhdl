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
        clk_i         : in  std_logic;
        reset_i       : in  std_logic;
        trap_taken_i  : in  std_logic;
        trap_target_i : in  std_logic_vector(XLEN-1 downto 0);
        func3_i       : in  std_logic_vector(2  downto 0);
        reg0_i        : in  std_logic_vector(XLEN-1 downto 0);
        reg1_i        : in  std_logic_vector(XLEN-1 downto 0);
        pc_i          : in  std_logic_vector(XLEN-1 downto 0);
        opd0_src_sel_i : in  std_logic;
        opd1_src_sel_i : in  std_logic;
        opd0_pass_i    : in  std_logic;
        opd1_pass_i    : in  std_logic;
        jmp_i         : in  std_logic;
        br_en_i       : in  std_logic;
        alu_op_i      : in  std_logic_vector(5  downto 0);
        dmls_mode_i   : in  std_logic;
        dmls_en_i     : in  std_logic;
        data_dat_i   : in  std_logic_vector(XLEN-1 downto 0);
        data_ack_i   : in  std_logic;
        data_err_i   : in  std_logic;
        csrrd_data_i  : in  std_logic_vector(XLEN-1 downto 0);
        immwr_data_i  : in  std_logic_vector(XLEN-1 downto 0);
        csrwr_data_o  : out std_logic_vector(XLEN-1 downto 0);
        imrd_malgn_o  : out std_logic;
        dmld_malgn_o  : out std_logic;
        dmld_fault_o  : out std_logic;
        dmst_malgn_o  : out std_logic;
        dmst_fault_o  : out std_logic;
        data_cyc_o         : out std_logic;
        data_stb_o         : out std_logic;
        data_dat_o   : out std_logic_vector(XLEN-1 downto 0);
        data_adr_o   : out std_logic_vector(XLEN-1 downto 2);
        data_sel_o  : out std_logic_vector(3  downto 0);
        data_we_o   : out std_logic;
        dmls_ready_o  : out std_logic;
        dmld_data_o   : out std_logic_vector(XLEN-1 downto 0);
        taken_o  : out std_logic;
        target_o : out std_logic_vector(XLEN-1 downto 0);
        branch_o      : out std_logic;
        res_o         : out std_logic_vector(XLEN-1 downto 0);
        valid_i       : in  std_logic
    );
end entity ex_block;

architecture ex_block_arch of ex_block is

    signal alu_res  : std_logic_vector(XLEN-1 downto 0);
    signal branch   : std_logic;

    signal taken_int  : std_logic;
    signal target_int : std_logic_vector(XLEN-1 downto 0);

    signal dmls_ready : std_logic;

    signal dmls_cyc : std_logic;
    signal dmls_stb : std_logic;
    signal dmls_adr : std_logic_vector(XLEN-1 downto 2);
    signal dmls_dat : std_logic_vector(XLEN-1 downto 0);
    signal dmls_sel : std_logic_vector(3 downto 0);
    signal dmls_we  : std_logic;

    signal taken_reg  : std_logic;
    signal target_reg : std_logic_vector(XLEN-1 downto 0);

    signal opd0      : std_logic_vector(XLEN-1 downto 0);
    signal opd1      : std_logic_vector(XLEN-1 downto 0);
    signal gtd_opd0  : std_logic_vector(XLEN-1 downto 0);
    signal gtd_opd1  : std_logic_vector(XLEN-1 downto 0);
begin

    opd0 <= pc_i when opd0_src_sel_i = '1' else reg0_i;
    opd1 <= immwr_data_i when opd1_src_sel_i = '1' else reg1_i;
    gtd_opd0 <= opd0 and (XLEN-1 downto 0 => opd0_pass_i);
    gtd_opd1 <= opd1 and (XLEN-1 downto 0 => opd1_pass_i);

    exec_alu: alu port map (
        opd0_i => gtd_opd0,
        opd1_i => gtd_opd1,
        op_i   => alu_op_i,
        res_o  => alu_res
    );

    exec_br_detector: br_detector port map (
        reg0_i   => reg0_i,
        reg1_i   => reg1_i,
        mode_i   => func3_i,
        en_i     => br_en_i,
        branch_o => branch
    );

    imrd_malgn_o <= alu_res(1) and (branch or jmp_i);

    taken_int   <= branch or jmp_i or trap_taken_i;
    target_int  <= trap_target_i when trap_taken_i = '1' else alu_res(XLEN-1 downto 1) & b"0";
    res_o       <= alu_res;

    exec_branch_reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                taken_reg  <= '0';
                target_reg <= (others => '0');
            elsif taken_reg = '1' and valid_i = '1' then
                taken_reg  <= '0';
                target_reg <= (others => '0');
            elsif taken_reg = '0' then
                taken_reg  <= taken_int;
                target_reg <= target_int;
            end if;
        end if;
    end process exec_branch_reg;

    exec_dmls_block: dmls_block port map (
        clk_i         => clk_i,
        reset_i       => reset_i,
        dmls_mode_i   => dmls_mode_i,
        dmls_en_i     => dmls_en_i,
        dmls_dtype_i  => func3_i,
        dmst_data_i   => reg1_i,
        dmls_addr_i   => alu_res,
        data_dat_i    => data_dat_i,
        data_ack_i    => data_ack_i,
        data_err_i    => data_err_i,
        data_cyc_o    => dmls_cyc,
        data_stb_o    => dmls_stb,
        data_dat_o    => dmls_dat,
        data_adr_o    => dmls_adr,
        data_sel_o    => dmls_sel,
        data_we_o     => dmls_we,
        dmls_ready_o  => dmls_ready,
        dmld_malgn_o  => dmld_malgn_o,
        dmld_fault_o  => dmld_fault_o,
        dmst_malgn_o  => dmst_malgn_o,
        dmst_fault_o  => dmst_fault_o,
        dmld_data_o   => dmld_data_o
    );

    exec_csrs_logic: csrs_logic port map (
        csrwr_mode_i => func3_i,
        csrrd_data_i => csrrd_data_i,
        regwr_data_i => reg0_i,
        immwr_data_i => immwr_data_i,
        csrwr_data_o => csrwr_data_o
    );

    data_cyc_o <= dmls_cyc;
    data_stb_o <= dmls_stb;
    data_dat_o <= dmls_dat;
    data_adr_o <= dmls_adr;
    data_sel_o <= dmls_sel;
    data_we_o  <= dmls_we;
    dmls_ready_o <= dmls_ready;

    branch_o   <= branch;
    taken_o  <= taken_reg;
    target_o <= target_reg;

end architecture ex_block_arch;
