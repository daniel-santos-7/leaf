library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package sim_pkg is
    
    component sim_ctrl is
        generic (
            CLK_PERIOD : time := 20 ns
        );
        port (
            wr_en   : in  std_logic;
            wr_data : in  std_logic_vector(31 downto 0);
            halt    : out std_logic;
            clk     : out std_logic;
            reset   : out std_logic
        );
    end component sim_ctrl;

    component sim_mem is
        generic (
            BITS    : natural := 8;
            PROGRAM : string
        );
        port (
            clk        : in  std_logic;
            reset      : in  std_logic;
            wr_en      : in  std_logic;
            rd_en      : in  std_logic;
            wr_byte_en : in  std_logic_vector(3  downto 0);
            wr_data1   : in  std_logic_vector(31 downto 0);
            rw_addr0   : in  std_logic_vector(BITS-3 downto 0);
            rw_addr1   : in  std_logic_vector(BITS-3 downto 0);        
            rd_data0   : out std_logic_vector(31 downto 0);
            rd_data1   : out std_logic_vector(31 downto 0)
        );
    end component sim_mem;

    component sim_out is
        generic (
            FILENAME : string
        );
        port (
            halt    : in std_logic;
            clk     : in std_logic;
            reset   : in std_logic;
            wr_en   : in std_logic;
            wr_data : in std_logic_vector(31 downto 0)
        );
    end component sim_out;

    component addr_comp is
        port (
            addr  : in  std_logic_vector(31 downto 0);
            wr_en : in  std_logic;
            acm0  : out std_logic;
            acm1  : out std_logic;
            acm2  : out std_logic
        );
    end component addr_comp;
    
end package sim_pkg;