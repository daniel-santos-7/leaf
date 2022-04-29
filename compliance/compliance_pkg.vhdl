library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use std.textio.all;

package compliance_pkg is
    
    type bin_file is file of character;
    
    type byte_array is array (natural range<>) of std_logic_vector(7 downto 0);
    
    procedure read_bin_file(filename: string; mem: inout byte_array);
    
    procedure write_txt_file(filename: string; mem: byte_array; start_addr: integer; end_addr: integer);
    
end package compliance_pkg;

package body compliance_pkg is

    procedure read_bin_file(filename: string; mem: inout byte_array) is
        file bin      : bin_file;
        variable byte : character;
        variable addr : natural;
    begin
        file_open(bin, filename);
        addr := 0;
        while not endfile(bin) and addr <= mem'length-1 loop
            read(bin, byte);
            mem(addr) := std_logic_vector(to_unsigned(character'pos(byte), 8));
            addr := addr + 1;
        end loop;
        file_close(bin);
    end procedure read_bin_file;

    procedure write_txt_file(filename: string; mem: byte_array; start_addr: integer; end_addr: integer) is
        file txt      : text;
        variable word : line;
        variable addr : integer;
    begin
        file_open(txt, filename, write_mode);
        addr := start_addr;
        while addr <= end_addr-4 loop
            hwrite(word, mem(addr + 3));
            hwrite(word, mem(addr + 2));
            hwrite(word, mem(addr + 1));
            hwrite(word, mem(addr + 0));
            writeline(txt, word);
            addr := addr + 4;
        end loop;
        file_close(txt);
    end procedure write_txt_file;
    
end package body compliance_pkg;