library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package soc_pkg is
    
    component soc_addr is
        port (
            addr  : in  std_logic_vector(31 downto 0);
            acmp0 : out std_logic;
            acmp1 : out std_logic;
            acmp2 : out std_logic
        );
    end component soc_addr;

    component soc_ram is
        generic (
            BITS  : natural := 8
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
    end component soc_ram;

    component soc_rom is
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
    end component soc_rom;

    component soc_uart is
        port (
            clk_i : in  std_logic;
            rst_i : in  std_logic;
            dat_i : in  std_logic_vector(31 downto 0);
            cyc_i : in  std_logic;
            stb_i : in  std_logic;
            we_i  : in  std_logic;
            sel_i : in  std_logic_vector(3  downto 0);        
            adr_i : in  std_logic_vector(1 downto 0);
            rx    : in  std_logic;
            ack_o : out std_logic;
            dat_o : out std_logic_vector(31 downto 0);
            tx    : out std_logic
        );
    end component soc_uart;

    component soc is
        port (
            clk: in  std_logic;
            rst: in  std_logic;
            rx : in  std_logic;
            tx : out std_logic
        );
    end component soc;
    
end package soc_pkg;