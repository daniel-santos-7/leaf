library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity core is
    
    port (
        clk: in std_logic;
        instr_mem_addr: out std_logic_vector(31 downto 0);
        instr_mem_data: in std_logic_vector(31 downto 0);
        rd_mem_data: in std_logic_vector(31 downto 0);
        rd_mem_en: out std_logic;
        wr_mem_data: out std_logic_vector(31 downto 0);
        wr_mem_en: out std_logic
    );

end entity core;

architecture core_arch of core is
    
    signal branch, jal, jalr: std_logic;

    signal target, pc, next_pc, instr: std_logic_vector(31 downto 0);

    signal pc_reg, next_pc_reg, instr_reg: std_logic_vector(31 downto 0) := x"0000_0000";

begin

    process(clk)
    
    begin
        
        if rising_edge(clk) then
            
            pc_reg <= pc;
            next_pc_reg <= next_pc;
            instr_reg <= instr;

        end if;

    end process;
    
    core_if_stage: if_stage port map (
        clk => clk,
        branch => branch, 
        jal => jal, 
        jalr => jalr,
        target => target,
        instr_mem_addr => instr_mem_addr,
        instr_mem_data => instr_mem_data,
        pc => pc, 
        next_pc => next_pc,
        instr => instr
    );

    core_id_ex_stage: id_ex_stage port map (
        clk => clk,
        pc => pc_reg,
        next_pc => next_pc_reg,
        instr => instr_reg,
        rd_mem_data => rd_mem_data,
        rd_mem_en => rd_mem_en,
        wr_mem_data => wr_mem_data,
        wr_mem_en => wr_mem_en,
        branch => branch, 
        jal => jal, 
        jalr => jalr,
        target => target
    );
    
end architecture core_arch;