library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;
use work.sim_pkg.all;

entity sim is
    generic (
        BIN_FILE : string
    );
end entity sim;

architecture sim_arch of sim is
    
    signal halt : std_logic;
    signal clk  : std_logic;
    signal rst  : std_logic;

    signal halt_acmp : std_logic;
    signal out_acmp  : std_logic;
    signal mem_acmp  : std_logic;

    signal cpu_ack : std_logic;
    signal cpu_cyc : std_logic;
    signal cpu_stb : std_logic;
    signal cpu_we  : std_logic;
    signal cpu_sel : std_logic_vector(3  downto 0);
    signal cpu_adr : std_logic_vector(31 downto 0);
    signal cpu_drd : std_logic_vector(31 downto 0);
    signal cpu_dwr : std_logic_vector(31 downto 0);

    signal halt_stb : std_logic;
    signal out_stb  : std_logic;
    signal mem_stb  : std_logic;

    signal halt_ack : std_logic;
    signal out_ack  : std_logic;
    signal mem_ack  : std_logic;

begin
    
    halt_stb <= halt_acmp and cpu_cyc and cpu_stb;
    out_stb  <= out_acmp  and cpu_cyc and cpu_stb;
    mem_stb  <= mem_acmp  and cpu_cyc and cpu_stb;

    cpu_ack <= halt_ack or out_ack or mem_ack;

    control: syscon port map (
        halt_i => halt,
        clk_o  => clk,
        rst_o  => rst
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

    address: addr_comp port map (
        addr   => cpu_adr,
        acmp0  => halt_acmp,
        acmp1  => out_acmp,
        acmp2  => mem_acmp
    );

    haltsim: halt_gen port map (
        clk_i  => clk,
        rst_i  => rst,
        dat_i  => cpu_dwr,
        cyc_i  => cpu_cyc,
        stb_i  => halt_stb,
        we_i   => cpu_we,
        ack_o  => halt_ack,
        halt_o => halt
    );

    output: sim_out port map (
        halt_i => halt,
        clk_i  => clk,
        rst_i  => rst,
        dat_i  => cpu_dwr,
        cyc_i  => cpu_cyc,
        stb_i  => out_stb,
        we_i   => cpu_we,
        sel_i  => cpu_sel,     
        ack_o  => out_ack
    );

    -- memory 4 MB --
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
        adr_i => cpu_adr(21 downto 2),
        ack_o => mem_ack,
        dat_o => cpu_drd
    );

end architecture sim_arch;