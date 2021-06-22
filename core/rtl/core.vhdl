library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity core is
    
    generic (
        RESET_ADDR: std_logic_vector(31 downto 0) := (others => '0')
    );

    port (
        clk:   in std_logic; 
        reset: in std_logic;
        
        rd_instr_mem_data: in  std_logic_vector(31 downto 0);
        rd_instr_mem_addr: out std_logic_vector(31 downto 0);
        
        rd_mem_data: in  std_logic_vector(31 downto 0);
        wr_mem_data: out std_logic_vector(31 downto 0);
        
        rd_mem_en: out std_logic;
        wr_mem_en: out std_logic;
        
        rd_wr_mem_addr: out std_logic_vector(31 downto 0);
        wr_mem_byte_en: out std_logic_vector(3 downto 0);

        ex_irq: in std_logic;
        sw_irq: in std_logic;
        tm_irq: in std_logic
    );

end entity core;

architecture core_arch of core is

    signal jmp:     std_logic;
    signal branch:  std_logic;
    signal trap:    std_logic;
    
    signal pc:      std_logic_vector(31 downto 0);
    signal next_pc: std_logic_vector(31 downto 0);
    signal instr:   std_logic_vector(31 downto 0);
    signal target:  std_logic_vector(31 downto 0);
    signal flush:   std_logic;

    signal pc_reg:      std_logic_vector(31 downto 0);
    signal next_pc_reg: std_logic_vector(31 downto 0);
    signal instr_reg:   std_logic_vector(31 downto 0);
    signal flush_reg:   std_logic;

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
        clk               => clk,
        reset             => reset,
        jmp               => jmp, 
        branch            => branch, 
        trap              => trap,
        target            => target,
        rd_instr_mem_data => rd_instr_mem_data,
        rd_instr_mem_addr => rd_instr_mem_addr,
        pc                => pc, 
        next_pc           => next_pc,
        instr             => instr,
        flush             => flush
    );

    core_id_ex_stage: id_ex_stage port map (
        clk            => clk,
        reset          => reset,
        pc             => pc_reg,
        next_pc        => next_pc_reg,
        instr          => instr_reg,
        flush          => flush_reg,
        rd_mem_data    => rd_mem_data,
        wr_mem_data    => wr_mem_data,
        rd_mem_en      => rd_mem_en,
        wr_mem_en      => wr_mem_en,
        rd_wr_mem_addr => rd_wr_mem_addr,
        wr_mem_byte_en => wr_mem_byte_en,
        ex_irq         => ex_irq,
        sw_irq         => sw_irq,
        tm_irq         => tm_irq,
        branch         => branch, 
        jmp            => jmp, 
        trap           => trap,
        target         => target
    );
    
end architecture core_arch;