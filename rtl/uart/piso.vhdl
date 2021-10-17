library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity piso is
    generic(
        BITS: natural
    );

    port (
        clk:  in  std_logic;
        clr:  in  std_logic;
        en:   in  std_logic;
        mode: in  std_logic;
        load: in  std_logic_vector(BITS-1 downto 0);
        ser:  out std_logic;
    );
end entity piso;

architecture piso_arch of piso is
    
    signal val: std_logic_vector(BITS-1 downto 0);

begin
    
    main: process(clk, clr)
    begin
        
        if clr = '1' then
            
            val <= (others => '1');

        elsif rising_edge(clk) then

            if en = '1' then
                
                if mode = '1' then
                    
                    val <= load;

                else

                    val <= '1' & piso_val(BITS-1 downto 1);

                end if;

            end if;

        end if;

    end process main;

    ser <= val(0);
    
end architecture piso_arch;