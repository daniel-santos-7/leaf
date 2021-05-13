library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity reg_file_tb is
end entity reg_file_tb;

architecture reg_file_tb_arch of reg_file_tb is
    
    signal clk, wr_reg_en: std_logic;
    signal rd_reg_addr0, rd_reg_addr1, wr_reg_addr: std_logic_vector(4 downto 0) := b"00000";
    signal wr_reg_data, rd_reg_data0, rd_reg_data1: std_logic_vector(31 downto 0);

    procedure tick(signal clk: out std_logic) is

    begin
        
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;

    end procedure;

begin
    
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

    process

    begin
        
        rd_reg_addr0 <= b"00000";
        rd_reg_addr1 <= b"00001";

        wr_reg_addr <= b"00000";
        wr_reg_data <= x"0000ffff";
        wr_reg_en <= '1';

        tick(clk);

        assert rd_reg_data0 = x"00000000" report "register reading failure" severity failure;
        assert rd_reg_data1 = x"00000000" report "register reading failure" severity failure;

        wr_reg_addr <= b"00001";
        wr_reg_data <= x"0000ffff";
        wr_reg_en <= '0';

        tick(clk);

        assert rd_reg_data0 = x"00000000" report "register write failure" severity failure;
        assert rd_reg_data1 = x"00000000" report "register write failure" severity failure;

        wr_reg_addr <= b"00001";
        wr_reg_data <= x"0000ffff";
        wr_reg_en <= '1';

        tick(clk);

        assert rd_reg_data0 = x"00000000" report "register write failure" severity failure;
        assert rd_reg_data1 = x"0000ffff" report "register write failure" severity failure;

        wait;

    end process;
    
end architecture reg_file_tb_arch;