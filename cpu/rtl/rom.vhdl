----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: fifo
-- description: boot read-only memory
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity rom is
    generic (
        BITS: natural := 8
    );
    port (
        rd:      in std_logic;
        rd_addr: in  std_logic_vector(BITS-3  downto 0);
        rd_data: out std_logic_vector(31 downto 0)
    );
end entity rom;

architecture rom_arch of rom is
    
    type mem_array is array (0 to 2**BITS/4-1) of std_logic_vector(31 downto 0);

    constant mem: mem_array := (
        x"00000293",
        x"00000313",
        x"00000393",
        x"00000e13",
        x"1b200293",
        x"00501423",
        x"07700293",
        x"034000ef",
        x"fea29ce3",
        x"02c000ef",
        x"00050293",
        x"10000313",
        x"00537463",
        x"fe5ff06f",
        x"00000313",
        x"014000ef",
        x"20a30023",
        x"00130313",
        x"fe536ae3",
        x"0b40006f",
        x"00000393",
        x"00400e13",
        x"00004383",
        x"0043f393",
        x"ffc39ce3",
        x"00c02503",
        x"00008067",
        others => x"00000013"
    );

begin
    
    main: process(rd, rd_addr)
    begin
        
        if rd = '1' then

            rd_data <= mem(to_integer(unsigned(rd_addr)));

        else

            rd_data <= (others => '0');
            
        end if;

    end process main;
    
end architecture rom_arch;