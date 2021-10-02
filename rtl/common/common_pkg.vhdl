----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- package: common
-- description: common resources package
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package common_pkg is

    component fifo is
        generic (
            SIZE: natural := 32;
            BITS: natural := 8 
        );
    
        port (
            clk:   in std_logic;
            reset: in std_logic;
    
            wr:      in  std_logic;
            wr_en:   out std_logic;
            wr_data: in  std_logic_vector(7 downto 0);
    
            rd:       in  std_logic;
            rd_en:    out std_logic;
            rd_data:  out std_logic_vector(7 downto 0)
        );
    end component fifo;

    procedure tick(constant T: in time; signal clk: inout std_logic);
    procedure ntick(constant T: in time; signal clk: inout std_logic; constant N: natural);

end package common_pkg;

package body common_pkg is
    
    procedure tick(constant T: in time; signal clk: inout std_logic) is
    begin
        
        clk <= not clk;
        wait for T/2;
        
        clk <= not clk;
        wait for T/2;

    end procedure;

    procedure ntick(constant T: in time; signal clk: inout std_logic; constant N: natural) is
    begin
        
        for i in 1 to N loop
            tick(T, clk);
        end loop;

    end procedure;
    
end package body common_pkg;