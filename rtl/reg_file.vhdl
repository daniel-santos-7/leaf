----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- 2022
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity reg_file is
    port (
        clk          : in  std_logic;
        rd_reg_addr0 : in  std_logic_vector(4  downto 0);
        rd_reg_addr1 : in  std_logic_vector(4  downto 0);
        wr_reg_addr  : in  std_logic_vector(4  downto 0);
        wr_reg_data  : in  std_logic_vector(31 downto 0);
        wr_reg_en    : in  std_logic;
        rd_reg_data0 : out std_logic_vector(31 downto 0);
        rd_reg_data1 : out std_logic_vector(31 downto 0)
    );
end entity reg_file;

architecture reg_file_arch of reg_file is

    type regs_array is array(0 to 31) of std_logic_vector(31 downto 0);
    
    signal regs: regs_array;

    constant X0_ADDR: std_logic_vector(4  downto 0) := b"00000";
    constant X0_DATA: std_logic_vector(31 downto 0) := x"00000000";

    function to_uint(value: std_logic_vector) return integer is
    begin
        return to_integer(unsigned(value));
    end function;

begin

    write_reg: process(clk)
    begin
        if rising_edge(clk) then
            regs(0) <= X0_DATA;
            if wr_reg_en = '1' then
                if wr_reg_addr /= X0_ADDR then
                    regs(to_uint(wr_reg_addr)) <= wr_reg_data;
                end if;
            end if;
        end if;
    end process write_reg;
    
    rd_reg_data0 <= regs(to_uint(rd_reg_addr0));
    rd_reg_data1 <= regs(to_uint(rd_reg_addr1));

end architecture reg_file_arch;