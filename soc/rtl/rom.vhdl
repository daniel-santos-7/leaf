library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity rom is
    
    generic (
        MEM_SIZE:  natural := 256;
        ADDR_BITS: natural := 8
    );

    port (
        rd_addr: in  std_logic_vector(ADDR_BITS-3  downto 0);
        rd_data: out std_logic_vector(31 downto 0)
    );

end entity rom;

architecture rom_arch of rom is
    
    type data_array is array (0 to MEM_SIZE/4-1) of std_logic_vector(31 downto 0);

    constant boot_data: data_array := (
        0  => x"00000013",
        1  => x"fff00293",
        2  => x"02c000ef",
        3  => x"fea29ce3",
        4  => x"00000313",
        5  => x"10000393",
        6  => x"02730e63",
        7  => x"018000ef",
        8  => x"fff00393",
        9  => x"02750863",
        10 => x"20a32023",
        11 => x"00430313",
        12 => x"fe5ff06f",
        13 => x"00000e13",
        14 => x"01c02423",
        15 => x"fff00e13",
        16 => x"00000e93",
        17 => x"00402e83",
        18 => x"ffce9ee3",
        19 => x"00802503",
        20 => x"00008067",
        21 => x"00000093",
        22 => x"00000113",
        23 => x"00000193",
        24 => x"00000213",
        25 => x"00000293",
        26 => x"00000313",
        27 => x"00000393",
        28 => x"00000413",
        29 => x"00000493",
        30 => x"00000513",
        31 => x"00000593",
        32 => x"00000613",
        33 => x"00000693",
        34 => x"00000713",
        35 => x"00000793",
        36 => x"00000813",
        37 => x"00000893",
        38 => x"00000913",
        39 => x"00000993",
        40 => x"00000a13",
        41 => x"00000a93",
        42 => x"00000b13",
        43 => x"00000b93",
        44 => x"00000c13",
        45 => x"00000c93",
        46 => x"00000d13",
        47 => x"00000d93",
        48 => x"00000e13",
        49 => x"00000e93",
        50 => x"00000f13",
        51 => x"00000f93",
        52 => x"0300006f",
        others => x"00000013"
    );

begin
    
    rd_rom: process(rd_addr)
    
        variable addr: integer range 0 to MEM_SIZE/4-1;

    begin
                
        addr := to_integer(unsigned(rd_addr));

        rd_data <= boot_data(addr);

    end process rd_rom;
    
end architecture rom_arch;