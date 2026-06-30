----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: register file
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_pkg.all;

entity reg_file is
    generic (
        SIZE : natural := 32
    );
    port (
        clk_i      : in  std_logic;
        we_i       : in  std_logic;
        wr_sel_i   : in  std_logic_vector(1 downto 0);
        wr_addr_i  : in  std_logic_vector(4  downto 0);
        wr_data0_i : in  std_logic_vector(XLEN-1 downto 0);
        wr_data1_i : in  std_logic_vector(XLEN-1 downto 0);
        wr_data2_i : in  std_logic_vector(XLEN-1 downto 0);
        wr_data3_i : in  std_logic_vector(XLEN-1 downto 0);
        rd_addr0_i : in  std_logic_vector(4  downto 0);
        rd_addr1_i : in  std_logic_vector(4  downto 0);
        rd_data0_o : out std_logic_vector(XLEN-1 downto 0);
        rd_data1_o : out std_logic_vector(XLEN-1 downto 0)
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

    wr_data_mux: process(wr_sel_i, wr_data0_i, wr_data1_i, wr_data2_i, wr_data3_i)
    begin
        case wr_sel_i is
            when b"00" => wr_data <= wr_data0_i;
            when b"01" => wr_data <= wr_data1_i;
            when b"10" => wr_data <= wr_data2_i;
            when b"11" => wr_data <= wr_data3_i;
            when others => wr_data <= (others => '-');
        end case;
    end process wr_data_mux;

    large_reg_file: if (EMBEDDED = false) generate
        write_reg: process(clk_i)
        begin
            if rising_edge(clk_i) then
                regs(0) <= X0_DATA;
                if we_i = '1' then
                    if wr_addr_i /= X0_ADDR then
                        regs(to_uint(wr_addr_i)) <= wr_data;
                    end if;
                end if;
            end if;
        end process write_reg;

        rd_data0_o <= wr_data when (we_i = '1' and wr_addr_i = rd_addr0_i and rd_addr0_i /= X0_ADDR)
                      else regs(to_uint(rd_addr0_i));
        rd_data1_o <= wr_data when (we_i = '1' and wr_addr_i = rd_addr1_i and rd_addr1_i /= X0_ADDR)
                      else regs(to_uint(rd_addr1_i));
    end generate large_reg_file;

    small_reg_file: if (EMBEDDED = true) generate
        write_reg: process(clk_i)
        begin
            if rising_edge(clk_i) then
                regs(0) <= X0_DATA;
                if we_i = '1' then
                    if wr_addr_i /= X0_ADDR then
                        regs(to_uint(wr_addr_i(3 downto 0))) <= wr_data;
                    end if;
                end if;
            end if;
        end process write_reg;

        rd_data0_o <= wr_data when (we_i = '1' and wr_addr_i(3 downto 0) = rd_addr0_i(3 downto 0) and rd_addr0_i(3 downto 0) /= "0000")
                      else regs(to_uint(rd_addr0_i(3 downto 0)));
        rd_data1_o <= wr_data when (we_i = '1' and wr_addr_i(3 downto 0) = rd_addr1_i(3 downto 0) and rd_addr1_i(3 downto 0) /= "0000")
                      else regs(to_uint(rd_addr1_i(3 downto 0)));
    end generate small_reg_file;

end architecture reg_file_arch;
