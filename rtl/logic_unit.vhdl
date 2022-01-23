library IEEE;
use IEEE.std_logic_1164.all;

entity logic_unit is
    
    port (
	    opd0:   in  std_logic_vector(31 downto 0);
	    opd1:   in  std_logic_vector(31 downto 0);
        op:     in  std_logic_vector(1  downto 0);
        res:    out std_logic_vector(31 downto 0)
    );

end entity logic_unit;

architecture logic_unit_arch of logic_unit is
    
    constant LOGIC_XOR: std_logic_vector(1 downto 0) := b"00";
    constant LOGIC_OR:  std_logic_vector(1 downto 0) := b"01";
    constant LOGIC_AND: std_logic_vector(1 downto 0) := b"10";

begin
    
    main: process(op, opd0, opd1)
    begin
        
        case op is

            when LOGIC_XOR =>   res <= opd0 xor opd1;
            when LOGIC_OR  =>   res <= opd0 or opd1;
            when LOGIC_AND =>   res <= opd0 and opd1;
            when others =>      null;

        end case;

    end process main;
    
end architecture logic_unit_arch;