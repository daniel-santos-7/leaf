----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: simulator clock and reset signal generator
-- 2022
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sim_io is
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;
        halt  : in  std_logic;
        dat_i : in  std_logic_vector(31 downto 0);
        cyc_i : in  std_logic;
        stb_i : in  std_logic;
        we_i  : in  std_logic;
        sel_i : in  std_logic_vector(3  downto 0);        
        adr_i : in  std_logic_vector(1  downto 0);
        ack_o : out std_logic;
        dat_o : out std_logic_vector(31 downto 0)
    );
end entity sim_io;

architecture arch of sim_io is

    -- fake registers --
    constant STAT_ADDR : std_logic_vector(1 downto 0) := b"00";
    constant CTRL_ADDR : std_logic_vector(1 downto 0) := b"01";
    constant BRDV_ADDR : std_logic_vector(1 downto 0) := b"10";
    constant TXRX_ADDR : std_logic_vector(1 downto 0) := b"11";

    -- idle state --
    signal idle : std_logic;

    type charfile is file of character;

    -- input and output files --
    file out_file : charfile;
    file in_file  : charfile;

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

    main: process(clk_i)
        variable char : character;
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                file_open(out_file, "STD_OUTPUT", write_mode);
                file_open(in_file, "STD_INPUT", read_mode);
            elsif halt = '1' then
                file_close(out_file);
                file_close(in_file);
            elsif idle = '1' and cyc_i = '1' and stb_i = '1' then
                if we_i = '1' then
                    if adr_i = TXRX_ADDR then
                        write(out_file, character'val(to_integer(unsigned(dat_i(7 downto 0)))));
                    end if;
                else
                    if adr_i = STAT_ADDR then
                        dat_o <= (31 downto 6 => '1') & b"111100";
                    elsif adr_i = TXRX_ADDR then
                        read(in_file, char);
                        dat_o <= (31 downto 8 => '0') & std_logic_vector(to_unsigned(character'pos(char), 8));
                    else
                        dat_o <= (31 downto 0 => '1');
                    end if;
                end if;
            end if;
        end if;
    end process main;

    ack_o <= not idle;

end architecture arch;