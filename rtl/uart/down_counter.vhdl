library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity down_counter is
    generic(
        BITS: natural := 16
    );

    port (
        clr:  in std_logic;
        en:   in std_logic;
        mode: in std_logic;
        load: in std_logic_vector(BITS-1 downto 0);
        val:  out std_logic_vector(BITS-1 downto 0)
    );
end entity down_counter;

architecture down_counter_tb of down_counter is

    constant MIN_VAL: unsigned(BITS-1 downto 0) := (others => '0');
    
    signal inter_val: unsigned(BITS-1 downto 0);

begin
    
    main: process(clk, clr)
    begin
        
        if clr = '1' then
            
            inter_val <= (others => '1');

        elsif rising_edge(clk) then

            if en = '1' then
                
                if mode = '1' then
                    
                    inter_val <= unsigned(load);

                elsif inter_val = MIN_VAL then

                    inter_val <= (others => '1');

                else

                    inter_val <= inter_val - 1;

                end if;

            end if;
        
        end if;

    end process main;
    
end architecture down_counter_tb;