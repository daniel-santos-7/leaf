library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity addr_comp is
    port (
        addr  : in  std_logic_vector(31 downto 0);
        acmp0 : out std_logic;
        acmp1 : out std_logic;
        acmp2 : out std_logic
    );
end entity addr_comp;

architecture addr_comp_arch of addr_comp is
begin

    acmp0 <= '1' when addr(31 downto  2) = b"000000000000000000000000000000" else '0';
    acmp1 <= '1' when addr(31 downto  2) = b"000000000000000000000000000001" else '0';
    acmp2 <= '1' when addr(31 downto 22) = b"0000000001" else '0';
    
end architecture addr_comp_arch;