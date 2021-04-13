library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity if_stage is
    
    port (
        clk: std_logic;
        branch, jal, jalr: in std_logic;
        target: in std_logic_vector(31 downto 0);
        instr_mem_addr: out std_logic_vector(31 downto 0);
        instr_mem_data: in std_logic_vector(31 downto 0);
        pc, next_pc: out std_logic_vector(31 downto 0);
        instr: out std_logic_vector(31 downto 0)
    );

end entity if_stage;

architecture if_stage_arch of if_stage is

    constant PC_INC: unsigned := x"4";
    constant NO_OP_INSTR: std_logic_vector(31 downto 0) := x"0000_0000";

    signal branch_or_jump: std_logic;
    signal target_i: std_logic_vector(31 downto 0);
    signal pc_i: std_logic_vector(31 downto 0) := x"0000_0000";
    signal next_pc_i: std_logic_vector(31 downto 0);
    
begin
    
    branch_or_jump <= branch or jal or jalr;

    target_i <= target(30 downto 0) & '0' when jalr = '1' else target;

    next_pc_i <= std_logic_vector(unsigned(pc_i) + PC_INC);

    process(clk)
    
    begin
        
        if rising_edge(clk) then
            
            if branch_or_jump = '1' then
                
                pc_i <= target_i;

            else

                pc_i <= next_pc_i;
                
            end if;

        end if;
    
    end process;

    instr_mem_addr <= pc_i;

    pc <= pc_i;

    next_pc <= next_pc_i;

    instr <= NO_OP_INSTR when branch_or_jump = '1' else instr_mem_data;

end architecture if_stage_arch;