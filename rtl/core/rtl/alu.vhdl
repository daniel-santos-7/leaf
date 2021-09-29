library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;

entity alu is

    port(
	    opd0: in  std_logic_vector(31 downto 0);
        opd1: in  std_logic_vector(31 downto 0);
	    op:   in  std_logic_vector(5  downto 0);
        
	    res:  out std_logic_vector(31 downto 0)
    );

end entity alu;

architecture alu_arch of alu is

    signal arith_op:   std_logic;
    signal arith_opd0: std_logic_vector(31 downto 0);
    signal arith_opd1: std_logic_vector(31 downto 0);
    signal arith_res:  std_logic_vector(31 downto 0);

    signal comp_en:     std_logic;
    signal comp_op:     std_logic;
    signal comp_opd0:   std_logic;
    signal comp_opd1:   std_logic;
    signal comp_opd2:   std_logic;
    signal comp_bypass: std_logic_vector(31 downto 0);
    signal comp_res:    std_logic_vector(31 downto 0);

    signal logic_op:     std_logic_vector(1  downto 0);
    signal logic_opd0:   std_logic_vector(31 downto 0);
    signal logic_opd1:   std_logic_vector(31 downto 0);
    signal logic_bypass: std_logic_vector(31 downto 0);
    signal logic_res:    std_logic_vector(31 downto 0);

    signal shifter_op:     std_logic_vector(1  downto 0);
    signal shifter_opd:    std_logic_vector(31 downto 0);
    signal shifter_shamt:  std_logic_vector(4  downto 0);
    signal shifter_bypass: std_logic_vector(31 downto 0);
    signal shifter_res:    std_logic_vector(31 downto 0);
    
begin

    arith_op   <= op(4) or op(5);
    arith_opd0 <= opd0;
    arith_opd1 <= opd1;

    comp_en     <= op(5);
    comp_op     <= op(4);
    comp_opd0   <= opd0(31);
    comp_opd1   <= opd1(31);
    comp_opd2   <= arith_res(31);
    comp_bypass <= arith_res;

    logic_op     <= op(3 downto 2);
    logic_opd0   <= opd0;
    logic_opd1   <= opd1;
    logic_bypass <= comp_res;

    shifter_op     <= op(1 downto 0);
    shifter_opd    <= opd0;
    shifter_shamt  <= opd1(4 downto 0);
    shifter_bypass <= logic_res;

    arith_unit: process(arith_op, arith_opd0, arith_opd1)
            
        variable opd0_i: std_logic_vector(31 downto 0);
        variable opd1_i: std_logic_vector(31 downto 0);
        variable cin:    std_logic_vector(0  downto 0);

    begin

        if arith_op = '1' then
            
            opd0_i := arith_opd0;
            opd1_i := not arith_opd1;
            cin(0) := '1';

        else

            opd0_i := arith_opd0;
            opd1_i := arith_opd1;
            cin(0) := '0';

        end if;

        arith_res <= std_logic_vector(unsigned(opd0_i) + unsigned(opd1_i) + unsigned(cin));

    end process arith_unit;

    comparator: process(comp_en, comp_op, comp_opd0, comp_opd1, comp_opd2, comp_bypass)
    
        variable comp_res_i: std_logic;

    begin
        
        if comp_opd0 = comp_opd1 then

            comp_res_i := comp_opd2;

        else 
            
            if comp_op = '0' then

                comp_res_i := comp_opd0 and not comp_opd1;

            else
            
                comp_res_i := not comp_opd0 and comp_opd1;
                
            end if;

        end if;

        if comp_en = '1' then
            
            comp_res <= (0 => comp_res_i, others => '0');

        else

            comp_res <= comp_bypass;

        end if;

    end process comparator;

    logic_unit: process(logic_op, logic_opd0, logic_opd1, logic_bypass)
    
        constant LOGIC_XOR: std_logic_vector(1 downto 0) := b"00";
        constant LOGIC_OR:  std_logic_vector(1 downto 0) := b"01";
        constant LOGIC_AND: std_logic_vector(1 downto 0) := b"10";

    begin
        
        case logic_op is
            
             when LOGIC_XOR => 
                
                logic_res <= opd0 xor opd1;

            when LOGIC_OR =>  
            
                logic_res <= opd0 or opd1;

            when LOGIC_AND => 
                
                logic_res <= opd0 and opd1;
            
            when others =>  
            
                logic_res <= logic_bypass;
                
        end case;

    end process logic_unit;

    shifter: process(shifter_op, shifter_opd, shifter_shamt, shifter_bypass)
    
        variable shamt: integer range 0 to 31;

        constant SHIFTER_SLL: std_logic_vector(1 downto 0) := b"00";
        constant SHIFTER_SRL: std_logic_vector(1 downto 0) := b"01";
        constant SHIFTER_SRA: std_logic_vector(1 downto 0) := b"10";

    begin

        shamt := to_integer(unsigned(shifter_shamt));

        case shifter_op is
            
            when SHIFTER_SLL => 
            
                shifter_res <= std_logic_vector(shift_left(unsigned(shifter_opd), shamt));

            when SHIFTER_SRL => 
            
                shifter_res <= std_logic_vector(shift_right(unsigned(shifter_opd), shamt));
                
            when SHIFTER_SRA => 
            
                shifter_res <= std_logic_vector(shift_right(signed(shifter_opd), shamt));

            when others => 
            
                shifter_res <= shifter_bypass;
        
        end case;       

    end process shifter;

    res <= shifter_res;

end architecture alu_arch;