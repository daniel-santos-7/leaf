library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use std.textio.all;

entity sim_out is
    generic (
        FILENAME : string
    );
    port (
        halt    : in std_logic;
        clk     : in std_logic;
        reset   : in std_logic;
        wr_en   : in std_logic;
        wr_data : in std_logic_vector(31 downto 0)
    );
end entity sim_out;

architecture sim_out_arch of sim_out is

    file txt_file : text;

begin

    main: process(clk)
        variable word : line;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                file_open(txt_file, FILENAME, write_mode);
            elsif halt = '1' then
                file_close(txt_file);
            elsif wr_en = '1' then
                hwrite(word, wr_data(31 downto 24));
                hwrite(word, wr_data(23 downto 16));
                hwrite(word, wr_data(15 downto 8));
                hwrite(word, wr_data(7  downto 0));
                writeline(txt_file, word);
            end if;
        end if;
    end process main;
    
end architecture sim_out_arch;