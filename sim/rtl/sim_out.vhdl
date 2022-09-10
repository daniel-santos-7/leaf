library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sim_out is
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
end entity sim_out;

architecture rtl of sim_out is

    constant STAT_ADDR : std_logic_vector(1 downto 0) := b"00";
    constant CTRL_ADDR : std_logic_vector(1 downto 0) := b"01";
    constant BRDV_ADDR : std_logic_vector(1 downto 0) := b"10";
    constant TXRX_ADDR : std_logic_vector(1 downto 0) := b"11";

    signal ack : std_logic;
    signal we  : std_logic;

    type charfile is file of character;
    file out_file: charfile;

begin

    ack <= cyc_i and stb_i;
    we  <= ack and we_i;

    rd_data: process(ack, adr_i)
    begin
        if ack = '1' then
            case adr_i is
                when STAT_ADDR => dat_o <= (31 downto 6 => '1') & b"111100";
                when CTRL_ADDR => dat_o <= (31 downto 0 => '1');
                when BRDV_ADDR => dat_o <= (31 downto 0 => '1');
                when TXRX_ADDR => dat_o <= (31 downto 0 => '1');
                when others => null;
            end case;
        end if;
    end process rd_data;

    wr_data: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                file_open(out_file, "STD_OUTPUT", write_mode);
            elsif halt = '1' then
               file_close(out_file);
            elsif we = '1' then
                write(out_file, character'val(to_integer(unsigned(dat_i(7 downto 0)))));
            end if;
        end if;
    end process wr_data;

    ack_o <= ack and not rst_i;
    
end architecture rtl;