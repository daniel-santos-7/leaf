library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use work.core_pkg.all;
use work.tbs_pkg.all;
use std.textio.all;

entity leaf_tb is
    generic (
        PROGRAM : string
    );
end entity leaf_tb;

architecture leaf_tb_arch of leaf_tb is

    -- DUT inputs --
    signal clk_i  : std_logic;
    signal rst_i  : std_logic;
    signal ex_irq : std_logic;
    signal sw_irq : std_logic;
    signal tm_irq : std_logic;
    signal ack_i  : std_logic;
    signal err_i  : std_logic;
    signal dat_i  : std_logic_vector(31 downto 0);
    
    -- DUT outputs --
    signal cyc_o  : std_logic;
    signal stb_o  : std_logic;
    signal we_o   : std_logic;
    signal sel_o  : std_logic_vector(3  downto 0);
    signal adr_o  : std_logic_vector(31 downto 0);
    signal dat_o  : std_logic_vector(31 downto 0);

    signal sim_started  : boolean := false;
    signal sim_finished : boolean := false;

begin
    
    uut: leaf port map (
        clk_i  => clk_i,
        rst_i  => rst_i,
        ex_irq => ex_irq,
        sw_irq => sw_irq,
        tm_irq => tm_irq,
        ack_i  => ack_i,
        err_i  => err_i,
        dat_i  => dat_i,
        cyc_o  => cyc_o,
        stb_o  => stb_o,
        we_o   => we_o,
        sel_o  => sel_o,
        adr_o  => adr_o,
        dat_o  => dat_o
    );

    mem: wb_ram generic map (
        BITS    => 22,
        PROGRAM => PROGRAM
    ) port map (
        clk_i => clk_i,
        rst_i => rst_i,
        dat_i => dat_o,
        cyc_i => cyc_o,
        stb_i => stb_o,
        we_i  => we_o,
        sel_i => sel_o,        
        adr_i => adr_o(21 downto 2),
        ack_o => ack_i,
        dat_o => dat_i
    );

    clk_i <= not clk_i after 5 ns when sim_started and not sim_finished else '0';
    
    rst_i <= '0' after 10 ns when sim_started else '1';

    ex_irq <= '0';
    sw_irq <= '0';
    tm_irq <= '0';
    err_i  <= '0';

    process
    begin
        sim_started <= true;
        wait for 1000 ns;
        sim_finished <= true;
        wait;
    end process;

end architecture leaf_tb_arch;