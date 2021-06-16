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
        0  =>	x"0c800293",
        1  =>	x"12c00313",
        2  =>	x"006283b3",
        3  =>	x"007005b3",
        4  =>	x"004000ef",
        5  =>	x"00b02423",
        6  =>	x"00800e13",
        7  =>	x"01c02023",
        8  =>	x"fff00e13",
        9  =>	x"00402e83",
        10 =>	x"01ce9063",
        11 =>	x"00802503",
        12 =>	x"00008067"
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

               report integer'image(bit_count);
    
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

        while slave_data /=x"000001F4"  loop

            tick(clk);

        end loop;

        wait;

    end process test;
    
end architecture leaf_chip_tb_arch;