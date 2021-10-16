library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ram is
    
    generic (
        MEM_SIZE:  natural := 256;  -- memory size 256B
        ADDR_BITS: natural := 8     -- internal bus width address = log2(MEM_SIZE)
    );

    port (
        clk: in std_logic;
        
        -- read port 0 --

        rd_addr0: in  std_logic_vector(ADDR_BITS-1 downto 0);
        rd_data0: out std_logic_vector(31 downto 0);

        -- read port 1 --

        rd_addr1: in  std_logic_vector(ADDR_BITS-1 downto 0);
        rd_data1: out std_logic_vector(31 downto 0);

        -- write port --

        wr_addr:    in  std_logic_vector(ADDR_BITS-1 downto 0);
        wr_data:    in  std_logic_vector(31 downto 0);
        wr_byte_en: in  std_logic_vector(3  downto 0);
        wr_en:      in  std_logic
    );

end entity ram;

architecture ram_arch of ram is
    
    type memory_array is array (0 to MEM_SIZE-1) of std_logic_vector(7 downto 0);

    signal memory: memory_array;

begin
    
    wr_ram: process(clk)
    
        variable addr: integer range 0 to MEM_SIZE-1;

    begin
       
        if rising_edge(clk) then

            if wr_en = '1' then
                
                case wr_byte_en is
                
                    when b"0001" => 

                        addr := to_integer(unsigned(wr_addr));
                        
                        memory(addr) <= wr_data(7 downto 0);
                        
                    when b"0011" => 
                    
                        addr := to_integer(unsigned(wr_addr));
                    
                        memory(addr + 0) <= wr_data(7  downto 0);
                        memory(addr + 1) <= wr_data(15 downto 8);
                
                    when others => 

                        addr := to_integer(unsigned(wr_addr));
                    
                        memory(addr + 0) <= wr_data(7  downto 0);
                        memory(addr + 1) <= wr_data(15 downto 8);
                        memory(addr + 2) <= wr_data(23 downto 16);
                        memory(addr + 3) <= wr_data(31 downto 24);
    
                end case;

            end if;

        end if;
        
    end process wr_ram;

    rd_data0(7  downto  0)  <= memory(to_integer(unsigned(rd_addr0) + 0));
    rd_data0(15 downto  8)  <= memory(to_integer(unsigned(rd_addr0) + 1));
    rd_data0(23 downto 16)  <= memory(to_integer(unsigned(rd_addr0) + 2));
    rd_data0(31 downto 24)  <= memory(to_integer(unsigned(rd_addr0) + 3));

    rd_data1(7  downto  0)  <= memory(to_integer(unsigned(rd_addr1) + 0));
    rd_data1(15 downto  8)  <= memory(to_integer(unsigned(rd_addr1) + 1));
    rd_data1(23 downto 16)  <= memory(to_integer(unsigned(rd_addr1) + 2));
    rd_data1(31 downto 24)  <= memory(to_integer(unsigned(rd_addr1) + 3));        
    
end architecture ram_arch;