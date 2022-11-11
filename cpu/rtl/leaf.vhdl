----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: leaf cpu with wishbone interface
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity leaf is
    generic (
        RESET_ADDR    : std_logic_vector(31 downto 0) := (others => '0');
        CSRS_MHART_ID : std_logic_vector(31 downto 0) := (others => '0');
        REG_FILE_SIZE : natural := 32
    );
    port (
        clk_i  : in  std_logic;
        rst_i  : in  std_logic;
        ex_irq : in  std_logic;
        sw_irq : in  std_logic;
        tm_irq : in  std_logic;
        ack_i  : in  std_logic;
        err_i  : in  std_logic;
        dat_i  : in  std_logic_vector(31 downto 0);
        cyc_o  : out std_logic;
        stb_o  : out std_logic;
        we_o   : out std_logic;
        sel_o  : out std_logic_vector(3  downto 0);
        adr_o  : out std_logic_vector(31 downto 0);
        dat_o  : out std_logic_vector(31 downto 0)
    );
end entity leaf;

architecture rtl of leaf is
    
    -- internal clock and reset --
    
    signal clk_en : std_logic;
    signal clk    : std_logic;
    signal reset  : std_logic;

    -- instruction memory signals --
    
    signal imrd_en   : std_logic;
    signal imrd_addr : std_logic_vector(31 downto 0);
    signal imrd_data : std_logic_vector(31 downto 0);

    -- data memory signals --
    
    signal dmrd_en   : std_logic;
    signal dmwr_en   : std_logic;
    signal dmwr_be   : std_logic_vector(3  downto 0);
    signal dmrw_addr : std_logic_vector(31 downto 0);
    signal dmrd_data : std_logic_vector(31 downto 0);
    signal dmwr_data : std_logic_vector(31 downto 0);

    -- errors --

    signal imrd_err : std_logic;
    signal dmrd_err : std_logic;
    signal dmwr_err : std_logic;

    -- counters --
    
    signal cycle   : std_logic_vector(63 downto 0);
    signal timer   : std_logic_vector(63 downto 0);
    signal instret : std_logic_vector(63 downto 0);

begin

    -- leaf wishbone master interface --

    leaf_master: wb_ctrl port map (
        clk_i     => clk_i,
        rst_i     => rst_i,
        imrd_en   => imrd_en,
        dmrd_en   => dmrd_en,
        dmwr_en   => dmwr_en,
        ack_i     => ack_i,
        err_i     => err_i,
        dat_i     => dat_i,
        dmwr_be   => dmwr_be,
        imrd_addr => imrd_addr,
        dmrw_addr => dmrw_addr,
        dmwr_data => dmwr_data,
        cyc_o     => cyc_o,
        stb_o     => stb_o,
        we_o      => we_o,
        clk_en    => clk_en,
        reset     => reset,
        imrd_err  => imrd_err,
        dmrd_err  => dmrd_err,
        dmwr_err  => dmwr_err,
        sel_o     => sel_o,
        adr_o     => adr_o,
        dat_o     => dat_o,
        imrd_data => imrd_data,
        dmrd_data => dmrd_data
    );

    -- counters --

    leaf_counters: counters port map (
        clk     => clk_i, 
        reset   => rst_i,
        cycle   => cycle,
        timer   => timer,
        instret => instret
    );

    -- clock gating --

    leaf_clk_ctrl: clk_ctrl port map (
        clk_i  => clk_i,
        rst_i  => rst_i,
        clk_en => clk_en,
        clk    => clk
    );

    -- leaf core --
    
    leaf_core: core generic map (
        RESET_ADDR    => RESET_ADDR,
        CSRS_MHART_ID => CSRS_MHART_ID,
        REG_FILE_SIZE => REG_FILE_SIZE
    ) port map (
        clk       => clk, 
        reset     => reset,
        ex_irq    => ex_irq,
        sw_irq    => sw_irq,
        tm_irq    => tm_irq,
        imrd_err  => imrd_err,
        dmrd_err  => dmrd_err,
        dmwr_err  => dmwr_err,
        imrd_data => imrd_data,
        dmrd_data => dmrd_data,
        cycle     => cycle,
        timer     => timer,
        instret   => instret,
        imrd_en   => imrd_en,
        dmrd_en   => dmrd_en,
        dmwr_en   => dmwr_en,
        dmwr_be   => dmwr_be,
        imrd_addr => imrd_addr,
        dmrw_addr => dmrw_addr,
        dmwr_data => dmwr_data
    );
    
end architecture rtl;