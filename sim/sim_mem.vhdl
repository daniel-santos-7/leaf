library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sim_mem is
    generic (
        BITS    : natural := 8;
        PROGRAM : string
    );
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        wr_en      : in  std_logic;
        rd_en      : in  std_logic;
        wr_byte_en : in  std_logic_vector(3  downto 0);
        wr_data1   : in  std_logic_vector(31 downto 0);
        rw_addr0   : in  std_logic_vector(BITS-3 downto 0);
        rw_addr1   : in  std_logic_vector(BITS-3 downto 0);        
        rd_data0   : out std_logic_vector(31 downto 0);
        rd_data1   : out std_logic_vector(31 downto 0)
    );
end entity sim_mem;

architecture sim_mem_arch of sim_mem is
    
    constant MEM_SIZE: natural := 2**BITS;

    type byte_array is array (0 to MEM_SIZE/4-1) of std_logic_vector(7 downto 0);

    shared variable mem0: byte_array;
    shared variable mem1: byte_array;
    shared variable mem2: byte_array;
    shared variable mem3: byte_array;

begin

    wr_mem1: process(clk)
        subtype byte_type is character;
        type bin_type is file of byte_type;

        file bin: bin_type;
        variable byte: byte_type;

        variable addr: integer range 0 to MEM_SIZE/4-1;

        variable mem0_wr: std_logic;
        variable mem1_wr: std_logic;
        variable mem2_wr: std_logic;
        variable mem3_wr: std_logic;
    begin

        if rising_edge(clk) then
            if reset = '1' then
                file_open(bin, PROGRAM);
                addr := 0;
                
                while not endfile(bin) and addr <= MEM_SIZE/4-1 loop
                    read(bin, byte);
                    mem0(addr) := std_logic_vector(to_unsigned(byte_type'pos(byte), 8));
                    read(bin, byte);
                    mem1(addr) := std_logic_vector(to_unsigned(byte_type'pos(byte), 8));
                    read(bin, byte);
                    mem2(addr) := std_logic_vector(to_unsigned(byte_type'pos(byte), 8));
                    read(bin, byte);
                    mem3(addr) := std_logic_vector(to_unsigned(byte_type'pos(byte), 8));

                    addr := addr + 1;
                end loop;

                file_close(bin);
            elsif wr_en = '1' then
                addr := to_integer(unsigned(rw_addr1));

                mem0_wr := wr_byte_en(0);
                mem1_wr := wr_byte_en(1);
                mem2_wr := wr_byte_en(2);
                mem3_wr := wr_byte_en(3);

                if mem0_wr = '1' then
                    mem0(addr) := wr_data1(7  downto 0);
                end if;

                if mem1_wr = '1' then
                    mem1(addr) := wr_data1(15 downto 8);
                end if;

                if mem2_wr = '1' then
                    mem2(addr) := wr_data1(23 downto 16);
                end if;

                if mem3_wr = '1' then
                    mem3(addr) := wr_data1(31 downto 24);
                end if;

            end if;
        end if;
    end process wr_mem1;

    rd_mem0: process(rw_addr0)
        variable addr: integer range 0 to MEM_SIZE/4-1;
    begin
        addr := to_integer(unsigned(rw_addr0));

        rd_data0(7  downto  0) <= mem0(addr);
        rd_data0(15 downto  8) <= mem1(addr);
        rd_data0(23 downto 16) <= mem2(addr);
        rd_data0(31 downto 24) <= mem3(addr);
    end process rd_mem0;

    rd_mem1: process(rd_en, rw_addr1)
        variable addr: integer range 0 to MEM_SIZE/4-1;
    begin
        addr := to_integer(unsigned(rw_addr1));

        rd_data1(7  downto  0) <= mem0(addr);
        rd_data1(15 downto  8) <= mem1(addr);
        rd_data1(23 downto 16) <= mem2(addr);
        rd_data1(31 downto 24) <= mem3(addr);
    end process rd_mem1;
    
end architecture sim_mem_arch;