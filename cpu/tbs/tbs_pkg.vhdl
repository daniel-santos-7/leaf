library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use std.textio.all;

package tbs_pkg is

    constant CLK_PERIOD: time := 20 ns;

    type memory_array is array (natural range <>) of std_logic_vector(31 downto 0);

    procedure read_memory (
        constant program : in string;
        signal memory  : out memory_array
    );

    procedure write_memory (
        dump_file : in string;
        memory    : in memory_array
    );

    component wb_ram is
        generic (
            MEM_SIZE : natural;
            PROGRAM  : string
        );
        port (
            clk_i : in  std_logic;
            rst_i : in  std_logic;
            dat_i : in  std_logic_vector(31 downto 0);
            cyc_i : in  std_logic;
            stb_i : in  std_logic;
            we_i  : in  std_logic;
            sel_i : in  std_logic_vector(3  downto 0);
            adr_i : in  std_logic_vector(31 downto 0);
            ack_o : out std_logic;
            dat_o : out std_logic_vector(31 downto 0);
            mem_o : out memory_array
        );
    end component wb_ram;

end package tbs_pkg;

package body tbs_pkg is

    procedure read_memory (
        constant program : in string;
        signal memory  : out memory_array
    ) is

        type sw_type is file of character;
        file sw_file : sw_type;

        variable data : std_logic_vector(31 downto 0);
        variable byte : character;
        variable addr : integer range 0 to memory'length-1;

    begin
        file_open(sw_file, program);
        addr := 0;
        while not endfile(sw_file) and addr <= memory'length-1 loop
            read(sw_file, byte);
            data(7 downto 0) := std_logic_vector(to_unsigned(character'pos(byte), 8));
            read(sw_file, byte);
            data(15 downto 8) := std_logic_vector(to_unsigned(character'pos(byte), 8));
            read(sw_file, byte);
            data(23 downto 16) := std_logic_vector(to_unsigned(character'pos(byte), 8));
            read(sw_file, byte);
            data(31 downto 24) := std_logic_vector(to_unsigned(character'pos(byte), 8));
            memory(addr) <= data;
            addr := addr + 1;
        end loop;
        file_close(sw_file);
    end procedure;

    procedure write_memory (
        dump_file : in string;
        memory    : in memory_array
    ) is

        file dump: text;

        variable word: line;

        variable data : std_logic_vector(31 downto 0);
        variable addr : integer range 0 to memory'length-1;

    begin
        file_open(dump, DUMP_FILE, write_mode);
        while addr <= memory'length-1 loop
            data := memory(addr);
            hwrite(word, data(31 downto 24));
            hwrite(word, data(23 downto 16));
            hwrite(word, data(15 downto 8));
            hwrite(word, data(7 downto 0));
            writeline(dump, word);
            addr := addr + 1;
        end loop;
        file_close(dump);
    end procedure;

end package body tbs_pkg;
