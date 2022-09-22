----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: rom (bootloader) with wishbone interface
-- 2022
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity rom is
    generic (
        BITS: natural := 8
    );
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;
        cyc_i : in  std_logic;
        stb_i : in  std_logic;
        adr_i : in  std_logic_vector(BITS-3 downto 0);
        ack_o : out std_logic;
        dat_o : out std_logic_vector(31 downto 0)
    );
end entity rom;

architecture arch of rom is
	
	signal idle : std_logic;

    type mem_array is array (0 to 2**BITS/4-1) of std_logic_vector(31 downto 0);
	 
    constant mem: mem_array := (
        x"00000293",
        x"00000313",
        x"00000393",
        x"00000e13",
        x"000012b7",
        x"45828293",
        x"00501423",
        x"0ff00293",
        x"00500823",
        x"03100293",
        x"038000ef",
        x"fea29ee3",
        x"00f00293",
        x"00500823",
        x"000102b7",
        x"00010337",
        x"00530333",
        x"01c000ef",
        x"00a28023",
        x"00128293",
        x"fe629ae3",
        x"00000293",
        x"00500823",
        x"6a50f06f",
        x"00000393",
        x"00400e13",
        x"00004383",
        x"0043f393",
        x"ffc39ce3",
        x"00c00503",
        x"00008067",
        others => x"00000013"
    );
    
begin

	idle_reg: process(clk_i)
	begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                idle <= '1';
            elsif idle = '1' then
                idle <= not (cyc_i and stb_i);
            else
                idle <= '1';
            end if;
        end if;
	end process idle_reg;

    main: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                dat_o <= (others => '0');
            elsif idle = '1' and cyc_i = '1' and stb_i = '1' then
                dat_o <= mem(to_integer(unsigned(adr_i)));
            end if;
        end if;
    end process main;

    ack_o <= not idle;
    
end architecture arch;