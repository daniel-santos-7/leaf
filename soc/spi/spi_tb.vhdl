library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.leaf_chip_pkg.all;

entity spi_tb is
end entity spi_tb;

architecture spi_tb_arch of spi_tb is
    
    signal clk:   std_logic;
    signal reset: std_logic;
        
    signal rd_addr:  std_logic_vector(1 downto 0);
    signal rd_data:  std_logic_vector(31 downto 0);

    signal wr_addr:    std_logic_vector(1 downto 0);
    signal wr_data:    std_logic_vector(31 downto 0);
    signal wr_byte_en: std_logic_vector(3  downto 0);
    signal wr_en:      std_logic;

    signal sdo:  std_logic;
    signal sdi:  std_logic;
    signal sclk: std_logic;
    signal cs:   std_logic;

    signal slave_data: std_logic_vector(31 downto 0) := x"6789CDEF";

    procedure tick(signal clk: out std_logic) is

    begin
        
        clk <= '0';
        wait for 500 ns;
        
        clk <= '1';
        wait for 500 ns;

    end procedure;

begin

    uut: spi port map (
        clk        => clk,
        reset      => reset,
        rd_addr    => rd_addr,
        rd_data    => rd_data,
        wr_addr    => wr_addr,
        wr_data    => wr_data,
        wr_byte_en => wr_byte_en,
        wr_en      => wr_en,
        sdo        => sdo,
        sdi        => sdi,
        sclk       => sclk,
        cs         => cs
    );

    slave: process(sclk)
    
    begin

        if rising_edge(sclk) and cs = '0' then
            
            sdi <= slave_data(31);

        end if;

        if falling_edge(sclk) and cs = '0' then
            
            slave_data <= slave_data(30 downto 0) & sdo;

        end if;

    end process slave;

    test: process
    
        variable status_reg: std_logic_vector(31 downto 0);

    begin
        
        clk        <= '0';
        reset      <= '1';
        rd_addr    <= (others => '0');
        wr_addr    <= (others => '0');
        wr_data    <= (others => '0');
        wr_byte_en <= (others => '0');
        wr_en      <= '0';

        tick(clk);

        reset <= '0';

        tick(clk);

        wr_addr     <= b"10";
        wr_data     <= x"1234ABCD";
        wr_byte_en  <= b"1111";

        wr_en <= '1';

        tick(clk);

        wr_addr     <= b"00";
        wr_data     <= x"00000000";
        wr_byte_en  <= b"1111";

        wr_en <= '0';

        rd_addr <= b"01";

        tick(clk);

        while rd_data /= x"FFFFFFFF" loop

            rd_addr <= b"01";

            tick(clk);

        end loop;

        rd_addr <= b"10";

        tick(clk);

        assert rd_data = x"6789CDEF";

        wait;

    end process test;
    
end architecture spi_tb_arch;