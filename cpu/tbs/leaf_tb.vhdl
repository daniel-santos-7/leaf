----------------------------------------------------------------------
-- Project: Leaf
-- Developed by: Daniel Santos
-- Module: Leaf testbench.
-- Date: 2026
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;
use work.leaf_tb_pkg.all;

entity leaf_tb is
    generic (
        PROGRAM   : string;
        DUMP_FILE : string
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

    signal wr_mem_i : std_logic;
    signal rd_mem_i : std_logic;
    signal halt_o   : std_logic;

    -- Clock enable signal --
    signal clk_en : std_logic;

begin

    uut: leaf generic map (
        RESET_ADDR => RESET_ADDR
    ) port map (
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
        PROGRAM  => PROGRAM,
        DUMP_FILE => DUMP_FILE
    ) port map (
        clk_i => clk_i,
        rst_i => rst_i,
        dat_i => dat_o,
        cyc_i => cyc_o,
        stb_i => stb_o,
        we_i  => we_o,
        sel_i => sel_o,
        adr_i => adr_o,
        ack_o => ack_i,
        dat_o => dat_i,
        wr_mem_i => wr_mem_i,
        rd_mem_i => rd_mem_i,
        halt_o   => halt_o
    );

    clk_i <= not clk_i after (CLK_PERIOD/2) when clk_en = '1' else '0';

    ex_irq <= '0';
    sw_irq <= '0';
    tm_irq <= '0';
    err_i  <= '0';

    test: process
    begin
        rst_i <= '1';
        clk_en <= '1';
        wr_mem_i <= '0';
        rd_mem_i <= '0';

        wait until rising_edge(clk_i);
        rd_mem_i <= '1';

        wait until rising_edge(clk_i);
        rd_mem_i <= '0';
        rst_i <= '0';

        loop
            wait until rising_edge(clk_i);
            exit when halt_o = '1';
        end loop;

        wait until rising_edge(clk_i);
        wr_mem_i <= '1';

        wait until rising_edge(clk_i);
        wr_mem_i <= '0';
        clk_en <= '0';

        wait;
    end process test;

end architecture leaf_tb_arch;
