library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity if_stage is
    
    port (
        clk: std_logic;
        jmp, branch, target_shift: in std_logic;
        target: in std_logic_vector(31 downto 0);
        rd_instr_mem_data: in std_logic_vector(31 downto 0);
        rd_instr_mem_addr: out std_logic_vector(31 downto 0);
        pc, next_pc: out std_logic_vector(31 downto 0);
        instr: out std_logic_vector(31 downto 0);
        no_op: out std_logic
    );

end entity if_stage;

architecture if_stage_arch of if_stage is

    constant PC_INC: unsigned := x"4";

    signal take: std_logic;
    signal target_i: std_logic_vector(31 downto 0);
    signal pc_reg: std_logic_vector(31 downto 0) := x"0000_0000";
    signal next_pc_i: std_logic_vector(31 downto 0);
    
begin
    
    take <= branch or jmp;

    target_i <= target(30 downto 0) & '0' when target_shift = '1' else target;

    next_pc_i <= std_logic_vector(unsigned(pc_reg) + PC_INC);

    process(clk)
    
    begin
        
        if rising_edge(clk) then
            
            if take = '1' then
                
                pc_reg <= target_i;

            else

                pc_reg <= next_pc_i;
                
            end if;

        end if;
    
    end process;

    rd_instr_mem_addr <= pc_reg;

    pc <= pc_reg;

    next_pc <= next_pc_i;

    instr <= rd_instr_mem_data;

    no_op <= take;

end architecture if_stage_arch;