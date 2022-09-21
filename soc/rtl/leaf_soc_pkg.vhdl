library IEEE;
use IEEE.std_logic_1164.all;

package leaf_soc_pkg is
    
    component soc_syscon is
        port (
            clk   : in  std_logic;
            rst   : in  std_logic;
            clk_o : out std_logic;
            rst_o : out std_logic
        );
    end component soc_syscon;

    component ram is
        generic (
            BITS : natural := 8
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
    end component ram;

    component rom is
        generic (
            BITS : natural := 8
        );
        port (
            clk_i : in  std_logic;
            rst_i : in  std_logic;
            cyc_i : in  std_logic;
            stb_i : in  std_logic;
            adr_i : in  std_logic_vector(BITS-3 downto 0);
            ack_o : out std_logic;
            dat_o : out std_logic_vector(31 downto 0)
        );
    end component rom;

    component leaf_soc is
        port (
            clk : in  std_logic;
            rst : in  std_logic;
            rx  : in  std_logic;
            tx  : out std_logic;
            dbg : out std_logic_vector(7 downto 0)
        );
    end component leaf_soc;

    component debug_reg is
        port (
            clk_i : in  std_logic;
            rst_i : in  std_logic;
            dat_i : in  std_logic_vector(7 downto 0);
            cyc_i : in  std_logic;
            stb_i : in  std_logic;
            we_i  : in  std_logic;
            ack_o : out std_logic;
            dat_o : out std_logic_vector(7 downto 0)
        );
    end component debug_reg;
    
end package leaf_soc_pkg;