----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: leaf cpu with wishbone interface
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

entity leaf is
    generic (
        RESET_ADDR    : std_logic_vector(XLEN-1 downto 0) := (others => '0');
        CSRS_MHART_ID : std_logic_vector(XLEN-1 downto 0) := (others => '0');
        REG_FILE_SIZE : natural := 32
    );
    port (
        clk_i       : in  std_logic;
        rst_i       : in  std_logic;
        ex_irq_i    : in  std_logic;
        sw_irq_i    : in  std_logic;
        tm_irq_i    : in  std_logic;
        ack_i       : in  std_logic;
        err_i       : in  std_logic;
        dat_i       : in  std_logic_vector(XLEN-1 downto 0);
        cop_dat_i   : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o   : out std_logic_vector(5 downto 0);
        cop_dat_o   : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o    : out std_logic;
        cyc_o       : out std_logic;
        stb_o       : out std_logic;
        we_o        : out std_logic;
        sel_o       : out std_logic_vector(3         downto 0);
        adr_o       : out std_logic_vector(XLEN-1 downto 2);
        dat_o       : out std_logic_vector(XLEN-1 downto 0)
    );
end entity leaf;

architecture rtl of leaf is

    -- instruction fetch Wishbone signals --

    signal inst_cyc_o : std_logic;
    signal inst_stb_o : std_logic;
    signal inst_adr   : std_logic_vector(XLEN-1 downto 2);
    signal inst_ack   : std_logic;
    signal inst_err   : std_logic;
    signal inst_dat   : std_logic_vector(XLEN-1 downto 0);

    -- data memory signals --

    signal data_cyc   : std_logic;
    signal data_stb   : std_logic;
    signal data_ack   : std_logic;
    signal data_err   : std_logic;
    signal data_sel   : std_logic_vector(3  downto 0);
    signal data_we    : std_logic;
    signal data_adr : std_logic_vector(XLEN-1 downto 2);
    signal data_dat_from_core : std_logic_vector(XLEN-1 downto 0);
    signal data_dat           : std_logic_vector(XLEN-1 downto 0);

    -- counters --

    signal cycle   : std_logic_vector(63 downto 0);
    signal timer   : std_logic_vector(63 downto 0);
    signal instret : std_logic_vector(63 downto 0);

    -- retire signal (core -> counters) --

    signal retire : std_logic;

begin

    -- counters --

    leaf_counters: counters port map (
        clk_i     => clk_i,
        reset_i   => rst_i,
        retire_i  => retire,
        cycle_o   => cycle,
        timer_o   => timer,
        instret_o => instret
    );

    -- leaf core --

    leaf_core: core generic map (
        RESET_ADDR    => RESET_ADDR,
        CSRS_MHART_ID => CSRS_MHART_ID,
        REG_FILE_SIZE => REG_FILE_SIZE
    ) port map (
        clk_i       => clk_i,
        reset_i     => rst_i,
        ex_irq_i    => ex_irq_i,
        sw_irq_i    => sw_irq_i,
        tm_irq_i    => tm_irq_i,
        inst_err_i  => inst_err,
        inst_ack_i  => inst_ack,
        inst_dat_i  => inst_dat,
        inst_cyc_o  => inst_cyc_o,
        inst_stb_o  => inst_stb_o,
        inst_adr_o  => inst_adr,
        data_dat_i => data_dat,
        data_ack_i => data_ack,
        data_err_i => data_err,
        cycle_i     => cycle,
        timer_i     => timer,
        instret_i   => instret,
        cop_dat_i   => cop_dat_i,
        cop_adr_o   => cop_adr_o,
        cop_dat_o   => cop_dat_o,
        cop_we_o    => cop_we_o,
        retire_o    => retire,
        data_cyc_o  => data_cyc,
        data_stb_o  => data_stb,
        data_we_o   => data_we,
        data_sel_o  => data_sel,
        data_adr_o => data_adr,
        data_dat_o => data_dat_from_core
    );

    leaf_wb_arbiter: wb_arbiter port map (
        clk_i      => clk_i,
        rst_i      => rst_i,
        inst_cyc_i => inst_cyc_o,
        inst_stb_i => inst_stb_o,
        inst_adr_i => inst_adr,
        inst_ack_o => inst_ack,
        inst_err_o => inst_err,
        data_cyc_i => data_cyc,
        data_stb_i => data_stb,
        data_adr_i => data_adr,
        data_sel_i => data_sel,
        data_we_i  => data_we,
        data_dat_i => data_dat_from_core,
        data_ack_o => data_ack,
        data_err_o => data_err,
        cyc_o      => cyc_o,
        stb_o      => stb_o,
        adr_o      => adr_o,
        sel_o      => sel_o,
        we_o       => we_o,
        dat_o      => dat_o,
        ack_i      => ack_i,
        err_i      => err_i,
        dat_i      => dat_i,
        inst_dat_o => inst_dat,
        data_dat_o => data_dat
    );

end architecture rtl;
