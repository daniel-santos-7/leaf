library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity lsu_tb is 
end lsu_tb;

architecture lsu_tb_arch of lsu_tb is

    signal rd_mem_data: std_logic_vector(31 downto 0);
    signal wr_data: std_logic_vector(31 downto 0);
    signal data_type: std_logic_vector(2 downto 0);
    signal mode, en: std_logic;
    signal rd_mem_en, wr_mem_en: std_logic;
    signal wr_mem_data: std_logic_vector(31 downto 0);
    signal rd_data: std_logic_vector(31 downto 0);

begin
    
    uut: lsu port map (
        rd_mem_data,
        wr_data,
        data_type,
        mode, 
        en,
        rd_mem_en, 
        wr_mem_en,
        wr_mem_data,
        rd_data
    );

    process

        constant period: time := 10 ns;

        begin

            rd_mem_data <= x"0000_FFFF";
            wr_data <= x"FFFF_0000";
            
            data_type <= b"000";
            mode <= '0';
            en <= '0';

            wait for period;
            
            assert (rd_mem_en = '0');
            assert (wr_mem_en = '0');
            assert (wr_mem_data = x"0000_0000");
            assert (rd_data = x"0000_0000");

            data_type <= b"010";
            mode <= '0';
            en <= '1';

            wait for period;
            
            assert (rd_mem_en = '1');
            assert (wr_mem_en = '0');
            assert (wr_mem_data = x"0000_0000");
            assert (rd_data = x"0000_FFFF");

            data_type <= b"010";
            mode <= '1';
            en <= '1';

            wait for period;
            
            assert (rd_mem_en = '0');
            assert (wr_mem_en = '1');
            assert (wr_mem_data = x"FFFF_0000");
            assert (rd_data = x"0000_0000");

            wait;

    end process;
    
end architecture lsu_tb_arch;