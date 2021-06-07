library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity if_stage is
    
    generic (
        RESET_ADDR: std_logic_vector(31 downto 0) := x"00000000"
    );

    port (
        clk:   in std_logic;
        reset: in std_logic;

        jmp:     in std_logic;
        jmp_rel: in std_logic;
        branch:  in std_logic;
        trap:    in std_logic;

        target: in std_logic_vector(31 downto 0);
        
        rd_instr_mem_data: in  std_logic_vector(31 downto 0);
        rd_instr_mem_addr: out std_logic_vector(31 downto 0);
        
        pc:      out std_logic_vector(31 downto 0);
        next_pc: out std_logic_vector(31 downto 0);
        instr:   out std_logic_vector(31 downto 0);
        flush:   out std_logic
    );

end entity if_stage;

architecture if_stage_arch of if_stage is

    signal taken: std_logic;
    
    signal target_i: std_logic_vector(31 downto 0);
    
    signal pc_reg:    std_logic_vector(31 downto 0);

    signal next_pc_i: std_logic_vector(31 downto 0);
    
begin
    
    taken <= branch or jmp or trap;

    target_i <= target(31 downto 1) & '0' when jmp = '1' and jmp_rel = '1' else target;
    
    next_pc_i <= std_logic_vector(unsigned(pc_reg) + 4);

    pc_gen: process(clk)
    
    begin
        
        if rising_edge(clk) then

            if reset = '1' then
            
                pc_reg <= RESET_ADDR;

            elsif taken = '1' then
                
                pc_reg <= target_i;

            else

                pc_reg <= next_pc_i;
                
            end if;

        end if;
    
    end process pc_gen;

    rd_instr_mem_addr <= pc_reg;

    pc <= pc_reg;

    next_pc <= next_pc_i;
    
    instr <= rd_instr_mem_data;
    
    flush <= taken;

end architecture if_stage_arch;