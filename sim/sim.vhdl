library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;
use work.sim_pkg.all;

entity sim is
    generic (
        BIN_FILE : string;
        OUT_FILE : string
    );
end entity sim;

architecture sim_arch of sim is
    
    signal clk        : std_logic;
    signal reset      : std_logic;
    signal imem_data  : std_logic_vector(31 downto 0);
    signal imem_addr  : std_logic_vector(31 downto 0);
    signal dmrw_addr  : std_logic_vector(31 downto 0);
    signal dmrd_data  : std_logic_vector(31 downto 0);
    signal dmwr_data  : std_logic_vector(31 downto 0);
    signal dmrd_en    : std_logic;
    signal dmwr_en    : std_logic;
    signal dm_byte_en : std_logic_vector(3  downto 0);
    signal ex_irq     : std_logic := '0';
    signal sw_irq     : std_logic := '0';
    signal tm_irq     : std_logic := '0';

    signal halt : std_logic;

    signal mem_acm : std_logic;
    signal out_acm : std_logic;
    signal ctr_acm : std_logic;

begin
    
    cpu: core port map (
        clk        => clk,
        reset      => reset,
        imem_data  => imem_data,
        imem_addr  => imem_addr,
        dmrd_data  => dmrd_data,
        dmwr_data  => dmwr_data,
        dmrd_en    => dmrd_en,
        dmwr_en    => dmwr_en,
        dmrw_addr  => dmrw_addr,
        dm_byte_en => dm_byte_en,
        ex_irq     => ex_irq,
        sw_irq     => sw_irq,
        tm_irq     => tm_irq
    );

    memory: sim_mem generic map (
        BITS    => 21,
        PROGRAM => BIN_FILE
    ) port map (
        clk        => clk,
        reset      => reset,
        wr_en      => mem_acm,
        rd_en      => dmrd_en,
        wr_byte_en => dm_byte_en,
        wr_data1   => dmwr_data,
        rw_addr0   => imem_addr(20 downto 2),
        rw_addr1   => dmrw_addr(20 downto 2),
        rd_data0   => imem_data,
        rd_data1   => dmrd_data
    );

    output: sim_out generic map (
        FILENAME => OUT_FILE
    ) port map (
        halt    => halt,
        clk     => clk,
        reset   => reset,
        wr_en   => out_acm,
        wr_data => dmwr_data
    );

    control: sim_ctrl port map (
        wr_en   => ctr_acm,
        wr_data => dmwr_data,
        halt    => halt,
        clk     => clk,
        reset   => reset
    );

    address: addr_comp port map (
        addr  => dmrw_addr,
        wr_en => dmwr_en,
        acm0  => mem_acm,
        acm1  => out_acm,
        acm2  => ctr_acm
    );

end architecture sim_arch;