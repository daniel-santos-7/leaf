library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sim_out is
    port (
        halt_i : in  std_logic;
        clk_i  : in  std_logic;
        rst_i  : in  std_logic;
        dat_i  : in  std_logic_vector(31 downto 0);
        cyc_i  : in  std_logic;
        stb_i  : in  std_logic;
        we_i   : in  std_logic;
        sel_i  : in  std_logic_vector(3  downto 0);        
        ack_o  : out std_logic
    );
end entity sim_out;

architecture sim_out_arch of sim_out is

    signal ack : std_logic;
    signal we  : std_logic;

    type charfile is file of character;
    
    file out_file: charfile;

begin

    ack <= cyc_i and stb_i;
    we  <= ack and we_i;

    wr_data: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                file_open(out_file, "STD_OUTPUT", write_mode);
            elsif halt_i = '1' then
                file_close(out_file);
            elsif we = '1' then
                if sel_i(3) = '1' then
                    write(out_file, character'val(to_integer(unsigned(dat_i(31 downto 24)))));
                end if;
                
                if sel_i(2) = '1' then
                    write(out_file, character'val(to_integer(unsigned(dat_i(23 downto 16)))));
                end if;

                if sel_i(1) = '1' then
                    write(out_file, character'val(to_integer(unsigned(dat_i(15 downto 8)))));
                end if;

                if sel_i(0) = '1' then
                    write(out_file, character'val(to_integer(unsigned(dat_i(7  downto 0)))));
                end if;
            end if;
        end if;
    end process wr_data;

    ack_o <= ack and not rst_i;
    
end architecture sim_out_arch;