----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- package: leaf system simulator package
-- 2022
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package leaf_sim_pkg is
    
    component sim_syscon is
        generic (
            CLK_PERIOD : time := 20 ns
        );
        port (
            halt  : in  std_logic;
            clk_o : out std_logic;
            rst_o : out std_logic
        );
    end component sim_syscon;

    component sim_halt is
        port (
            clk_i : in  std_logic;
            rst_i : in  std_logic;
            dat_i : in  std_logic_vector(31 downto 0);
            cyc_i : in  std_logic;
            stb_i : in  std_logic;
            we_i  : in  std_logic;
            ack_o : out std_logic;
            halt  : out std_logic
        );
    end component sim_halt;

    component sim_io is
        port (
            clk_i : in  std_logic;
            rst_i : in  std_logic;
            halt  : in  std_logic;
            dat_i : in  std_logic_vector(31 downto 0);
            cyc_i : in  std_logic;
            stb_i : in  std_logic;
            we_i  : in  std_logic;
            sel_i : in  std_logic_vector(3  downto 0);
            adr_i : in  std_logic_vector(1  downto 0);
            ack_o : out std_logic;
            dat_o : out std_logic_vector(31 downto 0)
        );
    end component sim_io;

    component sim_mem is
        generic (
            BITS    : natural := 8;
            PROGRAM : string
        );
        port (
            clk_i : in  std_logic;
            rst_i : in  std_logic;
            dat_i : in  std_logic_vector(31 downto 0);
            cyc_i : in  std_logic;
            stb_i : in  std_logic;
            we_i  : in  std_logic;
            sel_i : in  std_logic_vector(3  downto 0);        
            adr_i : in  std_logic_vector(BITS-3 downto 0);
            ack_o : out std_logic;
            dat_o : out std_logic_vector(31 downto 0)
        );
    end component sim_mem;
    
end package leaf_sim_pkg;