----------------------------------------------------------------------
-- Project: Leaf
-- Developed by: Daniel Santos
-- Module: Leaf testbench.
-- Date: 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_pkg.all;
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
    signal cop_dat_i : std_logic_vector(31 downto 0);
    signal cop_adr_o : std_logic_vector(5 downto 0);
    signal cop_dat_o : std_logic_vector(31 downto 0);
    signal cop_we_o  : std_logic;
    signal wr_mem_i : std_logic;
    signal rd_mem_i : std_logic;
    signal halt_o   : std_logic;

    -- Instruction Wishbone (leaf -> arbiter)
    signal inst_cyc : std_logic;
    signal inst_stb : std_logic;
    signal inst_adr : std_logic_vector(31 downto 2);
    signal inst_dat : std_logic_vector(31 downto 0);
    signal inst_ack : std_logic;
    signal inst_err : std_logic;
    signal inst_stall : std_logic;

    -- Data Wishbone (leaf -> arbiter)
    signal data_cyc : std_logic;
    signal data_stb : std_logic;
    signal data_adr : std_logic_vector(31 downto 2);
    signal data_sel : std_logic_vector(3 downto 0);
    signal data_we  : std_logic;
    signal data_dat : std_logic_vector(31 downto 0);
    signal data_dat_to_core : std_logic_vector(31 downto 0);
    signal data_ack : std_logic;
    signal data_err : std_logic;
    signal data_stall : std_logic;

    -- Clock enable signal --
    signal clk_en : std_logic;

begin

    uut: leaf generic map (
        RESET_ADDR => RESET_ADDR
    ) port map (
        clk_i       => clk_i,
        rst_i       => rst_i,
        ex_irq_i    => ex_irq,
        sw_irq_i    => sw_irq,
        tm_irq_i    => tm_irq,
        cop_dat_i   => cop_dat_i,
        cop_adr_o   => cop_adr_o,
        cop_dat_o   => cop_dat_o,
        cop_we_o    => cop_we_o,
        inst_cyc_o  => inst_cyc,
        inst_stb_o  => inst_stb,
        inst_adr_o  => inst_adr,
        inst_dat_i  => inst_dat,
        inst_ack_i  => inst_ack,
        inst_err_i  => inst_err,
        inst_stall_i => inst_stall,
        data_cyc_o  => data_cyc,
        data_stb_o  => data_stb,
        data_we_o   => data_we,
        data_sel_o  => data_sel,
        data_adr_o  => data_adr,
        data_dat_o  => data_dat,
        data_dat_i  => data_dat_to_core,
        data_ack_i  => data_ack,
        data_err_i  => data_err,
        data_stall_i => data_stall
    );
    
    mem: wb_ram_dual generic map (
        PROGRAM  => PROGRAM,
        DUMP_FILE => DUMP_FILE
    ) port map (
        clk_i    => clk_i,
        rst_i    => rst_i,

        inst_cyc_i => inst_cyc,
        inst_stb_i => inst_stb,
        inst_adr_i => inst_adr,
        inst_dat_o => inst_dat,
        inst_ack_o => inst_ack,

        data_cyc_i => data_cyc,
        data_stb_i => data_stb,
        data_adr_i => data_adr,
        data_sel_i => data_sel,
        data_we_i  => data_we,
        data_dat_i => data_dat,
        data_dat_o => data_dat_to_core,
        data_ack_o => data_ack,

        wr_mem_i => wr_mem_i,
        rd_mem_i => rd_mem_i,
        halt_o   => halt_o
    );

    clk_i <= not clk_i after (CLK_PERIOD/2) when clk_en = '1' else '0';

    ex_irq <= '0';
    sw_irq <= '0';
    tm_irq <= '0';
    inst_err <= '0';
    data_err <= '0';
    inst_stall <= '0';
    data_stall <= '0';
    cop_dat_i <= (others => '0');

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
