library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;
use work.soc_pkg.all;

entity soc is
    port (
        clk: in  std_logic;
        rst: in  std_logic;
        rx : in  std_logic;
        tx : out std_logic
    );
end entity soc;

architecture soc_arch of soc is
    
    signal uart_acmp  : std_logic;
    signal rom_acmp   : std_logic;
    signal ram_acmp   : std_logic;

    signal cpu_ack : std_logic;
    signal cpu_cyc : std_logic;
    signal cpu_stb : std_logic;
    signal cpu_we  : std_logic;
    signal cpu_sel : std_logic_vector(3  downto 0);
    signal cpu_adr : std_logic_vector(31 downto 0);
    signal cpu_drd : std_logic_vector(31 downto 0);
    signal cpu_dwr : std_logic_vector(31 downto 0);

    signal uart_stb : std_logic;
    signal rom_stb  : std_logic;
    signal ram_stb  : std_logic;

    signal uart_ack : std_logic;
    signal rom_ack  : std_logic;
    signal ram_ack  : std_logic;

    signal uart_dat : std_logic_vector(31 downto 0);
    signal rom_dat  : std_logic_vector(31 downto 0);
    signal ram_dat  : std_logic_vector(31 downto 0);

begin
    
    uart_stb <= uart_acmp and cpu_cyc and cpu_stb;
    rom_stb  <= rom_acmp  and cpu_cyc and cpu_stb;
    ram_stb  <= ram_acmp  and cpu_cyc and cpu_stb;

    cpu_ack <= uart_ack or rom_ack or ram_ack;
    cpu_drd <= uart_dat when uart_acmp = '1' else rom_dat when rom_acmp = '1' else ram_dat when ram_acmp = '1' else (others => '0');

    cpu: leaf generic map (
        RESET_ADDR => x"00000100"
    ) port map (
        clk_i => clk,
        rst_i => rst,
        ack_i => cpu_ack,
        dat_i => cpu_drd,
        cyc_o => cpu_cyc,
        stb_o => cpu_stb,
        we_o  => cpu_we,
        sel_o => cpu_sel,
        adr_o => cpu_adr,
        dat_o => cpu_dwr
    );

    address: soc_addr port map (
        addr   => cpu_adr,
        acmp0  => uart_acmp,
        acmp1  => rom_acmp,
        acmp2  => ram_acmp
    );

    soc_io: soc_uart port map (
        clk_i => clk,
        rst_i => rst,
        dat_i => cpu_dwr,
        cyc_i => cpu_cyc,
        stb_i => uart_stb,
        we_i  => cpu_we,
        sel_i => cpu_sel,
        adr_i => cpu_adr(3 downto 2),     
        rx    => rx,
        ack_o => uart_ack,
        dat_o => uart_dat,
        tx    => tx
    );

    rom: soc_rom generic map (
        BITS  => 8
    ) port map (
        clk_i => clk,
        rst_i => rst,
        cyc_i => cpu_cyc,
        stb_i => rom_stb,
        adr_i => cpu_adr(7 downto 2),
        ack_o => rom_ack,
        dat_o => rom_dat
    );

    -- memory 64 kB --
    ram: soc_ram generic map (
        BITS  => 16
    ) port map (
        clk_i => clk,
        rst_i => rst,
        dat_i => cpu_dwr,
        cyc_i => cpu_cyc,
        stb_i => ram_stb,
        we_i  => cpu_we,
        sel_i => cpu_sel,
        adr_i => cpu_adr(15 downto 2),
        ack_o => ram_ack,
        dat_o => ram_dat
    );

end architecture soc_arch;