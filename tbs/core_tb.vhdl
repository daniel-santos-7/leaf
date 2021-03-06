library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use work.core_pkg.all;
use work.tbs_pkg.all;
use std.textio.all;

entity core_tb is
    
    generic (
        PROGRAM_FILE:   string;
        DUMP_FILE:      string;
        MEM_SIZE:       integer
    );

end entity core_tb;

architecture core_tb_arch of core_tb is
    
    signal clk:     std_logic;
    signal reset:   std_logic;

    signal rd_instr_mem_data: std_logic_vector(31 downto 0);
    signal rd_instr_mem_addr: std_logic_vector(31 downto 0);

    signal rd_wr_mem_addr:  std_logic_vector(31 downto 0);
    signal rd_mem_data:     std_logic_vector(31 downto 0);
    signal wr_mem_data:     std_logic_vector(31 downto 0);
    signal rd_mem_en:       std_logic;
    signal wr_mem_en:       std_logic;
    signal wr_mem_byte_en:  std_logic_vector(3  downto 0);

    signal ex_irq: std_logic := '0';
    signal sw_irq: std_logic := '0';
    signal tm_irq: std_logic := '0';

    type ram_array is array (0 to MEM_SIZE-1) of std_logic_vector(7 downto 0);
    
    shared variable ram: ram_array := (others => x"00");

    function read_ram(constant ram_mem: ram_array; constant addr: integer) return std_logic_vector is
        
        variable word: std_logic_vector(31 downto 0);
        
    begin

        word(7  downto  0)  := ram_mem(addr + 0);
        word(15 downto  8)  := ram_mem(addr + 1);
        word(23 downto 16)  := ram_mem(addr + 2);
        word(31 downto 24)  := ram_mem(addr + 3);
        
        return word;

    end function read_ram;

    signal sim_started: boolean := false;
    signal sim_finished: boolean := false;

begin
    
    uut: core port map (
        clk               => clk,
        reset             => reset,
        rd_instr_mem_data => rd_instr_mem_data,
        rd_instr_mem_addr => rd_instr_mem_addr,
        rd_mem_data       => rd_mem_data,
        wr_mem_data       => wr_mem_data,
        rd_mem_en         => rd_mem_en,
        wr_mem_en         => wr_mem_en,
        rd_wr_mem_addr    => rd_wr_mem_addr,
        wr_mem_byte_en    => wr_mem_byte_en,
        ex_irq            => ex_irq,
        sw_irq            => sw_irq,
        tm_irq            => tm_irq
    );

    clk <= not clk after 5 ns when sim_started and not sim_finished else '0';
    
    reset <= '0' after 10 ns when sim_started else '1';

    mem_wr: process (sim_started, clk)

        subtype byte_type is character;
        type bin_type is file of byte_type;

        file bin: bin_type;
        variable byte: byte_type;

        variable addr: integer;

    begin

        if not sim_started then
            
            file_open(bin, PROGRAM_FILE);

            addr := 0;

            while not endfile(bin) and addr <= MEM_SIZE-1 loop
            
                read(bin, byte);

                ram(addr) := std_logic_vector(to_unsigned(byte_type'pos(byte), 8));

                addr := addr + 1;
            
            end loop;

            file_close(bin);

            sim_started <= true;

        elsif rising_edge(clk) and wr_mem_en = '1' then

            addr := to_integer(unsigned(rd_wr_mem_addr));

            case wr_mem_byte_en is
                
                when b"0001" => 
                    
                    ram(addr + 0) := wr_mem_data(7 downto 0);
                    
                when b"0011" => 
                
                    ram(addr + 0) := wr_mem_data(7  downto 0);
                    ram(addr + 1) := wr_mem_data(15 downto 8);
            
                when others => 
                
                    ram(addr + 0) := wr_mem_data(7  downto 0);
                    ram(addr + 1) := wr_mem_data(15 downto 8);
                    ram(addr + 2) := wr_mem_data(23 downto 16);
                    ram(addr + 3) := wr_mem_data(31 downto 24);

            end case;

        end if;

    end process mem_wr;

    instr_mem_rd: process (rd_instr_mem_addr)
    
        variable addr: integer;

    begin
        
        addr := to_integer(unsigned(rd_instr_mem_addr));

        rd_instr_mem_data <= read_ram(ram, addr);

    end process instr_mem_rd;

    data_mem_rd: process (clk, rd_mem_en, rd_mem_data)
    
        variable addr: integer;

    begin
            
        if rd_mem_en = '1' then

            addr := to_integer(unsigned(rd_wr_mem_addr));

            rd_mem_data <= read_ram(ram, addr);

        else

            rd_mem_data <= (others => '0');

        end if;

    end process data_mem_rd;

    finish_sim: process(clk)
    
        variable testutil_addr_halt_data: std_logic_vector(31 downto 0);

    begin

        testutil_addr_halt_data := read_ram(ram, MEM_SIZE - 13);
    
        if rising_edge(clk) then
            
            sim_finished <=  testutil_addr_halt_data = x"00000001";

        end if;

    end process finish_sim;

    dump_wr: process(sim_finished)
    
        constant TESTUTIL_BASE: integer := MEM_SIZE - 13;
        constant TESTUTIL_ADDR_BEGIN_SIGNATURE: integer := TESTUTIL_BASE + 4;
        constant TESTUTIL_ADDR_END_SIGNATURE: integer := TESTUTIL_BASE + 8;

        variable begin_signature_addr: integer;
        variable end_signature_addr: integer;

        file dump: text;
        variable word: line;

        variable addr: integer;

    begin
        
        if sim_finished then
            
            begin_signature_addr := to_integer(unsigned(read_ram(ram, TESTUTIL_ADDR_BEGIN_SIGNATURE)));
            end_signature_addr := to_integer(unsigned(read_ram(ram, TESTUTIL_ADDR_END_SIGNATURE)));

            file_open(dump, DUMP_FILE, write_mode);

            addr := begin_signature_addr;

            while  addr <= end_signature_addr-4 loop

                hwrite(word, ram(addr + 3));
                hwrite(word, ram(addr + 2));
                hwrite(word, ram(addr + 1));
                hwrite(word, ram(addr));

                writeline(dump, word);

                addr := addr + 4;

            end loop;

            file_close(dump);

        end if;

    end process dump_wr;

end architecture core_tb_arch;