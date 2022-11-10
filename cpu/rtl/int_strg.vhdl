----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: internal storage
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity int_strg is
    generic (
        REG_FILE_SIZE : natural := 32;
        CSRS_MHART_ID : std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        ex_irq     : in  std_logic;
        sw_irq     : in  std_logic;
        tm_irq     : in  std_logic;
        instr_err  : in  std_logic;
        imrd_malgn : in  std_logic;
        imrd_fault : in  std_logic;
        dmld_malgn : in  std_logic;
        dmld_fault : in  std_logic;
        dmst_malgn : in  std_logic;
        dmst_fault : in  std_logic;
        cycle      : in  std_logic_vector(63 downto 0);
        timer      : in  std_logic_vector(63 downto 0);
        instret    : in  std_logic_vector(63 downto 0);
        exec_res   : in  std_logic_vector(31 downto 0);
        dmld_data  : in  std_logic_vector(31 downto 0);
        pc         : in  std_logic_vector(31 downto 0);
        next_pc    : in  std_logic_vector(31 downto 0);
        imm        : in  std_logic_vector(31 downto 0);
        func3      : in  std_logic_vector(2  downto 0);
        regs_addr  : in  std_logic_vector(14 downto 0);
        csrs_addr  : in  std_logic_vector(11 downto 0);
        istg_ctrl  : in  std_logic_vector(3  downto 0);
        pcwr_en    : out std_logic;
        trap_taken : out std_logic;
        trap_target: out std_logic_vector(31 downto 0);
        rd_data0   : out std_logic_vector(31 downto 0);
        rd_data1   : out std_logic_vector(31 downto 0)
    );
end entity int_strg;

architecture int_strg_arch of int_strg is
    
    signal regs_we       : std_logic;
    signal regs_wr_addr  : std_logic_vector(4  downto 0);
    signal regs_wr_data  : std_logic_vector(31 downto 0);
    signal regs_rd_addr0 : std_logic_vector(4  downto 0);
    signal regs_rd_addr1 : std_logic_vector(4  downto 0);
    signal regs_wr_sel   : std_logic_vector(1  downto 0);
    signal regs_rd_data0 : std_logic_vector(31 downto 0);
    signal regs_rd_data1 : std_logic_vector(31 downto 0);
    signal csrs_we       : std_logic;
    signal csrs_rd_data  : std_logic_vector(31 downto 0);

begin
    
    regs_wr_addr  <= regs_addr(4  downto  0);
    regs_rd_addr0 <= regs_addr(9  downto  5);
    regs_rd_addr1 <= regs_addr(14 downto 10);

    regs_we     <= istg_ctrl(0) and not (imrd_malgn or dmld_malgn or dmld_fault);
    regs_wr_sel <= istg_ctrl(2 downto 1);
    csrs_we     <= istg_ctrl(3);

    regs_wr_data_mux: process(regs_wr_sel, exec_res, dmld_data, next_pc, csrs_rd_data)
    begin
        case regs_wr_sel is
            when b"00"  => regs_wr_data <= exec_res;
            when b"01"  => regs_wr_data <= dmld_data;
            when b"10"  => regs_wr_data <= next_pc;
            when b"11"  => regs_wr_data <= csrs_rd_data;
            when others => null;
        end case;
    end process regs_wr_data_mux;
    
    istg_reg_file: reg_file generic map (
        SIZE => REG_FILE_SIZE
    ) port map (
        clk      => clk,
        we       => regs_we,
        wr_addr  => regs_wr_addr,
        wr_data  => regs_wr_data,
        rd_addr0 => regs_rd_addr0,
        rd_addr1 => regs_rd_addr1,
        rd_data0 => regs_rd_data0, 
        rd_data1 => regs_rd_data1
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
        wr_en       => csrs_we,
        wr_mode     => func3,
        rd_wr_addr  => csrs_addr,
        exec_res    => exec_res,
        pc          => pc,
        wr_reg_data => regs_rd_data0,
        wr_imm_data => imm,
        cycle       => cycle,
        timer       => timer,
        instret     => instret,
        pcwr_en     => pcwr_en,
        trap_taken  => trap_taken,
        trap_target => trap_target,
        rd_data     => csrs_rd_data
    );

    rd_data0 <= regs_rd_data0;
    rd_data1 <= regs_rd_data1;

end architecture int_strg_arch;