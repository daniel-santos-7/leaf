----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: leaf cpu with wishbone interface
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;

entity leaf is
    generic (
        RESET_ADDR : std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;
        ack_i : in  std_logic;
        dat_i : in  std_logic_vector(31 downto 0);
        cyc_o : out std_logic;
        stb_o : out std_logic;
        we_o  : out std_logic;
        sel_o : out std_logic_vector(3  downto 0);
        adr_o : out std_logic_vector(31 downto 0);
        dat_o : out std_logic_vector(31 downto 0)
    );
end entity leaf;

architecture leaf_arch of leaf is
    
    -- internal clock and reset
    signal clk   : std_logic;
    signal reset : std_logic;

    -- instruction memory signals --
    signal imrd_data : std_logic_vector(31 downto 0);
    signal imrd_addr : std_logic_vector(31 downto 0);
    signal imrd_en   : std_logic;

    -- data memory signals --
    signal dmrd_data : std_logic_vector(31 downto 0);
    signal dmwr_data : std_logic_vector(31 downto 0);
    signal dmrd_en   : std_logic;
    signal dmwr_en   : std_logic;
    signal dmrw_addr : std_logic_vector(31 downto 0);
    signal dmrw_be: std_logic_vector(3  downto 0);

    -- interruptions --
    signal ex_irq : std_logic;
    signal sw_irq : std_logic;
    signal tm_irq : std_logic;

begin

    imrd_en <= not rst_i;

    ex_irq <= '0';
    sw_irq <= '0';
    tm_irq <= '0';

    leaf_master: wb_ctrl port map (
        clk_i     => clk_i,
        rst_i     => rst_i,
        ack_i     => ack_i,
        dat_i     => dat_i,
        imrd_en   => imrd_en,
        dmrd_en   => dmrd_en,
        dmwr_en   => dmwr_en,
        dmrw_be   => dmrw_be,
        imrd_addr => imrd_addr,
        dmrw_addr => dmrw_addr,
        dmwr_data => dmwr_data,
        cyc_o     => cyc_o,
        stb_o     => stb_o,
        we_o      => we_o,
        sel_o     => sel_o,
        adr_o     => adr_o,
        dat_o     => dat_o,
        clk       => clk,
        reset     => reset,
        imrd_data => imrd_data,
        dmrd_data => dmrd_data
    );
    
    leaf_core: core generic map (
        RESET_ADDR  => RESET_ADDR
    ) port map (
        clk         => clk, 
        reset       => reset,
        imem_data   => imrd_data,
        imem_addr   => imrd_addr,
        dmrd_data   => dmrd_data,
        dmwr_data   => dmwr_data,
        dmrd_en     => dmrd_en,
        dmwr_en     => dmwr_en,
        dmrw_addr   => dmrw_addr,
        dm_byte_en  => dmrw_be,
        ex_irq      => ex_irq,
        sw_irq      => sw_irq,
        tm_irq      => tm_irq
    );
    
end architecture leaf_arch;