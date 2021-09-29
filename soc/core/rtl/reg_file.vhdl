library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity reg_file is

    port (
        clk: in std_logic;
        
        rd_reg_addr0: in std_logic_vector(4 downto 0);
        rd_reg_addr1: in std_logic_vector(4 downto 0);
        wr_reg_addr:  in std_logic_vector(4 downto 0);
        
        wr_reg_data: in std_logic_vector(31 downto 0);
        wr_reg_en:   in std_logic;
        
        rd_reg_data0: out std_logic_vector(31 downto 0);
        rd_reg_data1: out std_logic_vector(31 downto 0)
    );

end entity reg_file;

architecture reg_file_arch of reg_file is

    type regs_array is array(0 to 31) of std_logic_vector(31 downto 0);

    signal regs: regs_array;

    constant X0: std_logic_vector(4 downto 0) := b"00000";

begin

    write_reg: process(clk)

    begin
        
        if rising_edge(clk) and wr_reg_en = '1' and wr_reg_addr /= X0 then
                
            regs(to_integer(unsigned(wr_reg_addr))) <= wr_reg_data;

        end if;

    end process write_reg;

    rd_reg_data0 <= (others => '0') when rd_reg_addr0 = X0 else regs(to_integer(unsigned(rd_reg_addr0)));
    rd_reg_data1 <= (others => '0') when rd_reg_addr1 = X0 else regs(to_integer(unsigned(rd_reg_addr1)));

end architecture reg_file_arch;