library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity debug_reg is
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;
        dat_i : in  std_logic_vector(7 downto 0);
        cyc_i : in  std_logic;
        stb_i : in  std_logic;
        we_i  : in  std_logic;
        ack_o : out std_logic;
        dat_o : out std_logic_vector(7 downto 0)
    );
end entity debug_reg;

architecture arch of debug_reg is
    
    signal en : std_logic;

    signal value : std_logic_vector(7 downto 0);

begin
    
    en <= cyc_i and stb_i;

    reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                value <= (others => '0');
            elsif en = '1' and we_i = '1' then
                value <= dat_i;
            end if;
        end if;
    end process reg;

    dat_o <= value;
    ack_o <= en;
    
end architecture arch;