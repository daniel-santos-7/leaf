----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: cpu core
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity core is
    generic (
        RESET_ADDR    : std_logic_vector(31 downto 0) := (others => '0');
        CSRS_MHART_ID : std_logic_vector(31 downto 0) := (others => '0');
        REG_FILE_SIZE : natural := 32
    );
    port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        ex_irq    : in  std_logic;
        sw_irq    : in  std_logic;
        tm_irq    : in  std_logic;
        imrd_err  : in  std_logic;
        dmrd_err  : in  std_logic;
        dmwr_err  : in  std_logic;
        imrd_data : in  std_logic_vector(31 downto 0);
        dmrd_data : in  std_logic_vector(31 downto 0);
        cycle     : in  std_logic_vector(63 downto 0);
        timer     : in  std_logic_vector(63 downto 0);
        instret   : in  std_logic_vector(63 downto 0);
        imrd_en   : out std_logic;
        dmrd_en   : out std_logic;
        dmwr_en   : out std_logic;
        dmwr_be   : out std_logic_vector(3  downto 0);
        imrd_addr : out std_logic_vector(31 downto 0);
        dmrw_addr : out std_logic_vector(31 downto 0);
        dmwr_data : out std_logic_vector(31 downto 0)
    );
end entity core;

architecture rtl of core is

    -- internal signals --

    signal pcwr_en    : std_logic;
    signal taken      : std_logic;
    signal target     : std_logic_vector(31 downto 0);
    signal imrd_fault : std_logic;
    signal flush      : std_logic;
    signal pc         : std_logic_vector(31 downto 0);
    signal next_pc    : std_logic_vector(31 downto 0);
    signal instr      : std_logic_vector(31 downto 0);

begin

    -- instruction fetch stage --

    core_if_stage: if_stage generic map (
        RESET_ADDR => RESET_ADDR
    ) port map (
        clk        => clk,
        reset      => reset,
        pcwr_en    => pcwr_en,
        imrd_err   => imrd_err,
        taken      => taken,
        target     => target,
        imrd_data  => imrd_data,
        imrd_en    => imrd_en,
        imrd_fault => imrd_fault,
        flush      => flush,
        imrd_addr  => imrd_addr,
        pc         => pc,
        next_pc    => next_pc,
        instr      => instr
    );

    -- instruction decode and execute stage --

    core_id_ex_stage: id_ex_stage generic map (
        REG_FILE_SIZE => REG_FILE_SIZE,
        CSRS_MHART_ID => CSRS_MHART_ID
    ) port map (
        clk        => clk,
        reset      => reset,
        ex_irq     => ex_irq,
        sw_irq     => sw_irq,
        tm_irq     => tm_irq,
        dmrd_err   => dmrd_err,
        dmwr_err   => dmwr_err,
        imrd_fault => imrd_fault,
        flush      => flush,
        instr      => instr,
        pc         => pc,
        next_pc    => next_pc,
        dmrd_data  => dmrd_data,
        cycle      => cycle,
        timer      => timer,
        instret    => instret,
        dmrd_en    => dmrd_en,
        dmwr_en    => dmwr_en,
        pcwr_en    => pcwr_en,
        taken      => taken,
        target     => target,
        dmwr_data  => dmwr_data,
        dmrw_addr  => dmrw_addr,
        dm_byte_en => dmwr_be
    );

end architecture rtl;
