library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity core is
    
    port (
        clk, reset: in std_logic;
        rd_instr_mem_data: in std_logic_vector(31 downto 0);
        rd_instr_mem_addr: out std_logic_vector(31 downto 0);
        rd_mem_data: in std_logic_vector(31 downto 0);
        rd_mem_en: out std_logic;
        wr_mem_data: out std_logic_vector(31 downto 0);
        wr_mem_en: out std_logic;
        rd_wr_mem_addr: out std_logic_vector(31 downto 0)
    );

end entity core;

architecture core_arch of core is
    
    signal jmp, branch, target_shift: std_logic;

    signal no_op: std_logic;

    signal pc, next_pc, instr, target: std_logic_vector(31 downto 0);

    signal pc_reg, next_pc_reg, instr_reg: std_logic_vector(31 downto 0) := x"00000000";

    signal no_op_reg: std_logic := '0';

begin

    process(clk)
    
    begin
        
        if rising_edge(clk) then
            
            pc_reg <= pc;
            next_pc_reg <= next_pc;
            instr_reg <= instr;
            no_op_reg <= no_op;

        end if;

    end process;
    
    core_if_stage: if_stage port map (
        clk => clk,
        reset => reset,
        jmp => jmp, 
        branch => branch, 
        target_shift => target_shift,
        target => target,
        rd_instr_mem_data => rd_instr_mem_data,
        rd_instr_mem_addr => rd_instr_mem_addr,
        pc => pc, 
        next_pc => next_pc,
        instr => instr,
        no_op => no_op
    );

    core_id_ex_stage: id_ex_stage port map (
        clk => clk,
        pc => pc_reg,
        next_pc => next_pc_reg,
        instr => instr_reg,
        no_op => no_op_reg,
        rd_mem_data => rd_mem_data,
        rd_mem_en => rd_mem_en,
        wr_mem_en => wr_mem_en,
        rd_wr_mem_addr => rd_wr_mem_addr,
        wr_mem_data => wr_mem_data,
        branch => branch, 
        jmp => jmp, 
        target_shift => target_shift,
        target => target
    );
    
end architecture core_arch;