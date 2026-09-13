----------------------------------------------------------------------
-- Project: Leaf
-- Developed by: Daniel Santos
-- Module: Leaf testbench package.
-- Date: 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use std.textio.all;

package leaf_tb_pkg is

    constant CLK_PERIOD: time := 10 ns;

    -- Reset address = 0x80000000 --
    constant RESET_ADDR : std_logic_vector(31 downto 0) := x"80000000";

    -- Memory size = 4MiB --
    constant MEM_SIZE : natural := 4194304;

    -- dump control --
    constant HALT_CMD_ADDR   : natural := MEM_SIZE/4-1;
    constant DUMP_START_ADDR : natural := MEM_SIZE/4-3;
    constant DUMP_STOP_ADDR  : natural := MEM_SIZE/4-2;

    -- interrupt command --
    constant HALT_CMD_DATA : std_logic_vector(31 downto 0) := x"DEADBEEF";

    type byte_array is array (natural range <>) of std_logic_vector(7 downto 0);

    type memory_array is array (natural range <>) of std_logic_vector(31 downto 0);

    procedure read_bytes (constant file_path : in string; signal bytes : out byte_array);

    procedure write_bytes (constant file_path : in string; signal bytes : in byte_array);

    procedure read_memory (constant program : in string; variable memory : out memory_array);

    procedure write_memory (dump_file : in string; memory : in memory_array);

    component wb_ram_dual is
        generic (
            PROGRAM   : string;
            DUMP_FILE : string
        );
        port (
            clk_i : in  std_logic;
            rst_i : in  std_logic;

            inst_cyc_i : in  std_logic;
            inst_stb_i : in  std_logic;
            inst_adr_i : in  std_logic_vector(31 downto 2);
            inst_dat_o : out std_logic_vector(31 downto 0);
            inst_ack_o : out std_logic;

            data_cyc_i : in  std_logic;
            data_stb_i : in  std_logic;
            data_adr_i : in  std_logic_vector(31 downto 2);
            data_sel_i : in  std_logic_vector(3 downto 0);
            data_we_i  : in  std_logic;
            data_dat_i : in  std_logic_vector(31 downto 0);
            data_dat_o : out std_logic_vector(31 downto 0);
            data_ack_o : out std_logic;

            wr_mem_i : in std_logic;
            rd_mem_i : in std_logic;
            halt_o   : out std_logic
        );
    end component wb_ram_dual;

    component wb_clint is
        generic (
            RTC_DIV : positive := 8
        );
        port (
            clk_i : in  std_logic;
            rst_i : in  std_logic;

            cyc_i : in  std_logic;
            stb_i : in  std_logic;
            we_i  : in  std_logic;
            adr_i : in  std_logic_vector(31 downto 2);
            dat_i : in  std_logic_vector(31 downto 0);
            dat_o : out std_logic_vector(31 downto 0);
            sel_o : out std_logic;

            sw_irq_o : out std_logic;
            tm_irq_o : out std_logic
        );
    end component wb_clint;

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

    procedure read_memory (
        constant program : in string;
        variable memory  : out memory_array
    ) is

        type sw_type is file of character;
        file sw_file : sw_type;

        variable data : std_logic_vector(31 downto 0);
        variable byte : character;
        variable addr : integer range 0 to memory'length;

    begin
        file_open(sw_file, program);
        addr := 0;
        while not endfile(sw_file) loop
            if addr >= memory'length then
                report "read_memory: program too large for memory" severity error;
                exit;
            end if;
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
        file_open(dump, dump_file, write_mode);
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
