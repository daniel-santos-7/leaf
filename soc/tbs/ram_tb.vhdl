library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.leaf_chip_pkg.all;

entity ram_tb is
end entity ram_tb;

architecture ram_tb_arch of ram_tb is
    
    signal clk: std_logic;
        
    signal rd_addr0:  std_logic_vector(10 downto 0);
    signal rd_data0:  std_logic_vector(31 downto 0);

    signal rd_addr1:  std_logic_vector(10 downto 0);
    signal rd_data1:  std_logic_vector(31 downto 0);

    signal wr_addr:     std_logic_vector(10 downto 0);
    signal wr_data:     std_logic_vector(31 downto 0);
    signal wr_byte_en:  std_logic_vector(3  downto 0);
    signal wr_en:       std_logic;

    procedure tick(signal clk: out std_logic) is

    begin
        
        clk <= '0';
        wait for 5 ns;
        
        clk <= '1';
        wait for 5 ns;

    end procedure;

begin

    uut: ram generic map (
        MEM_SIZE => 8192,
        ADDR_BITS => 13
    ) port map (
        clk        => clk,
        rd_addr0   => rd_addr0,
        rd_data0   => rd_data0,
        rd_addr1   => rd_addr1,
        rd_data1   => rd_data1,
        wr_addr    => wr_addr,
        wr_data    => wr_data,
        wr_byte_en => wr_byte_en,
        wr_en      => wr_en
    );

    test: process
    
    begin
        
        clk <= '0';

        rd_addr0   <= (others => '0');
        rd_addr1   <= (others => '0');
        wr_addr    <= (others => '0');
        wr_data    <= (others => '0');
        wr_byte_en <= (others => '0');
        wr_en      <= '0';

        tick(clk);

        wr_en   <= '1';
        wr_addr <= b"00000000001";
        wr_data <= x"1234ABCD";

        tick(clk);

        wr_en   <= '1';
        wr_addr <= b"00000000010";
        wr_data <= x"5678CDEF";

        tick(clk);

        rd_addr0 <= b"00000000001";
        rd_addr1 <= b"00000000010";

        tick(clk);

        assert rd_data0 = x"1234ABCD";
        assert rd_data1 = x"5678CDEF";

        tick(clk);

        wr_en   <= '1';
        wr_addr <= b"11111111111";
        wr_data <= x"AAAABBBB";

        tick(clk);

        rd_addr0 <= b"11111111111";
        rd_addr1 <= b"11111111111";

        tick(clk);
        
        assert rd_data0 = x"AAAABBBB";
        assert rd_data1 = x"AAAABBBB";

        -- --

        tick(clk);

        wr_en   <= '1';
        wr_addr <= b"11111111111";
        wr_data <= x"CCCCDDDD";
        wr_byte_en <= b"0001";

        tick(clk);

        rd_addr0 <= b"11111111111";
        rd_addr1 <= b"11111111111";

        tick(clk);
        
        assert rd_data0 = x"AAAABBDD";
        assert rd_data1 = x"AAAABBDD";

        tick(clk);

        wr_en   <= '1';
        wr_addr <= b"11111111111";
        wr_data <= x"CCCCDDDD";
        wr_byte_en <= b"0011";

        tick(clk);

        rd_addr0 <= b"11111111111";
        rd_addr1 <= b"11111111111";

        tick(clk);
        
        assert rd_data0 = x"AAAADDDD";
        assert rd_data1 = x"AAAADDDD";

        wait;

    end process test;
    
end architecture ram_tb_arch;