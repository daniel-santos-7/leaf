library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.leaf_chip_pkg.all;

entity leaf_chip_tb is
end entity leaf_chip_tb;

architecture leaf_chip_tb_arch of leaf_chip_tb is
    
    signal clk:   std_logic;
    signal reset: std_logic;

    signal rx:  std_logic;
    signal tx:  std_logic;

    constant period: time := 20 ns;

    type program is array (natural range<>) of std_logic_vector(31 downto 0);

    constant test_program: program := (
        0 =>	x"00000013",
        1 =>	x"04800593",
        2 =>	x"024000ef",
        3 =>	x"04500593",
        4 =>	x"01c000ef",
        5 =>	x"04c00593",
        6 =>	x"014000ef",
        7 =>	x"04c00593",
        8 =>	x"00c000ef",
        9 =>	x"04f00593",
        10 =>	x"004000ef",
        11 =>	x"00b02423",
        12 =>	x"fff00e13",
        13 =>	x"00402e83",
        14 =>	x"ffce9ee3",
        15 =>	x"00802503",
        16 =>	x"00008067"
    );

begin

    uut: leaf_chip port map (
        clk   => clk,
        reset => reset,
        rx    => rx,
        tx    => tx
    );

    test: process

        constant load_cmd: std_logic_vector(31 downto 0) := x"00000077";
        constant uart_baud: integer := 5208;
        variable tx_frame: std_logic_vector(9 downto 0);

    begin
        
        reset <= '1';
        rx    <= '1';

        clk <= '0';
        wait for period/2;

        clk <= '1';
        wait for period/2;

        reset <= '0';
      
        tx_frame := '1' & load_cmd(7 downto 0) & '0';

        for i in 0 to 9 loop
        
            rx <= tx_frame(i);

            for j in 0 to 2*uart_baud loop
                
            clk <= not clk;
            wait for period/2;

            end loop;

        end loop;

        tx_frame := '1' & load_cmd(15 downto 8) & '0';

        for i in 0 to 9 loop
        
            rx <= tx_frame(i);

            for j in 0 to 2*uart_baud loop
                
            clk <= not clk;
            wait for period/2;

            end loop;

        end loop;

        wait;

    end process test;
    
end architecture leaf_chip_tb_arch;