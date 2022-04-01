library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity core is
    generic (
        RESET_ADDR: std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        clk         : in  std_logic; 
        reset       : in  std_logic;
        imem_data   : in  std_logic_vector(31 downto 0);
        imem_addr   : out std_logic_vector(31 downto 0);
        dmrd_data   : in  std_logic_vector(31 downto 0);
        dmwr_data   : out std_logic_vector(31 downto 0);
        dmrd_en     : out std_logic;
        dmwr_en     : out std_logic;
        dmrw_addr   : out std_logic_vector(31 downto 0);
        dm_byte_en  : out std_logic_vector(3 downto 0);
        ex_irq      : in  std_logic;
        sw_irq      : in  std_logic;
        tm_irq      : in  std_logic
    );
end entity core;

architecture core_arch of core is

    signal taken  : std_logic;
    signal target : std_logic_vector(31 downto 0);
    
    signal pc      : std_logic_vector(31 downto 0);
    signal next_pc : std_logic_vector(31 downto 0);
    signal instr   : std_logic_vector(31 downto 0);
    signal flush   : std_logic;

    signal pc_reg       : std_logic_vector(31 downto 0);
    signal next_pc_reg  : std_logic_vector(31 downto 0);
    signal instr_reg    : std_logic_vector(31 downto 0);
    signal flush_reg    : std_logic;

begin

    pipeline_regs: process(clk)
    begin
        
        if rising_edge(clk) then
            if reset = '1' then
                pc_reg      <= (others => '0');
                next_pc_reg <= (others => '0');
                instr_reg   <= (others => '0');
                flush_reg   <= '0';
            else
                pc_reg      <= pc;
                next_pc_reg <= next_pc;
                instr_reg   <= instr;
                flush_reg   <= flush;
            end if;
        end if;

    end process pipeline_regs;
    
    core_if_stage: if_stage generic map (
        RESET_ADDR => RESET_ADDR
    ) port map (
        clk       => clk,
        reset     => reset,
        taken     => taken,
        target    => target,
        imem_data => imem_data,
        imem_addr => imem_addr,
        pc        => pc, 
        next_pc   => next_pc,
        instr     => instr,
        flush     => flush
    );

    core_id_ex_stage: id_ex_stage port map (
        clk        => clk,
        reset      => reset,
        pc         => pc_reg,
        next_pc    => next_pc_reg,
        instr      => instr_reg,
        flush      => flush_reg,
        dmrd_data  => dmrd_data,
        dmwr_data  => dmwr_data,
        dmrd_en    => dmrd_en,
        dmwr_en    => dmwr_en,
        dmrw_addr  => dmrw_addr,
        dm_byte_en => dm_byte_en,
        ex_irq     => ex_irq,
        sw_irq     => sw_irq,
        tm_irq     => tm_irq,
        taken      => taken,
        target     => target
    );
    
end architecture core_arch;