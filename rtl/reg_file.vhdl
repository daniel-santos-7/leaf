library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity reg_file is

    port (
        clk: in std_logic;
        rd_reg0, rd_reg1, wr_reg: in std_logic_vector(3 downto 0);
        wr_data: in std_logic_vector(31 downto 0);
        reg_wr: in std_logic;
        rd_data0, rd_data1: out std_logic_vector(31 downto 0)
    );

end entity reg_file;

architecture reg_file_arch of reg_file is

    type regs_array is array(0 to 31) of std_logic_vector(31 downto 0);

begin

    process(clk)

        variable regs : regs_array := (others => x"0000_0000");
    
    begin
        
        if rising_edge(clk) then

            if reg_wr = '1' and wr_reg /= b"0000"  then
                
                regs(to_integer(unsigned(wr_reg))) := wr_data;

            end if;

            rd_data0 <= regs(to_integer(unsigned(rd_reg0)));
			
            rd_data1 <= regs(to_integer(unsigned(rd_reg1)));
            
        end if;

    end process;

end architecture reg_file_arch;