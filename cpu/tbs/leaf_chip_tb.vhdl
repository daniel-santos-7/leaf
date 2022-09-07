library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.leaf_chip_pkg.all;
use work.tbs_pkg.all;

entity leaf_chip_tb is
end entity leaf_chip_tb;

architecture leaf_chip_tb_arch of leaf_chip_tb is
    
    signal clk:   std_logic;
    signal reset: std_logic;
    signal rx:    std_logic;
    signal tx:    std_logic;

    type program is array (natural range<>) of std_logic_vector(31 downto 0);

    -- constant software: program := (
    --     x"04100293",
    --     x"02000313",
    --     x"00000393",
    --     x"00502623",
    --     x"00c02383",
    --     x"0203f393",
    --     x"fe731ce3",
    --     x"0000006f"
    -- );

    constant software: program := (
        x"04100293",
        x"00500623",
        x"0000006f"
    );

    constant UART_BAUD: natural := 434;

    procedure uart_tx(constant DATA: std_logic_vector(7 downto 0); signal clk: inout std_logic; signal rx: out std_logic) is

        variable frame: std_logic_vector(9 downto 0);

    begin

        frame := '1' & DATA & '0';

        for i in 0 to 9 loop
            
            rx <= frame(i);

            for j in 0 to UART_BAUD loop
                tick(clk);
            end loop;

        end loop;

    end procedure;

begin

    uut: leaf_chip port map (
        clk   => clk,
        reset => reset,
        rx    => rx,
        tx    => tx
    );

    test: process

        constant LOAD_CMD:     std_logic_vector(7 downto 0) := x"77";
        constant PROGRAM_SIZE: std_logic_vector(7 downto 0) := x"0C";
        
        variable instruction: std_logic_vector(31 downto 0);

    begin
        
        clk   <= '0';
        reset <= '1';
        rx    <= '1';

        wait for CLK_PERIOD;

        tick(clk);

        reset <= '0';

        tickn(clk, 10);

        uart_tx(LOAD_CMD, clk, rx);
        uart_tx(PROGRAM_SIZE, clk, rx);

        for i in 0 to software'length-1 loop
            
            instruction := software(i);

            for j in 0 to 3 loop
                uart_tx(instruction(8*j+7 downto j*8), clk, rx);
            end loop;

        end loop;

        while tx = '1' loop
            tick(clk);
        end loop;

        tickn(clk, 10*UART_BAUD);

        wait;

    end process test;
    
end architecture leaf_chip_tb_arch;