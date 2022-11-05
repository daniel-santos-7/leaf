----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- 2022
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity if_stage is
    generic (
        RESET_ADDR : std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        imrd_err   : in  std_logic;
        taken      : in  std_logic;
        target     : in  std_logic_vector(31 downto 0);
        imrd_data  : in  std_logic_vector(31 downto 0);
        imrd_fault : out std_logic;
        flush      : out std_logic;
        imrd_addr  : out std_logic_vector(31 downto 0);
        pc         : out std_logic_vector(31 downto 0);
        next_pc    : out std_logic_vector(31 downto 0);
        instr      : out std_logic_vector(31 downto 0)
    );
end entity if_stage;

architecture if_stage_arch of if_stage is
    
    signal pc_reg   : std_logic_vector(31 downto 0);
    signal next_res : std_logic_vector(31 downto 0);
    
begin

    next_res <= std_logic_vector(unsigned(pc_reg) + 4);

    pc_gen: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pc_reg <= RESET_ADDR;
            elsif taken = '1' then
                pc_reg <= target;
            else
                pc_reg <= next_res;
            end if;
        end if;
    end process pc_gen;

    imrd_fault <= imrd_err;
    flush      <= taken or imrd_err;
    imrd_addr  <= pc_reg;
    pc         <= pc_reg;
    next_pc    <= next_res;
    instr      <= imrd_data;

end architecture if_stage_arch;