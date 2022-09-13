----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: ram with wishbone interface
-- 2022
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ram is
    generic (
        BITS : natural := 8
    );
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;
        dat_i : in  std_logic_vector(31 downto 0);
        cyc_i : in  std_logic;
        stb_i : in  std_logic;
        we_i  : in  std_logic;
        sel_i : in  std_logic_vector(3  downto 0);        
        adr_i : in  std_logic_vector(BITS-3 downto 0);
        ack_o : out std_logic;
        dat_o : out std_logic_vector(31 downto 0)
    );
end entity ram;

architecture rtl of ram is
    
    constant MEM_SIZE: natural := 2**BITS;

    type mem_array is array (0 to MEM_SIZE/4-1) of std_logic_vector(7 downto 0);

    signal mem0 : mem_array;
    signal mem1 : mem_array;
    signal mem2 : mem_array;
    signal mem3 : mem_array;

    signal ack : std_logic;
    
    signal mem0_ack : std_logic;
    signal mem1_ack : std_logic;
    signal mem2_ack : std_logic;
    signal mem3_ack : std_logic;

    signal mem0_we : std_logic;
    signal mem1_we : std_logic;
    signal mem2_we : std_logic;
    signal mem3_we : std_logic;

    signal mem0_en : std_logic;
    signal mem1_en : std_logic;
    signal mem2_en : std_logic;
    signal mem3_en : std_logic;

begin

    mem0_ack <= not ack and cyc_i and stb_i and sel_i(0);
    mem1_ack <= not ack and cyc_i and stb_i and sel_i(1);
    mem2_ack <= not ack and cyc_i and stb_i and sel_i(2);
    mem3_ack <= not ack and cyc_i and stb_i and sel_i(3);

    mem0_we <= mem0_ack and we_i;
    mem1_we <= mem1_ack and we_i;
    mem2_we <= mem2_ack and we_i;
    mem3_we <= mem3_ack and we_i;

    mem0_en <= mem0_ack and not we_i;
    mem1_en <= mem1_ack and not we_i;
    mem2_en <= mem2_ack and not we_i;
    mem3_en <= mem3_ack and not we_i;

    main: process(clk_i)
        variable addr: integer range 0 to MEM_SIZE/4-1;
    begin
        if rising_edge(clk_i) then
            addr := to_integer(unsigned(adr_i));

            if mem0_we = '1' then
                mem0(addr) <= dat_i(7 downto 0);
            end if;
            if mem1_we = '1' then
                mem1(addr) <= dat_i(15 downto 8);
            end if;
            if mem2_we = '1' then
                mem2(addr) <= dat_i(23 downto 16);
            end if;
            if mem3_we = '1' then
                mem3(addr) <= dat_i(31 downto 24);
            end if;

            if mem0_en = '1' then
                dat_o(7 downto 0) <= mem0(addr);
            end if;
            if mem1_en = '1' then
                dat_o(15 downto  8) <= mem1(addr);
            end if;
            if mem2_en = '1' then
                dat_o(23 downto 16) <= mem2(addr);
            end if;
            if mem3_en = '1' then
                dat_o(31 downto 24) <= mem3(addr);
            end if;
        end if;
    end process main;

    ack_reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                ack <= '0';
            elsif ack = '1' then
                ack <= not (cyc_i and stb_i);
            else
                ack <= cyc_i and stb_i;
            end if;
        end if;
    end process ack_reg;

    ack_o <= ack;

end architecture rtl;