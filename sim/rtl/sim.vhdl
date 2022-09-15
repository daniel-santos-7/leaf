library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;
use work.sim_pkg.all;

entity sim is
    generic (
        BIN_FILE : string
    );
end entity sim;

architecture rtl of sim is
    
    signal clk  : std_logic;
    signal rst  : std_logic;
    signal halt : std_logic;

    signal cpu_ack : std_logic;
    signal cpu_cyc : std_logic;
    signal cpu_stb : std_logic;
    signal cpu_we  : std_logic;
    signal cpu_sel : std_logic_vector(3  downto 0);
    signal cpu_adr : std_logic_vector(31 downto 0);
    signal cpu_drd : std_logic_vector(31 downto 0);
    signal cpu_dwr : std_logic_vector(31 downto 0);

    signal out_acmp : std_logic;
    signal out_stb  : std_logic;
    signal out_ack  : std_logic;
    signal out_adr  : std_logic_vector(1  downto 0);
    signal out_dat  : std_logic_vector(31 downto 0);

    signal halt_acmp : std_logic;
    signal halt_stb  : std_logic;
    signal halt_ack  : std_logic;
    signal halt_dat  : std_logic;

    signal mem_acmp : std_logic;
    signal mem_stb  : std_logic;
    signal mem_ack  : std_logic;
    signal mem_adr  : std_logic_vector(19 downto 0);
    signal mem_dat  : std_logic_vector(31 downto 0);

begin

    out_acmp  <= '1' when cpu_adr(31 downto  4) = x"0000000" else '0';
    halt_acmp <= '1' when cpu_adr(31 downto  0) = x"00000010" else '0';
    mem_acmp  <= '1' when cpu_adr(31 downto 22) = b"0000000001" else '0';

    cpu_ack <= out_ack or mem_ack;
    cpu_drd <= out_dat when out_acmp = '1' else mem_dat when mem_acmp = '1' else (others => '0');

    out_stb  <= out_acmp and cpu_cyc and cpu_stb;
    halt_stb <= halt_acmp and cpu_cyc and cpu_stb;
    mem_stb  <= mem_acmp and cpu_cyc and cpu_stb;

    out_adr <= cpu_adr(3  downto 2);
    mem_adr <= cpu_adr(21 downto 2);

    control: syscon port map (
        halt  => halt,
        clk_o => clk,
        rst_o => rst
    );

    cpu: leaf generic map (
        RESET_ADDR => x"00400000"
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

    output: sim_out port map (
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

    sim_halt: halt_gen port map (
        clk_i => clk,
        rst_i => rst,
        dat_i => cpu_dwr,
        cyc_i => cpu_cyc,
        stb_i => halt_stb,
        we_i  => cpu_we,
        ack_o => halt_ack,
        halt  => halt
    );

    memory: sim_mem generic map (
        BITS    => 22,
        PROGRAM => BIN_FILE
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

end architecture rtl;