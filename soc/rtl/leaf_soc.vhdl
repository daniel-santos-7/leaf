----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: leaf system (SOC)
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;
use work.leaf_soc_pkg.all;
use work.uart_pkg.all;

entity leaf_soc is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        rx  : in  std_logic;
        tx  : out std_logic;
        dbg : out std_logic_vector(7 downto 0)
    );
end entity leaf_soc;

architecture arch of leaf_soc is

    -- system clock and reset --
    signal sys_clk : std_logic;
    signal sys_rst : std_logic;

    -- cpu signals --
    signal cpu_ack : std_logic;
    signal cpu_cyc : std_logic;
    signal cpu_stb : std_logic;
    signal cpu_we  : std_logic;
    signal cpu_sel : std_logic_vector(3  downto 0);
    signal cpu_adr : std_logic_vector(31 downto 0);
    signal cpu_drd : std_logic_vector(31 downto 0);
    signal cpu_dwr : std_logic_vector(31 downto 0);

    -- uart signals --
    signal uart_acmp: std_logic;
    signal uart_stb : std_logic;
    signal uart_ack : std_logic;
    signal uart_dat : std_logic_vector(31 downto 0);

    -- rom signals --
    signal rom_acmp : std_logic;
    signal rom_stb  : std_logic;
    signal rom_ack  : std_logic;
    signal rom_dat  : std_logic_vector(31 downto 0);

    -- ram signals --
    signal ram_acmp : std_logic;
    signal ram_stb  : std_logic;
    signal ram_ack  : std_logic;
    signal ram_dat  : std_logic_vector(31 downto 0);

    -- debug register signals --
    signal dbg_acmp : std_logic;
    signal dbg_stb  : std_logic;
    signal dbg_ack  : std_logic;
    signal dbg_dat  : std_logic_vector(7 downto 0);

begin
    
    -- address docode --
    uart_acmp <= '1' when cpu_adr(31 downto  4) = x"0000000" else '0';
    dbg_acmp  <= '1' when cpu_adr(31 downto  4) = x"0000001" else '0';
    rom_acmp  <= '1' when cpu_adr(31 downto  8) = x"000001" else '0';
    ram_acmp  <= '1' when cpu_adr(31 downto 16) = x"0001" else '0';

    uart_stb <= uart_acmp and cpu_stb;
    rom_stb  <= rom_acmp  and cpu_stb;
    ram_stb  <= ram_acmp  and cpu_stb;
    dbg_stb  <= dbg_acmp  and cpu_stb;

    cpu_ack <= uart_ack or rom_ack or ram_ack or dbg_ack;
    cpu_drd <= uart_dat when uart_acmp = '1' else rom_dat when rom_acmp = '1' else ram_dat when ram_acmp = '1' else  (31 downto 8 => '0') & dbg_dat when dbg_acmp = '1' else (others => '0');

    syscon: soc_syscon port map (
        clk   => clk,
        rst   => rst,
        clk_o => sys_clk,
        rst_o => sys_rst
    );

    soc_cpu: leaf generic map (
        RESET_ADDR => x"00000100"
    ) port map (
        clk_i  => sys_clk,
        rst_i  => sys_rst,
        ex_irq => '0',
        sw_irq => '0',
        tm_irq => '0',
        ack_i  => cpu_ack,
        err_i  => '0',
        dat_i  => cpu_drd,
        cyc_o  => cpu_cyc,
        stb_o  => cpu_stb,
        we_o   => cpu_we,
        sel_o  => cpu_sel,
        adr_o  => cpu_adr,
        dat_o  => cpu_dwr
    );

    soc_io: uart_wbsl port map (
        clk_i => sys_clk,
        rst_i => sys_rst,
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

    soc_rom: rom generic map (
        BITS  => 8
    ) port map (
        clk_i => sys_clk,
        rst_i => sys_rst,
        cyc_i => cpu_cyc,
        stb_i => rom_stb,
        adr_i => cpu_adr(7 downto 2),
        ack_o => rom_ack,
        dat_o => rom_dat
    );

    -- memory 64 kB --
    soc_ram: ram generic map (
        BITS  => 16
    ) port map (
        clk_i => sys_clk,
        rst_i => sys_rst,
        dat_i => cpu_dwr,
        cyc_i => cpu_cyc,
        stb_i => ram_stb,
        we_i  => cpu_we,
        sel_i => cpu_sel,
        adr_i => cpu_adr(15 downto 2),
        ack_o => ram_ack,
        dat_o => ram_dat
    );

    -- debug register --
    soc_dbg: debug_reg port map (
        clk_i => sys_clk,
        rst_i => sys_rst,
        dat_i => cpu_dwr(7 downto 0),
        cyc_i => cpu_cyc,
        stb_i => dbg_stb,
        we_i  => cpu_we,
        ack_o => dbg_ack,
        dat_o => dbg_dat
    );

    -- debug register output --
    dbg <= dbg_dat;

end architecture arch;