library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sim_out is
    port (
        halt       : in std_logic;
        clk        : in std_logic;
        reset      : in std_logic;
        wr_en      : in std_logic;
        wr_byte_en : in std_logic_vector(3  downto 0);
        wr_data    : in std_logic_vector(31 downto 0)
    );
end entity sim_out;

architecture sim_out_arch of sim_out is

    type charfile is file of character;
    
    file out_file: charfile;

begin

    main: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                file_open(out_file, "STD_OUTPUT", write_mode);
            elsif halt = '1' then
                file_close(out_file);
            elsif wr_en = '1' then
                if wr_byte_en(3) = '1' then
                    write(out_file, character'val(to_integer(unsigned(wr_data(31 downto 24)))));
                end if;
                
                if wr_byte_en(2) = '1' then
                    write(out_file, character'val(to_integer(unsigned(wr_data(23 downto 16)))));
                end if;

                if wr_byte_en(1) = '1' then
                    write(out_file, character'val(to_integer(unsigned(wr_data(15 downto 8)))));
                end if;

                if wr_byte_en(0) = '1' then
                    write(out_file, character'val(to_integer(unsigned(wr_data(7  downto 0)))));
                end if;
            end if;
        end if;
    end process main;
    
end architecture sim_out_arch;