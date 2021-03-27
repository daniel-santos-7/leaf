library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity instrs_fetch is

    port(
        clk, pc_clr: in std_logic;
        instr_addr: out std_logic_vector(31 downto 0)
    );

end entity instrs_fetch;

architecture instrs_fetch_arch of instrs_fetch is
    
begin
    
    process(clk)
    
        constant addr_inc: std_logic_vector(31 downto 0) := x"0000_0004";

        variable pc: std_logic_vector(31 downto 0):= x"0000_0000";

    begin

        if rising_edge(clk) then

            if pc_clr = '1' then
                
                pc := x"0000_0000";

            else

                pc := std_logic_vector(unsigned(pc) + unsigned(addr_inc));

            end if;

            instr_addr <= pc;

        end if;
        
    end process;
    
end architecture instrs_fetch_arch;