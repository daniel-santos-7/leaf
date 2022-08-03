----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;
use work.tbs_pkg.all;

entity reg_file_tb is
end entity reg_file_tb;

architecture reg_file_tb_arch of reg_file_tb is
    
    -- uut signals --

    signal clk          : std_logic;
    signal wr_reg_en    : std_logic;
    signal rd_reg_addr0 : std_logic_vector(4  downto 0);
    signal rd_reg_addr1 : std_logic_vector(4  downto 0);
    signal wr_reg_addr  : std_logic_vector(4  downto 0);
    signal wr_reg_data  : std_logic_vector(31 downto 0);
    signal rd_reg_data0 : std_logic_vector(31 downto 0);
    signal rd_reg_data1 : std_logic_vector(31 downto 0);

begin
    
    -- unit under test --

    uut: reg_file port map (
        clk,
        rd_reg_addr0, 
        rd_reg_addr1, 
        wr_reg_addr,
        wr_reg_data,
        wr_reg_en,
        rd_reg_data0, 
        rd_reg_data1
    );

    test: process
    begin

        -- x0/zero and x1 --

        rd_reg_addr0    <= b"00000";
        rd_reg_addr1    <= b"00001";

        -- it shouldn't write x0 --
        
        wr_reg_addr <= b"00000";
        wr_reg_data <= x"0000FFFF";
        wr_reg_en   <= '1';

        tick(clk);

        assert rd_reg_data0 = x"00000000" report "expected: x0 = 0x00000000" severity note;

        -- it shouldn't write x1 --

        wr_reg_addr <= b"00001";
        wr_reg_data <= x"0000FFFF";
        wr_reg_en   <= '0';

        tick(clk);

        assert rd_reg_data0 = x"00000000" report "expected: x0 = 0x00000000" severity note;

        -- it should write x1 --

        wr_reg_addr <= b"00001";
        wr_reg_data <= x"0000FFFF";
        wr_reg_en   <= '1';

        tick(clk);

        assert rd_reg_data0 = x"00000000" report "expected: x0 = 0x00000000" severity note;
        assert rd_reg_data1 = x"0000FFFF" report "expected: x1 = 0x0000FFFF" severity note;

        wait;
    end process test;
    
end architecture reg_file_tb_arch;