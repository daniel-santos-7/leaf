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
        0 => x"00000293",
        1 => x"00000313",
        2 => x"00000393",
        3 => x"00000e13",
        4 => x"07700293",
        5 => x"00000097",
        6 => x"000080e7",
        7 => x"fea29ae3",
        8 => x"00000097",
        9 => x"000080e7",
        10 => x"00050293",
        11 => x"10000313",
        12 => x"00537463",
        13 => x"fddff06f",
        14 => x"00000313",
        15 => x"00000097",
        16 => x"000080e7",
        17 => x"20a32023",
        18 => x"00430313",
        19 => x"fe5368e3",
        20 => x"0000006f",
        21 => x"00000393",
        22 => x"0ff00e13",
        23 => x"00000383",
        24 => x"ffc39ee3",
        25 => x"00802503",
        26 => x"00008067",
        27 => x"00400e93",
        28 => x"fff00e93",
        29 => x"00000097",
        30 => x"000080e7",
        31 => x"008f1f13",
        32 => x"00af0f33",
        33 => x"fe0e96e3",
        34 => x"01e00533",
        35 => x"00008067",
        others => x"00000013"
    );

begin
    
    rd_data <= boot_data(to_integer(unsigned(rd_addr)));
    
end architecture rom_arch;