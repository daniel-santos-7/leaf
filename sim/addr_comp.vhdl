library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity addr_comp is
    port (
        addr  : in  std_logic_vector(31 downto 0);
        wr_en : in  std_logic;
        acm0  : out std_logic;
        acm1  : out std_logic;
        acm2  : out std_logic
    );
end entity addr_comp;

architecture addr_comp_arch of addr_comp is
    
    signal offset : std_logic_vector(31 downto 20);
    signal base   : std_logic_vector(19 downto 0);

begin
    
    offset <= addr(31 downto 20);
    base   <= addr(19 downto 0);

    acm0 <= wr_en when offset = x"000" or offset = x"001" else '0';
    acm1 <= wr_en when offset = x"002" and base = x"00000" else '0';
    acm2 <= wr_en when offset = x"002" and base = x"00001" else '0';
    
end architecture addr_comp_arch;