library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ram is
    
    generic (
        MEM_SIZE:  natural := 8192;  -- memory size 8kB
        ADDR_BITS: natural := 13     -- internal bus width address = log2(MEM_SIZE)
    );

    port (
        clk: in std_logic;
        
        -- read port 0 --

        rd_addr0: in  std_logic_vector(ADDR_BITS-3 downto 0);
        rd_data0: out std_logic_vector(31 downto 0);

        -- read port 1 --

        rd_addr1: in  std_logic_vector(ADDR_BITS-3 downto 0);
        rd_data1: out std_logic_vector(31 downto 0);

        -- write port --

        wr_addr:    in  std_logic_vector(ADDR_BITS-3 downto 0);
        wr_data:    in  std_logic_vector(31 downto 0);
        wr_byte_en: in  std_logic_vector(3  downto 0);
        wr_en:      in  std_logic
    );

end entity ram;

architecture ram_arch of ram is
    
    type data_array is array (0 to MEM_SIZE/4-1) of std_logic_vector(31 downto 0);

    signal data: data_array;

begin
    
    wr_ram: process(clk)
    
        variable addr: integer range 0 to MEM_SIZE/4-1;

    begin
       
        if rising_edge(clk) then

            if wr_en = '1' then
                
                addr := to_integer(unsigned(wr_addr));

                case wr_byte_en is
                
                    when b"0001" => 
                        
                        data(addr)(7 downto 0) <= wr_data(7 downto 0);
                        
                    when b"0011" => 
                    
                        data(addr)(7  downto 0) <= wr_data(7  downto 0);
                        data(addr)(15 downto 0) <= wr_data(15 downto 8);
                
                    when others => 
                    
                        data(addr) <= wr_data;
    
                end case;

            end if;

        end if;
        
    end process wr_ram;

    rd_ram0: process(rd_addr0, data)
    
        variable addr: integer range 0 to MEM_SIZE/4-1;

    begin
    
        addr := to_integer(unsigned(rd_addr0));

        rd_data0 <= data(addr);
        
    end process rd_ram0;

    rd_ram1: process(rd_addr1, data)
    
        variable addr: integer range 0 to MEM_SIZE/4-1;

    begin
                
        addr := to_integer(unsigned(rd_addr1));

        rd_data1 <= data(addr);

    end process rd_ram1;
    
end architecture ram_arch;