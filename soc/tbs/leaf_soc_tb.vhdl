library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_soc_pkg.all;

entity leaf_soc_tb is
    generic (
        PROGRAM : string
    );
end entity leaf_soc_tb;

architecture sim of leaf_soc_tb is

    constant BITS       : natural := 24;
    constant MEM_SIZE   : natural := 2**BITS;
    constant UART_BAUD  : natural := 434;
    constant CLK_PERIOD : time    := 20 ns;
    constant WM_CMD     : std_logic_vector(7 downto 0) := x"31";

    signal clk : std_logic := '0';
    signal rst : std_logic;
    signal rx  : std_logic;
    signal tx  : std_logic;

    type byte_array is array (0 to MEM_SIZE-1) of std_logic_vector(7 downto 0);
    shared variable mem : byte_array;

    subtype byte_type is character;
    type bin_type is file of byte_type;
    file bin: bin_type;

begin
    
    uut: leaf_soc port map (
        clk => clk,
        rst => rst,
        rx  => rx,
        tx  => tx
    );

    clk <= not clk after (CLK_PERIOD/2);
    rst <= '1', '0' after CLK_PERIOD;

    ld_program: process
        variable byte  : byte_type;
        variable addr  : integer;
        variable size  : std_logic_vector(31 downto 0);
        variable frame : std_logic_vector(9 downto 0);
    begin
        rx <= '1';
        wait for 25*CLK_PERIOD;

        file_open(bin, PROGRAM);
        addr := 0;
        while not endfile(bin) loop
            read(bin, byte);
            mem(addr) := std_logic_vector(to_unsigned(byte_type'pos(byte), 8));
            addr := addr + 1;
        end loop;
        file_close(bin);

        frame := '1' & WM_CMD & '0';
        for i in 0 to 9 loop
            rx <= frame(i);
            wait for UART_BAUD*CLK_PERIOD;
        end loop;

        size := std_logic_vector(to_unsigned(addr, 32));

        frame := '1' & size(31 downto 24) & '0';
        for i in 0 to 9 loop
            rx <= frame(i);
            wait for UART_BAUD*CLK_PERIOD;    
        end loop;

        frame := '1' & size(23 downto 16) & '0';
        for i in 0 to 9 loop
            rx <= frame(i);
            wait for UART_BAUD*CLK_PERIOD;    
        end loop;

        frame := '1' & size(15 downto  8) & '0';
        for i in 0 to 9 loop
            rx <= frame(i);
            wait for UART_BAUD*CLK_PERIOD;    
        end loop;

        frame := '1' & size(7  downto  0) & '0';
        for i in 0 to 9 loop
            rx <= frame(i);
            wait for UART_BAUD*CLK_PERIOD;    
        end loop;

        for i in 0 to addr loop
            frame := '1' & mem(i) & '0';
            for j in 0 to 9 loop
                rx <= frame(j);
                wait for UART_BAUD*CLK_PERIOD;
            end loop;
        end loop;

        rx <= '1';
        wait;
    end process ld_program;

    wr_output: process
        variable data : std_logic_vector(7 downto 0);
        type charfile is file of character;
        file out_file: charfile;
    begin
        data := x"FF";
        file_open(out_file, "STD_OUTPUT", write_mode);
        while true loop
            wait until tx = '0';
            wait for UART_BAUD*CLK_PERIOD;
            wait for UART_BAUD*CLK_PERIOD/2;
            for i in 0 to 7 loop
                data(i) := tx;
                wait for UART_BAUD*CLK_PERIOD;
            end loop;
            write(out_file, character'val(to_integer(unsigned(data))));
        end loop;
        file_close(out_file);
        wait;
    end process wr_output;

end architecture sim;