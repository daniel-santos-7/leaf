library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity if_stage is
    generic (
        RESET_ADDR : std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        taken     : in  std_logic;
        target    : in  std_logic_vector(31 downto 0);
        imem_data : in  std_logic_vector(31 downto 0);
        imem_addr : out std_logic_vector(31 downto 0);
        pc        : out std_logic_vector(31 downto 0);
        next_pc   : out std_logic_vector(31 downto 0);
        instr     : out std_logic_vector(31 downto 0);
        flush     : out std_logic
    );
end entity if_stage;

architecture if_stage_arch of if_stage is
    
    signal target_i  : std_logic_vector(31 downto 0);
    signal next_pc_i : std_logic_vector(31 downto 0);
    signal pc_reg    : std_logic_vector(31 downto 0);
    
begin

    target_i  <= target(31 downto 2) & b"00";

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

    imem_addr <= pc_reg;
    pc        <= pc_reg;
    next_pc   <= next_pc_i;
    instr     <= imem_data;
    flush     <= taken;

end architecture if_stage_arch;