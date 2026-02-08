----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: register file
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_pkg.all;

entity reg_file is
    generic (
        SIZE : natural := 32
    );
    port (
        clk      : in  std_logic;
        we       : in  std_logic;
        wr_sel   : in  std_logic_vector(1 downto 0);
        wr_addr  : in  std_logic_vector(4  downto 0);
        wr_data0 : in  std_logic_vector(XLEN-1 downto 0);
        wr_data1 : in  std_logic_vector(XLEN-1 downto 0);
        wr_data2 : in  std_logic_vector(XLEN-1 downto 0);
        wr_data3 : in  std_logic_vector(XLEN-1 downto 0);
        rd_addr0 : in  std_logic_vector(4  downto 0);
        rd_addr1 : in  std_logic_vector(4  downto 0);
        rd_data0 : out std_logic_vector(XLEN-1 downto 0);
        rd_data1 : out std_logic_vector(XLEN-1 downto 0)
    );
end entity reg_file;

architecture reg_file_arch of reg_file is

    constant EMBEDDED : boolean := SIZE = 16;

    type regs_array is array(0 to SIZE-1) of std_logic_vector(XLEN-1 downto 0);
    
    signal regs: regs_array;

    signal wr_data: std_logic_vector(XLEN-1 downto 0);

    constant X0_ADDR: std_logic_vector(4  downto 0) := b"00000";

    constant X0_DATA: std_logic_vector(XLEN-1 downto 0) := (others => '0');

    function to_uint(value: std_logic_vector) return integer is
    begin
        return to_integer(unsigned(value));
    end function;

begin

    wr_data_mux: process(wr_sel, wr_data0, wr_data1, wr_data2, wr_data3)
    begin
        case wr_sel is
            when b"00" => wr_data <= wr_data0;
            when b"01" => wr_data <= wr_data1;
            when b"10" => wr_data <= wr_data2;
            when b"11" => wr_data <= wr_data3;
            when others => null;
        end case;
    end process wr_data_mux;

    large_reg_file: if (EMBEDDED = false) generate
        write_reg: process(clk)
        begin
            if rising_edge(clk) then
                regs(0) <= X0_DATA;
                if we = '1' then
                    if wr_addr /= X0_ADDR then
                        regs(to_uint(wr_addr)) <= wr_data;
                    end if;
                end if;
            end if;
        end process write_reg;

        rd_data0 <= regs(to_uint(rd_addr0));
        rd_data1 <= regs(to_uint(rd_addr1));
    end generate large_reg_file;

    small_reg_file: if (EMBEDDED = true) generate
        write_reg: process(clk)
        begin
            if rising_edge(clk) then
                regs(0) <= X0_DATA;
                if we = '1' then
                    if wr_addr /= X0_ADDR then
                        regs(to_uint(wr_addr(3 downto 0))) <= wr_data;
                    end if;
                end if;
            end if;
        end process write_reg;

        rd_data0 <= regs(to_uint(rd_addr0(3 downto 0)));
        rd_data1 <= regs(to_uint(rd_addr1(3 downto 0)));
    end generate small_reg_file;

end architecture reg_file_arch;