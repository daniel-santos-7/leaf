----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: simulator memory with wishbone interface
-- 2022
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity wb_ram is
    generic (
        BITS    : natural := 8;
        PROGRAM : string
    );
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;
        dat_i : in  std_logic_vector(31 downto 0);
        cyc_i : in  std_logic;
        stb_i : in  std_logic;
        we_i  : in  std_logic;
        sel_i : in  std_logic_vector(3  downto 0);        
        adr_i : in  std_logic_vector(BITS-3 downto 0);
        ack_o : out std_logic;
        dat_o : out std_logic_vector(31 downto 0)
    );
end entity wb_ram;

architecture arch of wb_ram is
    
    constant MEM_SIZE : natural := 2**BITS;

    type mem_array is array (0 to MEM_SIZE/4-1) of std_logic_vector(7 downto 0);

    -- memory blocks --
    shared variable mem0 : mem_array;
    shared variable mem1 : mem_array;
    shared variable mem2 : mem_array;
    shared variable mem3 : mem_array;

    -- idle state --
    signal idle : std_logic;

    -- enable signals --
    signal mem0_en : std_logic;
    signal mem1_en : std_logic;
    signal mem2_en : std_logic;
    signal mem3_en : std_logic;

    -- write enable signals --
    signal mem0_we : std_logic;
    signal mem1_we : std_logic;
    signal mem2_we : std_logic;
    signal mem3_we : std_logic;

    -- read enable signals --
    signal mem0_re : std_logic;
    signal mem1_re : std_logic;
    signal mem2_re : std_logic;
    signal mem3_re : std_logic;

begin

    idle_reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                idle <= '1';
            elsif idle = '1' then
                idle <= not (cyc_i and stb_i);
            else
                idle <= '1';
            end if;
        end if;
    end process idle_reg;

    mem0_en <= idle and cyc_i and stb_i and sel_i(0);
    mem1_en <= idle and cyc_i and stb_i and sel_i(1);
    mem2_en <= idle and cyc_i and stb_i and sel_i(2);
    mem3_en <= idle and cyc_i and stb_i and sel_i(3);

    mem0_we <= mem0_en and we_i;
    mem1_we <= mem1_en and we_i;
    mem2_we <= mem2_en and we_i;
    mem3_we <= mem3_en and we_i;

    mem0_re <= mem0_en and not we_i;
    mem1_re <= mem1_en and not we_i;
    mem2_re <= mem2_en and not we_i;
    mem3_re <= mem3_en and not we_i;

    main: process(clk_i)
        type sw_type is file of character;
        file sw_file : sw_type;

        variable byte : character;
        variable addr : integer range 0 to MEM_SIZE/4-1;
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                file_open(sw_file, PROGRAM);
                addr := 0;
                while not endfile(sw_file) and addr <= MEM_SIZE/4-1 loop
                    read(sw_file, byte);
                    mem0(addr) := std_logic_vector(to_unsigned(character'pos(byte), 8));
                    read(sw_file, byte);
                    mem1(addr) := std_logic_vector(to_unsigned(character'pos(byte), 8));
                    read(sw_file, byte);
                    mem2(addr) := std_logic_vector(to_unsigned(character'pos(byte), 8));
                    read(sw_file, byte);
                    mem3(addr) := std_logic_vector(to_unsigned(character'pos(byte), 8));
                    addr := addr + 1;
                end loop;
                file_close(sw_file);
            else 
                addr := to_integer(unsigned(adr_i));
                if mem0_we = '1' then
                    mem0(addr) := dat_i(7  downto 0);
                end if;
                if mem1_we = '1' then
                    mem1(addr) := dat_i(15 downto 8);
                end if;
                if mem2_we = '1' then
                    mem2(addr) := dat_i(23 downto 16);
                end if;
                if mem3_we = '1' then
                    mem3(addr) := dat_i(31 downto 24);
                end if;
                if mem0_re = '1' then
                    dat_o(7  downto  0) <= mem0(addr);                        
                end if;
                if mem1_re = '1' then
                    dat_o(15 downto  8) <= mem1(addr);                        
                end if;
                if mem2_re = '1' then
                    dat_o(23 downto 16) <= mem2(addr);                        
                end if;
                if mem3_re = '1' then
                    dat_o(31 downto 24) <= mem3(addr);                        
                end if;
            end if;
        end if;
    end process main;

    ack_o <= not idle;

end architecture arch;