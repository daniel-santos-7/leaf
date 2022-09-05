library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity soc_addr is
    port (
        addr  : in  std_logic_vector(31 downto 0);
        acmp0 : out std_logic;
        acmp1 : out std_logic;
        acmp2 : out std_logic
    );
end entity soc_addr;

architecture addr_comp_arch of soc_addr is
begin
    
    acmp0 <= '1' when addr(31 downto  4) = x"0000000" else '0';
    acmp1 <= '1' when addr(31 downto  8) = x"000001" else '0';
    acmp2 <= '1' when addr(31 downto 16) = x"0001" else '0';

end architecture addr_comp_arch;