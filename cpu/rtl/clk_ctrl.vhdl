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
    
    clk_gating: process(clk_i, clk_en)
    begin
        if clk_i = '0' then
            en_latch <= clk_en;
        end if;
    end process clk_gating;
    
    clk <= (en_latch or rst_i) and clk_i;

end architecture rtl;