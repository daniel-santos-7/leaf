library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.core_pkg.all;

entity alu is

    port(
	    opd0, opd1: in  std_logic_vector(31 downto 0);
	    op: in std_logic_vector(3 downto 0);
	    rslt: out std_logic_vector(31 downto 0)
    );

end entity alu;

architecture alu_arch of alu is

begin

    process(op, opd0, opd1)

	begin

		case op is
            
            when ALU_ADD => rslt <= std_logic_vector(unsigned(opd0) + unsigned(opd1));
			
            when ALU_SLL => rslt <= std_logic_vector(shift_left(unsigned(opd0), to_integer(unsigned(opd1(4 downto 0)))));

            when ALU_SLT =>
				
                if signed(opd0) < signed(opd1) then
				
                    rslt <= (0 => '1', others => '0');
				
                else
				
                    rslt <= (others => '0');
				
                end if;

            when ALU_SLTU =>

				if unsigned(opd0) < unsigned(opd1) then
			
                    rslt <= (0 => '1', others => '0');
			
                else
			
                    rslt <= (others => '0');
			
                end if;

            when ALU_XOR => rslt <= opd0 xor opd1;

            when ALU_SRL => rslt <= std_logic_vector(shift_right(unsigned(opd0), to_integer(unsigned(opd1(4 downto 0)))));

			when ALU_OR => rslt <= opd0 or opd1;
			
            when ALU_AND => rslt <= opd0 and opd1;

            when ALU_SUB => rslt <= std_logic_vector(unsigned(opd0) - unsigned(opd1));

            when ALU_SRA => rslt <= std_logic_vector(shift_right(signed(opd0), to_integer(unsigned(opd1(4 downto 0)))));
			
            when others => rslt <= (others => '0');
		
        end case;

    end process;

end architecture alu_arch;