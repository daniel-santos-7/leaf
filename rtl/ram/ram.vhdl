----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: ram
-- description: dual ported ram
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ram is
    generic (
        BITS: natural := 8
    );

    port (
        clk: in std_logic;
        
        rd_addr0: in  std_logic_vector(BITS-3 downto 0);
        rd_data0: out std_logic_vector(31 downto 0);

        rd_addr1: in  std_logic_vector(BITS-3 downto 0);        
        rd_data1: out std_logic_vector(31 downto 0);

        wr_addr:    in  std_logic_vector(BITS-3 downto 0);
        wr_data:    in  std_logic_vector(31 downto 0);
        wr_byte_en: in  std_logic_vector(3  downto 0);
        wr:         in  std_logic;
    );
end entity ram;

architecture ram_arch of ram is
    
    constant MEM_SIZE: natural := 2**BITS;

    type mem_array is array (0 to MEM_SIZE/4-1) of std_logic_vector(7 downto 0);

    signal mem0: mem_array;
    signal mem1: mem_array;
    signal mem2: mem_array;
    signal mem3: mem_array;

begin
    
    wr_ram: process(clk)
    
        variable addr: integer range 0 to MEM_SIZE/4-1;

        variable mem0_wr: std_logic;
        variable mem1_wr: std_logic;
        variable mem2_wr: std_logic;
        variable mem3_wr: std_logic;

    begin

        if rising_edge(clk) then

            addr := to_integer(unsigned(wr_addr));

            mem0_wr := wr_byte_en(0);
            mem1_wr := wr_byte_en(1);
            mem2_wr := wr_byte_en(2);
            mem3_wr := wr_byte_en(3);

            if we = '1' then
                    
                if mem0_wr = '1' then

                    mem0(addr) <= wr_data(7  downto 0);

                end if;

                if mem1_wr = '1' then

                    mem1(addr) <= wr_data(15 downto 8);

                end if;

                if mem2_wr = '1' then

                    mem2(addr) <= wr_data(23 downto 16);

                end if;

                if mem3_wr = '1' then

                    mem3(addr) <= wr_data(31 downto 24);
                    
                end if;
    
            end if;

        end if;
        
    end process wr_ram;

    rd_data0(7  downto  0)  <= mem0(to_integer(unsigned(rd_addr0)));
    rd_data0(15 downto  8)  <= mem1(to_integer(unsigned(rd_addr0)));
    rd_data0(23 downto 16)  <= mem2(to_integer(unsigned(rd_addr0)));
    rd_data0(31 downto 24)  <= mem3(to_integer(unsigned(rd_addr0)));

    rd_data1(7  downto  0)  <= mem0(to_integer(unsigned(rd_addr1)));
    rd_data1(15 downto  8)  <= mem1(to_integer(unsigned(rd_addr1)));
    rd_data1(23 downto 16)  <= mem2(to_integer(unsigned(rd_addr1)));
    rd_data1(31 downto 24)  <= mem3(to_integer(unsigned(rd_addr1)));        
    
end architecture ram_arch;