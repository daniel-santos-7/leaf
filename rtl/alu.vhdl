library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;

entity alu is

    port(
	    opd0, opd1: in std_logic_vector(31 downto 0);
	    op: in std_logic_vector(3 downto 0);
	    res: out std_logic_vector(31 downto 0)
    );

end entity alu;

architecture alu_arch of alu is

    signal logic_res0, logic_res1: std_logic_vector(31 downto 0);
    signal comp_res: std_logic;
    signal arith_res: std_logic_vector(31 downto 0);
    signal shifter_res: std_logic_vector(31 downto 0);

begin

    logic_unit: process(op, opd0, opd1)
    
        constant ZERO: std_logic_vector(31 downto 0) := (others => '0');

    begin
        
        case op is
            
            when ALU_SUB =>

                logic_res0 <= opd0;
                logic_res1 <= not opd1;

            when ALU_XOR => 
                
                logic_res0 <= opd0 xor opd1;
                logic_res1 <= ZERO;

            when ALU_OR =>  
            
                logic_res0 <= opd0 or opd1;
                logic_res1 <= ZERO;

            when ALU_AND => 
                
                logic_res0 <= opd0 and opd1;
                logic_res1 <= ZERO;

            when ALU_SLT | ALU_SLTU =>

                logic_res0 <= ZERO;
                logic_res1 <= ZERO;

            when ALU_SLL | ALU_SRL | ALU_SRA =>

                logic_res0 <= opd0;
                logic_res1 <= ZERO;

            when others =>  
            
                logic_res0 <= opd0;
                logic_res1 <= opd1;
                
        end case;

    end process logic_unit;

    comparator: process(op, opd0, opd1)
    
        variable less, less_unsigned: boolean;

    begin
        
        less := signed(opd0) < signed(opd1);

        less_unsigned := unsigned(opd0) < unsigned(opd1);

        if (op = ALU_SLT and less) or (op = ALU_SLTU and less_unsigned) then

            comp_res <= '1';

        else

            comp_res <= '0';

        end if;

    end process comparator;

    arith_unit: process(op, comp_res, logic_res0, logic_res1)
    
        variable cin: std_logic;

    begin

        if op = ALU_SUB then
            
            cin := '1';

        else
           
            cin := comp_res;

        end if;

        arith_res <= std_logic_vector(unsigned(logic_res0) + unsigned(logic_res1) + ("" & cin));

    end process arith_unit;

    shifter: process(op, arith_res, opd1)
    
        variable shamt: integer;

    begin

        shamt := to_integer(unsigned(opd1(4 downto 0)));

        case op is
            
            when ALU_SLL => shifter_res <= std_logic_vector(shift_left(unsigned(arith_res), shamt));

            when ALU_SRL => shifter_res <= std_logic_vector(shift_right(unsigned(arith_res), shamt));
                
            when ALU_SRA => shifter_res <= std_logic_vector(shift_right(signed(arith_res), shamt));

            when others => shifter_res <= arith_res;
        
        end case;       

    end process shifter;

    res <= shifter_res;

end architecture alu_arch;