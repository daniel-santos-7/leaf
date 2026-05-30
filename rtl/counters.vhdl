----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: cycle, time, instret counters
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity counters is
    port (
        clk_i    : in  std_logic;
        reset_i  : in  std_logic;
        retire_i : in  std_logic;
        cycle_o  : out std_logic_vector(63 downto 0);
        timer_o  : out std_logic_vector(63 downto 0);
        instret_o: out std_logic_vector(63 downto 0)
    );
end entity counters;

architecture counters_arch of counters is

    signal cycle_reg   : unsigned(63 downto 0);
    signal timer_reg   : unsigned(63 downto 0);
    signal instret_reg : unsigned(63 downto 0);

begin

    cycle_counter: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                cycle_reg <= (others => '0');
            else
                cycle_reg <= cycle_reg + 1;
            end if;
        end if;
    end process cycle_counter;

    timer_counter: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                timer_reg <= (others => '0');
            else
                timer_reg <= timer_reg + 1;
            end if;
        end if;
    end process timer_counter;

    instret_counter: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                instret_reg <= (others => '0');
            elsif retire_i = '1' then
                instret_reg <= instret_reg + 1;
            end if;
        end if;
    end process instret_counter;

    cycle_o   <= std_logic_vector(cycle_reg);
    timer_o   <= std_logic_vector(timer_reg);
    instret_o <= std_logic_vector(instret_reg);

end architecture counters_arch;
