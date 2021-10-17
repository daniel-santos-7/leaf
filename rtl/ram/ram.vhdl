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
        BITS: natural := 8     -- internal bus width address = log2(MEM_SIZE)
    );

    port (
        clk: in std_logic;
        
        -- read only port --

        adr_i0: in  std_logic_vector(ADDR_BITS-3 downto 0);
        dat_o0: out std_logic_vector(31 downto 0);

        -- read/write port --

        adr_i1: in  std_logic_vector(ADDR_BITS-3 downto 0);        
        dat_o1: out std_logic_vector(31 downto 0);
        dat_i1: in  std_logic_vector(31 downto 0);
        sel_i1: in  std_logic_vector(3  downto 0);
        we_i1:  in  std_logic;
    );
end entity ram;

architecture ram_arch of ram is
    
    constant MEM_SIZE := BITS**2;

    type mem_array is array (0 to MEM_SIZE/4-1) of std_logic_vector(31 downto 0);

    signal mem0: mem_array;
    signal mem1: mem_array;
    signal mem2: mem_array;
    signal mem3: mem_array;

begin
    
    wr_ram: process(clk)
    
        variable addr: integer range 0 to MEM_SIZE/4-1;

        variable mem0_we: std_logic;
        variable mem1_we: std_logic;
        variable mem2_we: std_logic;
        variable mem3_we: std_logic;

    begin

        if rising_edge(clk) then

            addr := to_integer(unsigned(wr_addr));

            mem0_we := sel_i1(0);
            mem1_we := sel_i1(1);
            mem2_we := sel_i1(2);
            mem3_we := sel_i1(3);

            if we_i1 = '1' then
                    
                if mem0_we = '1' then

                    mem0(addr) <= dat_i1(7  downto 0);

                end if;

                if mem1_we = '1' then

                    mem1(addr) <= dat_i1(15 downto 8);

                end if;

                if mem2_we = '1' then

                    mem2(addr) <= dat_i1(23 downto 16);

                end if;

                if mem3_we = '1' then

                    mem3(addr) <= dat_i1(31 downto 24);
                    
                end if;
    
            end if;

        end if;
        
    end process wr_ram;

    dat_o0(7  downto  0)  <= mem0(to_integer(unsigned(adr_i0)));
    dat_o0(15 downto  8)  <= mem1(to_integer(unsigned(adr_i0)));
    dat_o0(23 downto 16)  <= mem2(to_integer(unsigned(adr_i0)));
    dat_o0(31 downto 24)  <= mem3(to_integer(unsigned(adr_i0)));

    dat_o1(7  downto  0)  <= mem0(to_integer(unsigned(adr_i1)));
    dat_o1(15 downto  8)  <= mem1(to_integer(unsigned(adr_i1)));
    dat_o1(23 downto 16)  <= mem2(to_integer(unsigned(adr_i1)));
    dat_o1(31 downto 24)  <= mem3(to_integer(unsigned(adr_i1)));        
    
end architecture ram_arch;