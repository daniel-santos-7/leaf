library IEEE;
use IEEE.std_logic_1164.all;

entity halt_gen is
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;
        dat_i : in  std_logic_vector(31 downto 0);
        cyc_i : in  std_logic;
        stb_i : in  std_logic;
        we_i  : in  std_logic;
        ack_o : out std_logic;
        halt  : out std_logic
    );
end entity halt_gen;

architecture rtl of halt_gen is

    signal ack : std_logic;
    signal we  : std_logic;

    constant HALT_CMD : std_logic_vector(31 downto 0) := x"00000001";

begin
    
    ack <= cyc_i and stb_i;
    we  <= ack and we_i;

    main: process(rst_i, clk_i)
    begin
        if rst_i = '1' then
            halt <= '0';
        elsif rising_edge(clk_i) then
            if we = '1' and dat_i = HALT_CMD then
                halt <= '1';                    
            end if;
        end if;
    end process main;

    ack_o <= ack;

end architecture rtl;