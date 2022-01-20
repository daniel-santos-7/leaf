library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity int_strg_tb is 
end int_strg_tb;

architecture int_strg_tb_arch of int_strg_tb is

    signal clk:        std_logic;
    signal wr_en:      std_logic;
    signal wr_addr:    std_logic_vector(4  downto 0);
    signal wr_src0:    std_logic_vector(31 downto 0);
    signal wr_src1:    std_logic_vector(31 downto 0);
    signal wr_src2:    std_logic_vector(31 downto 0);
    signal wr_src3:    std_logic_vector(31 downto 0);
    signal wr_src_sel: std_logic_vector(1  downto 0);
    signal rd_addr0:   std_logic_vector(4  downto 0);
    signal rd_addr1:   std_logic_vector(4  downto 0);
    signal rd_data0:   std_logic_vector(31 downto 0);
    signal rd_data1:   std_logic_vector(31 downto 0);

begin
    
    uut: int_strg port map (
        clk        => clk,
        wr_en      => wr_en,
        wr_addr    => wr_addr,
        wr_src0    => wr_src0,
        wr_src1    => wr_src1,
        wr_src2    => wr_src2,
        wr_src3    => wr_src3,
        wr_src_sel => wr_src_sel,
        rd_addr0   => rd_addr0,
        rd_addr1   => rd_addr1,
        rd_data0   => rd_data0,
        rd_data1   => rd_data1
    );

    test: process

        constant period: time := 50 ns;

        begin
            
            clk        <= '0';
            wr_en      <= '0';
            wr_addr    <= (others => '0');
            wr_src0    <= (others => '0');
            wr_src1    <= (others => '0');
            wr_src2    <= (others => '0');
            wr_src3    <= (others => '0');
            wr_src_sel <= (others => '0');
            rd_addr0   <= (others => '0');
            rd_addr1   <= (others => '0');
            rd_data0   <= (others => '0');
            rd_data1   <= (others => '0');

            wait for period;

            wait;

    end process test;
    
end architecture int_strg_tb_arch;