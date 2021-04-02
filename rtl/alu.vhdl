library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.alu_pkg.all;

entity alu is

    port(
	    opd0, opd1: in  std_logic_vector(31 downto 0);
	    op: in alu_op;
	    rslt: out std_logic_vector(31 downto 0);
        zero: out std_logic
    );

end entity alu;

architecture alu_arch of alu is

    signal rslt_i: std_logic_vector(31 downto 0) := x"0000_0000";

begin

    process(op, opd0, opd1)

	begin

		case op is
			
            when ALU_AND => rslt_i <= opd0 and opd1;

			when ALU_OR => rslt_i <= opd0 or opd1;
			
            when ALU_XOR => rslt_i <= opd0 xor opd1;
			
            when ALU_SLT =>
				
                if signed(opd0) < signed(opd1) then
				
                    rslt_i <= (0 => '1', others => '0');
				
                else
				
                    rslt_i <= (others => '0');
				
                end if;

			when ALU_SLTU =>

				if unsigned(opd0) < unsigned(opd1) then
			
                    rslt_i <= (0 => '1', others => '0');
			
                else
			
                    rslt_i <= (others => '0');
			
                end if;
			
            when ALU_ADD => rslt_i <= std_logic_vector(unsigned(opd0) + unsigned(opd1));
			
            when ALU_SUB => rslt_i <= std_logic_vector(unsigned(opd0) - unsigned(opd1));
			
            when ALU_SRL => rslt_i <= std_logic_vector(shift_right(unsigned(opd0), to_integer(unsigned(opd1(4 downto 0)))));
			
            when ALU_SLL => rslt_i <= std_logic_vector(shift_left(unsigned(opd0), to_integer(unsigned(opd1(4 downto 0)))));
			
            when ALU_SRA => rslt_i <= std_logic_vector(shift_right(signed(opd0), to_integer(unsigned(opd1(4 downto 0)))));
			
            when others => rslt_i <= (others => '0');
		
        end case;

    end process;

    process(rslt_i)
    
    begin

        rslt <= rslt_i;

        if rslt_i = x"0000_0000" then
            
            zero <= '1';

        else

            zero <= '0';

        end if; 
        
    end process;

end architecture alu_arch;