----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: cycle, time, instret counters
-- 2022
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity counters is
    port (
        clk     : in  std_logic;
        reset   : in  std_logic;
        cycle   : out std_logic_vector(63 downto 0);
        timer   : out std_logic_vector(63 downto 0);
        instret : out std_logic_vector(63 downto 0)
    );
end entity counters;

architecture counters_arch of counters is
    
    signal cycle_reg : std_logic_vector(63 downto 0);

begin
    
    cycle_counter: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                cycle_reg <= (others => '0');
            else
                cycle_reg <= std_logic_vector(unsigned(cycle_reg) + 1);
            end if;
        end if;
    end process cycle_counter;

    cycle   <= cycle_reg;
    timer   <= (others => '0');
    instret <= (others => '0');
    
end architecture counters_arch;