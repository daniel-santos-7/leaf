----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: instruction decode stage
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

entity id_stage is
    generic (
        REG_FILE_SIZE : natural := 32;
        CSRS_MHART_ID : std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        ex_irq      : in  std_logic;
        sw_irq      : in  std_logic;
        tm_irq      : in  std_logic;
        imrd_malgn  : in  std_logic;
        imrd_fault  : in  std_logic;
        dmld_malgn  : in  std_logic;
        dmld_fault  : in  std_logic;
        dmst_malgn  : in  std_logic;
        dmst_fault  : in  std_logic;
        cycle       : in  std_logic_vector(63 downto 0);
        timer       : in  std_logic_vector(63 downto 0);
        instret     : in  std_logic_vector(63 downto 0);
        exec_res    : in  std_logic_vector(31 downto 0);
        dmld_data   : in  std_logic_vector(31 downto 0);
        pc          : in  std_logic_vector(31 downto 0);
        next_pc     : in  std_logic_vector(31 downto 0);
        instr       : in  std_logic_vector(31 downto 0);
        flush       : in  std_logic;
        func3       : out std_logic_vector(2  downto 0);
        func7       : out std_logic_vector(6  downto 0);
        imm         : out std_logic_vector(31 downto 0);
        exec_ctrl   : out std_logic_vector(7  downto 0);
        dmls_ctrl   : out std_logic_vector(1  downto 0);
        pcwr_en     : out std_logic;
        trap_taken  : out std_logic;
        trap_target : out std_logic_vector(31 downto 0);
        rd_data0    : out std_logic_vector(31 downto 0);
        rd_data1    : out std_logic_vector(31 downto 0)
    );
end entity id_stage;

architecture rtl of id_stage is

    signal instr_err : std_logic;
    signal csrs_addr : std_logic_vector(11 downto 0);
    signal istg_ctrl : std_logic_vector(3  downto 0);

    signal imm_value   : std_logic_vector(31 downto 0);
    signal func3_value : std_logic_vector(2  downto 0);

    signal regwr_en    : std_logic;
    signal regwr_addr  : std_logic_vector(4  downto 0);
    signal regwr_data  : std_logic_vector(31 downto 0);
    signal regrd_addr0 : std_logic_vector(4  downto 0);
    signal regrd_addr1 : std_logic_vector(4  downto 0);
    signal regwr_sel   : std_logic_vector(1  downto 0);
    signal regrd_data0 : std_logic_vector(31 downto 0);
    signal regrd_data1 : std_logic_vector(31 downto 0);

    signal csrwr_en   : std_logic;
    signal csrrd_data : std_logic_vector(31 downto 0);
    signal csrwr_data : std_logic_vector(31 downto 0);

begin

    stage_main_ctrl: main_ctrl port map (
        flush     => flush,
        instr     => instr,
        instr_err => instr_err,
        dmls_ctrl => dmls_ctrl,
        istg_ctrl => istg_ctrl,
        exec_ctrl => exec_ctrl,
        imm       => imm_value
    );

    func3_value <= instr(14 downto 12);
    func7       <= instr(31 downto 25);
    regwr_addr  <= instr(11 downto  7);
    regrd_addr0 <= instr(19 downto 15);
    regrd_addr1 <= instr(24 downto 20);
    csrs_addr   <= instr(31 downto 20);

    regwr_en  <= istg_ctrl(0) and not (imrd_malgn or dmld_malgn or dmld_fault);
    regwr_sel <= istg_ctrl(2 downto 1);
    csrwr_en  <= istg_ctrl(3);

    regwr_data_mux: process(regwr_sel, exec_res, dmld_data, next_pc, csrrd_data)
    begin
        case regwr_sel is
            when b"00" => regwr_data <= exec_res;
            when b"01" => regwr_data <= dmld_data;
            when b"10" => regwr_data <= next_pc;
            when b"11" => regwr_data <= csrrd_data;
            when others => null;
        end case;
    end process regwr_data_mux;

    istg_reg_file: reg_file generic map (
        SIZE => REG_FILE_SIZE
    ) port map (
        clk      => clk,
        we       => regwr_en,
        wr_addr  => regwr_addr,
        wr_data  => regwr_data,
        rd_addr0 => regrd_addr0,
        rd_addr1 => regrd_addr1,
        rd_data0 => regrd_data0,
        rd_data1 => regrd_data1
    );

    istg_csrs_logic: csrs_logic port map (
        csrwr_mode => func3_value,
        csrrd_data => csrrd_data,
        regwr_data => regrd_data0,
        immwr_data => imm_value,
        csrwr_data => csrwr_data
    );

    istg_csrs: csrs generic map (
        MHART_ID => CSRS_MHART_ID
    ) port map (
        clk         => clk,
        reset       => reset,
        ex_irq      => ex_irq,
        sw_irq      => sw_irq,
        tm_irq      => tm_irq,
        imrd_malgn  => imrd_malgn,
        imrd_fault  => imrd_fault,
        instr_err   => instr_err,
        dmld_malgn  => dmld_malgn,
        dmld_fault  => dmst_fault,
        dmst_malgn  => dmst_malgn,
        dmst_fault  => dmst_fault,
        wr_en       => csrwr_en,
        wr_mode     => func3_value,
        rw_addr     => csrs_addr,
        wr_data     => csrwr_data,
        exec_res    => exec_res,
        pc          => pc,
        next_pc     => next_pc,
        cycle       => cycle,
        timer       => timer,
        instret     => instret,
        pcwr_en     => pcwr_en,
        trap_taken  => trap_taken,
        trap_target => trap_target,
        rd_data     => csrrd_data
    );

    imm <= imm_value;
    func3 <= func3_value;
    rd_data0 <= regrd_data0;
    rd_data1 <= regrd_data1;

end architecture rtl;
