----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: simulator memory with wishbone interface
-- 2022
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use std.textio.all;

entity wb_out is
    generic (
        DUMP_FILE : string
    );
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;
        dat_i : in  std_logic_vector(31 downto 0);
        cyc_i : in  std_logic;
        stb_i : in  std_logic;
        we_i  : in  std_logic;
        sel_i : in  std_logic_vector(3  downto 0);
        ack_o : out std_logic;
        dat_o : out std_logic_vector(31 downto 0)
    );
end entity wb_out;

architecture arch of wb_out is

    signal ack : std_logic;

    signal pointer : integer;

    file dump: text;

begin

    ack_reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                ack <= '0';
            elsif ack = '0' then
                ack <= (cyc_i and stb_i);
            else
                ack <= '0';
            end if;
        end if;
    end process ack_reg;

    main: process(clk_i)

        variable word: line;

    begin

        if rising_edge(clk_i) then
            if rst_i = '1' then
                integer = 0;
            elsif cyc_i = '1' and stb_i = '1' then
                file_open(dump, DUMP_FILE, write_mode);
                if we_i = '1' then
                    if sel_i(3) = '1' then
                        hwrite(word, dat_i(31 downto 24));
                    end if;
                    if sel_i(2) = '1' then
                        hwrite(word, dat_i(23 downto 16));
                    end if;
                    if sel_i(1) = '1' then
                        hwrite(word, dat_i(15 downto 8));
                    end if;
                    if sel_i(0) = '1' then
                        hwrite(word, dat_i(7 downto 0));
                    end if;
                    writeline(dump, word);
                end if;
                file_close(dump);
            end if;
        end if;

    end process main;

    ack_o <= ack;

end architecture arch;
