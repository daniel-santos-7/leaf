library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.leaf_chip_pkg.all;

entity leaf_chip_tb is
end entity leaf_chip_tb;

architecture leaf_chip_tb_arch of leaf_chip_tb is
    
    signal clk:   std_logic;
    signal reset: std_logic;
    signal rx:    std_logic;
    signal tx:    std_logic;

    constant PERIOD: time := 20 ns;

    type program is array (natural range<>) of std_logic_vector(31 downto 0);

    constant software: program := (
        x"04100293",
        x"0ff00313",
        x"00000393",
        x"00502623",
        x"00002383",
        x"0083d393",
        x"fe731ce3"
    );

begin

    uut: leaf_chip port map (
        clk   => clk,
        reset => reset,
        rx    => rx,
        tx    => tx
    );

    test: process

        constant LOAD_CMD:     std_logic_vector(7 downto 0) := x"77";
        constant PROGRAM_SIZE: std_logic_vector(7 downto 0) := x"1C";

        variable tx_frame:    std_logic_vector(9 downto 0);
        variable instruction: std_logic_vector(31 downto 0);

    begin
        
        reset <= '1';
        rx    <= '1';

        clk <= '0';
        wait for PERIOD/2;

        clk <= '1';
        wait for PERIOD/2;

        reset <= '0';

        for i in 0 to 2*UART_BAUD loop
                
            clk <= not clk;
            wait for PERIOD/2;

        end loop;

        tx_frame := '1' & LOAD_CMD & '0';

        for i in 0 to 9 loop
        
            rx <= tx_frame(i);

            for j in 0 to 2*uart_baud loop
                
                clk <= not clk;
                wait for PERIOD/2;

            end loop;

        end loop;

        tx_frame := '1' & PROGRAM_SIZE & '0';

        for i in 0 to 9 loop
        
            rx <= tx_frame(i);

            for j in 0 to 2*uart_baud loop
                
                clk <= not clk;
                wait for PERIOD/2;

            end loop;

        end loop;

        for i in 0 to 6 loop
            
            instruction := software(i);

            for j in 0 to 3 loop
                
                tx_frame := '1' & instruction(8*j+7 downto j*8) & '0';

                for i in 0 to 9 loop
        
                    rx <= tx_frame(i);
        
                    for j in 0 to 2*uart_baud loop
                        
                        clk <= not clk;
                        wait for PERIOD/2;
        
                    end loop;
        
                end loop;

            end loop;

        end loop;

        for i in 0 to 2*UART_BAUD loop
            
            clk <= not clk;
            wait for PERIOD/2;

        end loop;

        for i in 0 to 12*UART_BAUD loop
        
            clk <= not clk;
            wait for PERIOD/2;

        end loop;

        wait;

    end process test;
    
end architecture leaf_chip_tb_arch;