library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.leaf_chip_pkg.all;

entity leaf_chip_tb is
end entity leaf_chip_tb;

architecture leaf_chip_tb_arch of leaf_chip_tb is
    
    signal clk:   std_logic;
    signal reset: std_logic;

    signal sdo:  std_logic;
    signal sdi:  std_logic;
    signal sclk: std_logic;
    signal cs:   std_logic;

    type program is array (natural range<>) of std_logic_vector(31 downto 0);

    constant hello_program: program := (
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

    signal slave_data:  std_logic_vector(31 downto 0) := (others => '1');

    procedure tick(signal clk: out std_logic) is

    begin
        
        clk <= '0';
        wait for 500 ns;
        
        clk <= '1';
        wait for 500 ns;

    end procedure;

begin

    uut: leaf_chip port map (
        clk        => clk,
        reset      => reset,
        sdo        => sdo,
        sdi        => sdi,
        sclk       => sclk,
        cs         => cs
    );

    spi_slave: process(cs, sclk)
        
        variable instr_count: integer := 0;
        variable bit_count:   integer := 0;

    begin

        if cs = '0' then
            
            if rising_edge(sclk) then
            
                sdi <= slave_data(31);

                bit_count := bit_count + 1;

            end if;
    
            if falling_edge(sclk) then
                
                slave_data <= slave_data(30 downto 0) & sdo;

            end if;

        else

            if bit_count = 32 then
                
                if instr_count < hello_program'length then
                
                    slave_data <= hello_program(instr_count);
    
                else
    
                    slave_data <= (others => '1');
    
                end if;

                instr_count := instr_count + 1;

                bit_count := 0;

            end if;

            sdi <= '0';

        end if;

    end process spi_slave;

    test: process
    
    begin
        
        clk     <= '0';
        reset   <= '1';
        
        tick(clk);

        reset <= '0';

        tick(clk);

        while slave_data /=x"00000048"  loop

            tick(clk);

        end loop;

        while slave_data /=x"00000045"  loop

            tick(clk);

        end loop;

        while slave_data /=x"0000004C"  loop

            tick(clk);

        end loop;

        while slave_data /=x"0000004C"  loop

            tick(clk);

        end loop;

        while slave_data /=x"0000004F"  loop

            tick(clk);

        end loop;

        wait;

    end process test;
    
end architecture leaf_chip_tb_arch;