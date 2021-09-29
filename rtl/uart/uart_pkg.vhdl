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

    component uart_rx is
        generic(
            UART_BAUD: integer
        );
    
        port (
            clk:     in std_logic;
            reset:   in std_logic;
            rx:      in std_logic;
            rd_data: out std_logic_vector(7 downto 0);
            rd_en:   out std_logic
        );
    end component uart_rx;

    component uart is
        generic (
            UART_BAUD: integer
        );
    
        port (
            clk:   in  std_logic;
            reset: in  std_logic;
            
            rd_en:   in  std_logic;
            rd_addr: in  std_logic_vector(1  downto 0);
            rd_data: out std_logic_vector(31 downto 0);
    
            wr_en:      in std_logic;
            wr_addr:    in std_logic_vector(1  downto 0);
            wr_data:    in std_logic_vector(31 downto 0);
            wr_byte_en: in std_logic_vector(3  downto 0);
    
            rx: in  std_logic;
            tx: out std_logic
        );
    end component uart;
    
end package uart_pkg;