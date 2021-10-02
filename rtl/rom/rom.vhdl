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
        0 =>    x"00000293",
        1 =>    x"00000313",
        2 =>    x"00000393",
        3 =>    x"00000e13",
        4 =>   x"07700293",
        5 =>   x"00000097",
        6 =>   x"000080e7",
        7 =>   x"fea29ae3",
        8 =>   x"00000097",
        9 =>   x"000080e7",
        10 =>   x"00050293",
        11 =>   x"10000313",
        12 =>   x"00537463",
        13 =>   x"fddff06f",
        14 =>   x"00000313",
        15 =>   x"00000097",
        16 =>   x"000080e7",
        17 =>   x"20a32023",
        18 =>   x"00430313",
        19 =>   x"fe5368e3",
        20 =>   x"00000093",
        21 =>   x"00000113",
        22 =>   x"00000193",
        23 =>   x"00000213",
        24 =>   x"00000293",
        25 =>   x"00000313",
        26 =>   x"00000393",
        27 =>   x"00000413",
        28 =>   x"00000493",
        29 =>   x"00000513",
        30 =>   x"00000593",
        31 =>   x"00000613",
        32 =>   x"00000693",
        33 =>   x"00000713",
        34 =>   x"00000793",
        35 =>   x"00000813",
        36 =>   x"00000893",
        37 =>   x"00000913",
        38 =>   x"00000993",
        39 =>   x"00000a13",
        40 =>   x"00000a93",
        41 =>   x"00000b13",
        42 =>   x"00000b93",
        43 =>   x"00000c13",
        44 =>   x"00000c93",
        45 =>   x"00000d13",
        46 =>   x"00000d93",
        47 =>   x"00000e13",
        48 =>   x"00000e93",
        49 =>   x"00000f13",
        50 =>   x"00000f93",
        51 =>   x"0000006f",
        52 =>   x"00000393",
        53 =>   x"00f00e13",
        54 =>   x"00002383",
        55 =>   x"01c3f3b3",
        56 =>   x"ffc39ce3",
        57 =>   x"00802503",
        58 =>   x"00008067",
        others => x"00000013"
    );

begin
    
    rd_data <= boot_data(to_integer(unsigned(rd_addr)));
    
end architecture rom_arch;