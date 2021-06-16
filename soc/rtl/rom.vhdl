library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity rom is
    
    generic (
        MEM_SIZE:  natural := 1024;
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
        0000 =>	x"00000013",
        0001 =>	x"fff00293",
        0002 =>	x"030000ef",
        0003 =>	x"fea29ce3",
        0004 =>	x"00001337",
        0005 =>	x"90030313",
        0006 =>	x"000023b7",
        0007 =>	x"04730263",
        0008 =>	x"018000ef",
        0009 =>	x"fff00393",
        0010 =>	x"02750c63",
        0011 =>	x"70a32023",
        0012 =>	x"00430313",
        0013 =>	x"fe5ff06f",
        0014 =>	x"00000e13",
        0015 =>	x"01c02423",
        0016 =>	x"00800e13",
        0017 =>	x"01c02023",
        0018 =>	x"fff00e13",
        0019 =>	x"00000e93",
        0020 =>	x"00402e83",
        0021 =>	x"ffce9ee3",
        0022 =>	x"00802503",
        0023 =>	x"00008067",
        0024 =>	x"00000093",
        0025 =>	x"00000113",
        0026 =>	x"00000193",
        0027 =>	x"00000213",
        0028 =>	x"00000293",
        0029 =>	x"00000313",
        0030 =>	x"00000393",
        0031 =>	x"00000413",
        0032 =>	x"00000493",
        0033 =>	x"00000513",
        0034 =>	x"00000593",
        0035 =>	x"00000613",
        0036 =>	x"00000693",
        0037 =>	x"00000713",
        0038 =>	x"00000793",
        0039 =>	x"00000813",
        0040 =>	x"00000893",
        0041 =>	x"00000913",
        0042 =>	x"00000993",
        0043 =>	x"00000a13",
        0044 =>	x"00000a93",
        0045 =>	x"00000b13",
        0046 =>	x"00000b93",
        0047 =>	x"00000c13",
        0048 =>	x"00000c93",
        0049 =>	x"00000d13",
        0050 =>	x"00000d93",
        0051 =>	x"00000e13",
        0052 =>	x"00000e93",
        0053 =>	x"00000f13",
        0054 =>	x"00000f93",
        0055 =>	x"6250006f",
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