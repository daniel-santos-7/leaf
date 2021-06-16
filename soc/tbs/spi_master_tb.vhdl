library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.leaf_chip_pkg.all;

entity spi_master_tb is
end entity spi_master_tb;

architecture spi_master_tb_arch of spi_master_tb is
    
    signal clk:   std_logic;
    signal reset: std_logic;

    signal en: std_logic;
    signal tx_data: std_logic_vector(7 downto 0);
    signal rx_data: std_logic_vector(7 downto 0);

    signal busy:  std_logic;
    signal done:  std_logic;

    signal cpol:  std_logic;
    signal cpha:  std_logic;

    signal sdo:  std_logic;
    signal sdi:  std_logic;
    signal sclk: std_logic;
    signal cs:   std_logic;

    signal slave_data:  std_logic_vector(7 downto 0) := x"AB";

    procedure tick(signal clk: out std_logic) is

    begin
        
        clk <= '0';
        wait for 500 ns;
        
        clk <= '1';
        wait for 500 ns;

    end procedure;

begin

    uut: spi_master port map (
        clk        => clk,
        reset      => reset,
        en         => en,
        tx_data    => tx_data,
        rx_data    => rx_data,
        busy       => busy,
        done       => done,
        cpol       => cpol,
        cpha       => cpha,
        sdo        => sdo,
        sdi        => sdi,
        sclk       => sclk,
        cs         => cs
    );

    slave: process(sclk)
    
    begin

        if cs = '0' then
            
            if rising_edge(sclk) then
            
                sdi <= slave_data(7);
    
            end if;
    
            if falling_edge(sclk) then
                
                slave_data <= slave_data(6 downto 0) & sdo;

            end if;

        else

            sdi <= '0';

        end if;

    end process slave;

    test: process
    
    begin
        
        clk     <= '0';
        reset   <= '1';
        en      <= '0';
        tx_data <= (others => '0');
        cpol    <= '0';
        cpha    <= '0';
        
        tick(clk);

        reset <= '0';

        tick(clk);

        en      <= '1';
        tx_data <= x"89";

        while done /= '1' loop

            tick(clk);

        end loop;

        tick(clk);

        wait;

    end process test;
    
end architecture spi_master_tb_arch;