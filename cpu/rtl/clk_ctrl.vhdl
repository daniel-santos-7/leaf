----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: clock gating control
-- 2022
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity clk_ctrl is
    port (
        clk_i  : in  std_logic;
        rst_i  : in  std_logic;
        clk_en : in  std_logic;
        clk    : out std_logic
    );
end entity clk_ctrl;

architecture rtl of clk_ctrl is

    -- enable latch --

    signal en_latch : std_logic;

begin
    
    clk_gating: process(clk_i)
    begin
        if falling_edge(clk_i) then
            if clk_en = '1' then
                en_latch <= '1';
            else
                en_latch <= '0';
            end if;
        end if;
    end process clk_gating;
    
    clk <= (en_latch or rst_i) and clk_i;

end architecture rtl;