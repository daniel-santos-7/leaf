library IEEE;
use IEEE.std_logic_1164.all;

entity sim_ctrl is
    generic (
        CLK_PERIOD : time := 20 ns
    );
    port (
        wr_en   : in  std_logic;
        wr_data : in  std_logic_vector(31 downto 0);
        halt    : out std_logic;
        clk     : out std_logic;
        reset   : out std_logic
    );
end entity sim_ctrl;

architecture sim_ctrl_arch of sim_ctrl is
    
    signal ihalt  : std_logic;
    signal iclk   : std_logic;
    signal ireset : std_logic;

    constant HALT_CMD : std_logic_vector(31 downto 0) := x"00000001";

begin
    
    halt_gen: process(iclk, ireset)
    begin
        if ireset = '1' then
            ihalt <= '0';
        elsif rising_edge(iclk) then
            if wr_en = '1' and wr_data = HALT_CMD then
                ihalt <= '1';
            end if;
        end if;
    end process halt_gen;

    ireset <= '1', '0' after CLK_PERIOD;

    iclk <= not iclk after (CLK_PERIOD/2) when ihalt = '0' else '0';
    
    halt  <= ihalt;
    clk   <= iclk;
    reset <= ireset;

end architecture sim_ctrl_arch;