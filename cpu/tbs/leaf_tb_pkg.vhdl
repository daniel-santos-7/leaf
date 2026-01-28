library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use std.textio.all;

package leaf_tb_pkg is

    constant CLK_PERIOD: time := 20 ns;

    type byte_array is array (natural range <>) of std_logic_vector(7 downto 0);

    type memory_array is array (natural range <>) of std_logic_vector(31 downto 0);

    procedure read_bytes (constant file_path : in string; signal bytes : out byte_array);

    procedure write_bytes (constant file_path : in string; signal bytes : in byte_array);

    -- procedure read_memory (constant program : in string; signal memory : out memory_array); --

    procedure read_memory (constant program : in string; variable memory : out memory_array);

    procedure write_memory (dump_file : in string; memory : in memory_array);

    component wb_ram is
        generic (
            MEM_SIZE : natural;
            PROGRAM  : string;
            DUMP_FILE  : string
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
            wr_mem_i : in std_logic;
            rd_mem_i : in std_logic;
            halt_o   : out std_logic
        );
    end component wb_ram;

end package leaf_tb_pkg;

package body leaf_tb_pkg is

    procedure read_bytes (constant file_path : in string; signal bytes : out byte_array) is

        type sw_type is file of character;

        file sw_file : sw_type;

        variable byte : character;

        variable addr : integer range 0 to bytes'length-1;

    begin
        file_open(sw_file, file_path);
        addr := 0;
        while not endfile(sw_file) and addr <= bytes'length-1 loop
            read(sw_file, byte);
            bytes(addr) <= std_logic_vector(to_unsigned(character'pos(byte), 8));
            addr := addr + 1;
        end loop;
        file_close(sw_file);
    end procedure;

    procedure write_bytes (constant file_path: in string; signal bytes: in byte_array) is

        file txt_file : text;

        variable content : line;

        variable byte : std_logic_vector(7 downto 0);

    begin
        file_open(txt_file, file_path, write_mode);
        for addr in bytes'range loop
            byte := bytes(addr);
            hwrite(content, byte);
        end loop;
        writeline(txt_file, content);
        file_close(txt_file);
    end procedure;

    --procedure read_memory (
    --    constant program : in string;
    --    signal memory  : out memory_array
    --) is

    --    type sw_type is file of character;
    --    file sw_file : sw_type;

    --    variable data : std_logic_vector(31 downto 0);
    --    variable byte : character;
    --    variable addr : integer range 0 to memory'length-1;

    --begin
    --    file_open(sw_file, program);
    --    addr := 0;
    --    while not endfile(sw_file) and addr <= memory'length-1 loop
    --        read(sw_file, byte);
    --        data(7 downto 0) <= std_logic_vector(to_unsigned(character'pos(byte), 8));
    --        read(sw_file, byte);
    --        data(15 downto 8) <= std_logic_vector(to_unsigned(character'pos(byte), 8));
    --        read(sw_file, byte);
    --        data(23 downto 16) <= std_logic_vector(to_unsigned(character'pos(byte), 8));
    --        read(sw_file, byte);
    --        data(31 downto 24) <= std_logic_vector(to_unsigned(character'pos(byte), 8));
    --        memory(addr) <= data;
    --        addr := addr + 1;
    --    end loop;
    --    file_close(sw_file);
    --end procedure;

    procedure read_memory (
        constant program : in string;
        variable memory  : out memory_array
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
            memory(addr) := data;
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

    begin
        file_open(dump, DUMP_FILE, write_mode);
        for addr in memory'range loop
            data := memory(addr);
            hwrite(word, data(31 downto 24));
            hwrite(word, data(23 downto 16));
            hwrite(word, data(15 downto 8));
            hwrite(word, data(7  downto 0));
            writeline(dump, word);
        end loop;
        file_close(dump);
    end procedure;

end package body leaf_tb_pkg;
