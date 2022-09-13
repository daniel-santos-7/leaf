----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: ram testbench
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.leaf_soc_pkg.all;

entity ram_tb is
end entity ram_tb;

architecture sim of ram_tb is

    constant CLK_PERIOD : time := 20 ns;

    signal clk_i : std_logic;
    signal rst_i : std_logic;
    signal dat_i : std_logic_vector(31 downto 0);
    signal cyc_i : std_logic;
    signal stb_i : std_logic;
    signal we_i  : std_logic;
    signal sel_i : std_logic_vector(3 downto 0);
    signal adr_i : std_logic_vector(1 downto 0);
    signal ack_o : std_logic;
    signal dat_o : std_logic_vector(31 downto 0);

begin
    
    uut: ram generic map (
        BITS => 4
    ) port map (
        clk_i => clk_i,
        rst_i => rst_i,
        dat_i => dat_i,
        cyc_i => cyc_i,
        stb_i => stb_i,
        we_i  => we_i,
        sel_i => sel_i,       
        adr_i => adr_i,
        ack_o => ack_o,
        dat_o => dat_o
    );

    clk_gen: process
    begin
        clk_i <= '0';
        for i in 0 to 15 loop
            wait for CLK_PERIOD/2;
            clk_i <= not clk_i;
        end loop;
        wait;
    end process clk_gen;

    rst_gen: process
    begin
        rst_i <= '1';
        wait for CLK_PERIOD;
        rst_i <= '0';
        wait;
    end process rst_gen;

    test: process
    begin
        dat_i <= (others => '0');
        cyc_i <= '0';
        stb_i <= '0';
        we_i  <= '0';
        sel_i <= (others => '0');
        adr_i <= (others => '0');

        wait until rising_edge(clk_i) and rst_i = '0';

        dat_i <= (others => '1');
        cyc_i <= '1';
        stb_i <= '1';
        we_i  <= '1';
        sel_i <= b"0001";
        adr_i <= b"00";

        wait until rising_edge(clk_i) and ack_o = '1';

        dat_i <= (others => '1');
        cyc_i <= '1';
        stb_i <= '0';
        we_i  <= '0';
        sel_i <= b"0001";
        adr_i <= b"00";

        wait until rising_edge(clk_i);

        dat_i <= (others => '1');
        cyc_i <= '1';
        stb_i <= '1';
        we_i  <= '0';
        sel_i <= b"0001";
        adr_i <= b"00";

        wait until rising_edge(clk_i) and ack_o = '1';

        dat_i <= (others => '1');
        cyc_i <= '0';
        stb_i <= '0';
        we_i  <= '0';
        sel_i <= b"0001";
        adr_i <= b"00";

        assert dat_o(7 downto 0) = x"FF" report "expected: data_o = xFF" severity note;

        wait;
    end process test;

end architecture sim;