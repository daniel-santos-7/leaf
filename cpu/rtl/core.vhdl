----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
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
        clk        : in  std_logic; 
        reset      : in  std_logic;
        ex_irq     : in  std_logic;
        sw_irq     : in  std_logic;
        tm_irq     : in  std_logic;
        imrd_err   : in  std_logic;
        dmrd_err   : in  std_logic;
        dmwr_err   : in  std_logic;
        imem_data  : in  std_logic_vector(31 downto 0);
        dmrd_data  : in  std_logic_vector(31 downto 0);
        cycle      : in  std_logic_vector(63 downto 0);
        timer      : in  std_logic_vector(63 downto 0);
        instret    : in  std_logic_vector(63 downto 0);
        dmrd_en    : out std_logic;
        dmwr_en    : out std_logic;
        imem_addr  : out std_logic_vector(31 downto 0);
        dmwr_data  : out std_logic_vector(31 downto 0);
        dmrw_addr  : out std_logic_vector(31 downto 0);
        dm_byte_en : out std_logic_vector(3  downto 0)
    );
end entity core;

architecture core_arch of core is

    signal taken       : std_logic;
    signal target      : std_logic_vector(31 downto 0);
    signal imrd_fault  : std_logic;
    signal flush       : std_logic;
    signal pc          : std_logic_vector(31 downto 0);
    signal next_pc     : std_logic_vector(31 downto 0);
    signal instr       : std_logic_vector(31 downto 0);
    
    signal imrd_fault_reg : std_logic;
    signal flush_reg      : std_logic;
    signal pc_reg         : std_logic_vector(31 downto 0);
    signal next_pc_reg    : std_logic_vector(31 downto 0);
    signal instr_reg      : std_logic_vector(31 downto 0);

begin

    pipeline_regs: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                imrd_fault_reg <= '0';
                flush_reg      <= '0';
                pc_reg         <= (others => '0');
                next_pc_reg    <= (others => '0');
                instr_reg      <= (others => '0');
            else
                imrd_fault_reg <= imrd_fault;
                flush_reg      <= flush;
                pc_reg         <= pc;
                next_pc_reg    <= next_pc;
                instr_reg      <= instr;
            end if;
        end if;
    end process pipeline_regs;
    
    core_if_stage: if_stage generic map (
        RESET_ADDR => RESET_ADDR
    ) port map (
        clk        => clk,
        reset      => reset,
        imrd_err   => imrd_err,
        taken      => taken,
        target     => target,
        imrd_data  => imem_data,
        imrd_fault => imrd_fault,
        flush      => flush,
        imrd_addr  => imem_addr,
        pc         => pc, 
        next_pc    => next_pc,
        instr      => instr
    );

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
        flush      => flush_reg,
        instr      => instr_reg,
        pc         => pc_reg,
        next_pc    => next_pc_reg,
        dmrd_data  => dmrd_data,
        cycle      => cycle,
        timer      => timer,
        instret    => instret,
        dmrd_en    => dmrd_en,
        dmwr_en    => dmwr_en,
        taken      => taken,
        target     => target,
        dmwr_data  => dmwr_data,        
        dmrw_addr  => dmrw_addr,
        dm_byte_en => dm_byte_en
    );
    
end architecture core_arch;