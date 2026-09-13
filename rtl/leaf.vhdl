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
        cop_dat_i   : in  std_logic_vector(XLEN-1 downto 0) := (others => '0');
        cop_adr_o   : out std_logic_vector(5 downto 0);
        cop_dat_o   : out std_logic_vector(XLEN-1 downto 0);
        cop_we_o    : out std_logic;

        -- Instruction Wishbone master
        inst_cyc_o  : out std_logic;
        inst_stb_o  : out std_logic;
        inst_adr_o  : out std_logic_vector(XLEN-1 downto 2);
        inst_dat_i  : in  std_logic_vector(XLEN-1 downto 0);
        inst_ack_i  : in  std_logic;
        inst_err_i  : in  std_logic;
        inst_stall_i : in  std_logic;

        -- Data Wishbone master
        data_cyc_o  : out std_logic;
        data_stb_o  : out std_logic;
        data_we_o   : out std_logic;
        data_sel_o  : out std_logic_vector(3 downto 0);
        data_adr_o  : out std_logic_vector(XLEN-1 downto 2);
        data_dat_o  : out std_logic_vector(XLEN-1 downto 0);
        data_dat_i  : in  std_logic_vector(XLEN-1 downto 0);
        data_ack_i  : in  std_logic;
        data_err_i  : in  std_logic;
        data_stall_i : in  std_logic
    );
end entity leaf;

architecture rtl of leaf is

    signal cycle   : std_logic_vector(63 downto 0);
    signal timer   : std_logic_vector(63 downto 0);
    signal instret : std_logic_vector(63 downto 0);
    signal retire  : std_logic;

begin

    leaf_counters: counters port map (
        clk_i     => clk_i,
        reset_i   => rst_i,
        retire_i  => retire,
        cycle_o   => cycle,
        timer_o   => timer,
        instret_o => instret
    );

    leaf_core: core generic map (
        RESET_ADDR    => RESET_ADDR,
        CSRS_MHART_ID => CSRS_MHART_ID,
        REG_FILE_SIZE => REG_FILE_SIZE
    ) port map (
        clk_i        => clk_i,
        reset_i      => rst_i,
        ex_irq_i     => ex_irq_i,
        sw_irq_i     => sw_irq_i,
        tm_irq_i     => tm_irq_i,

        cycle_i      => cycle,
        timer_i      => timer,
        instret_i    => instret,
        retire_o     => retire,

        cop_dat_i    => cop_dat_i,
        cop_adr_o    => cop_adr_o,
        cop_dat_o    => cop_dat_o,
        cop_we_o     => cop_we_o,

        inst_cyc_o   => inst_cyc_o,
        inst_stb_o   => inst_stb_o,
        inst_adr_o   => inst_adr_o,
        inst_dat_i   => inst_dat_i,
        inst_ack_i   => inst_ack_i,
        inst_err_i   => inst_err_i,
        inst_stall_i => inst_stall_i,

        data_cyc_o   => data_cyc_o,
        data_stb_o   => data_stb_o,
        data_we_o    => data_we_o,
        data_sel_o   => data_sel_o,
        data_adr_o   => data_adr_o,
        data_dat_o   => data_dat_o,
        data_dat_i   => data_dat_i,
        data_ack_i   => data_ack_i,
        data_err_i   => data_err_i,
        data_stall_i => data_stall_i
    );

end architecture rtl;
