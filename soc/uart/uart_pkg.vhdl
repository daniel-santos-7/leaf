library IEEE;
use IEEE.std_logic_1164.all;

package uart_pkg is
    
    component uart_tx is
        generic(
            UART_BAUD: integer
        );
    
        port (
            clk:     in  std_logic;
            reset:   in  std_logic;
            wr:      in  std_logic;
            wr_data: in  std_logic_vector(7 downto 0);
            wr_en:   out std_logic;
            tx:      out std_logic
        );
    end component uart_tx;
    
end package uart_pkg;