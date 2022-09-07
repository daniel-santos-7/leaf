library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sipo is
    generic(
        BITS: natural
    );

    port (
        clk:  in  std_logic;
        clr:  in  std_logic;
        en:   in  std_logic;
        ser:  in  std_logic;
        val:  out std_logic_vector(BITS-1 downto 0)
    );
end entity sipo;

architecture sipo_arch of sipo is
    
    signal inter_val: std_logic_vector(BITS-1 downto 0);

begin
    
    main: process(clk, clr)
    begin
        
        if clr = '1' then
            
            inter_val <= (others => '1');

        elsif rising_edge(clk) then

            if en = '1' then

                inter_val <= ser & inter_val(BITS-1 downto 1);

            end if;

        end if;

    end process main;

    val <= inter_val;
    
end architecture sipo_arch;