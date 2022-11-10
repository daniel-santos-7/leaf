----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: leaf system simulator
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;
use work.leaf_sim_pkg.all;

entity leaf_sim is
    generic (
        PROGRAM : string
    );
end entity leaf_sim;

architecture arch of leaf_sim is
    
    -- clock and reset --
    signal clk  : std_logic;
    signal rst  : std_logic;
    signal halt : std_logic;

    -- cpu signals --
    signal cpu_ack : std_logic;
    signal cpu_cyc : std_logic;
    signal cpu_stb : std_logic;
    signal cpu_we  : std_logic;
    signal cpu_sel : std_logic_vector(3  downto 0);
    signal cpu_adr : std_logic_vector(31 downto 0);
    signal cpu_drd : std_logic_vector(31 downto 0);
    signal cpu_dwr : std_logic_vector(31 downto 0);

    -- input/output virtual device signals --
    signal out_acmp : std_logic;
    signal out_stb  : std_logic;
    signal out_ack  : std_logic;
    signal out_adr  : std_logic_vector(1  downto 0);
    signal out_dat  : std_logic_vector(31 downto 0);

    -- simulator interrupt signals --
    signal halt_acmp : std_logic;
    signal halt_stb  : std_logic;
    signal halt_ack  : std_logic;
    signal halt_dat  : std_logic;

    -- memory signals --
    signal mem_acmp : std_logic;
    signal mem_stb  : std_logic;
    signal mem_ack  : std_logic;
    signal mem_adr  : std_logic_vector(19 downto 0);
    signal mem_dat  : std_logic_vector(31 downto 0);

begin

    -- address decoder --
    out_acmp  <= '1' when cpu_adr(31 downto  4) = x"0000000" else '0';
    halt_acmp <= '1' when cpu_adr(31 downto  0) = x"00000010" else '0';
    mem_acmp  <= '1' when cpu_adr(31 downto 22) = b"0000000001" else '0';

    -- cpu inputs
    cpu_ack <= out_ack or mem_ack;
    cpu_drd <= out_dat when out_acmp = '1' else mem_dat when mem_acmp = '1' else (others => '0');

    -- slaves selection --
    out_stb  <= out_acmp and cpu_cyc and cpu_stb;
    halt_stb <= halt_acmp and cpu_cyc and cpu_stb;
    mem_stb  <= mem_acmp and cpu_cyc and cpu_stb;

    -- slave addresses --
    out_adr <= cpu_adr(3  downto 2);
    mem_adr <= cpu_adr(21 downto 2);

    -- simulation clock and reset control --
    control: sim_syscon port map (
        halt  => halt,
        clk_o => clk,
        rst_o => rst
    );

    -- leaf cpu --
    cpu: leaf generic map (
        RESET_ADDR => x"00400000"
    ) port map (
        clk_i  => clk,
        rst_i  => rst,
        ex_irq => '0',
        sw_irq => '0',
        tm_irq => '0',
        ack_i  => cpu_ack,
        dat_i  => cpu_drd,
        cyc_o  => cpu_cyc,
        stb_o  => cpu_stb,
        we_o   => cpu_we,
        sel_o  => cpu_sel,
        adr_o  => cpu_adr,
        dat_o  => cpu_dwr
    );

    -- input/output device --
    output: sim_io port map (
        clk_i => clk,
        rst_i => rst,
        halt  => halt,
        dat_i => cpu_dwr,
        cyc_i => cpu_cyc,
        stb_i => out_stb,
        we_i  => cpu_we,
        sel_i => cpu_sel, 
        adr_i => out_adr,    
        ack_o => out_ack,
        dat_o => out_dat
    );

    -- simulator halt signal control --
    halt_control: sim_halt port map (
        clk_i => clk,
        rst_i => rst,
        dat_i => cpu_dwr,
        cyc_i => cpu_cyc,
        stb_i => halt_stb,
        we_i  => cpu_we,
        ack_o => halt_ack,
        halt  => halt
    );

    -- system memory (4 MB) --
    memory: sim_mem generic map (
        BITS    => 22,
        PROGRAM => PROGRAM
    ) port map (
        clk_i => clk,
        rst_i => rst,
        dat_i => cpu_dwr,
        cyc_i => cpu_cyc,
        stb_i => mem_stb,
        we_i  => cpu_we,
        sel_i => cpu_sel,
        adr_i => mem_adr,
        ack_o => mem_ack,
        dat_o => mem_dat
    );

end architecture arch;