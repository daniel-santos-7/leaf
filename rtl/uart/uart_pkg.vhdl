library IEEE;
use IEEE.std_logic_1164.all;

package uart_pkg is

    component down_counter is
        generic(
            BITS: natural := 16
        );
        
        port (
            clk:  in std_logic;
            clr:  in std_logic;
            en:   in std_logic;
            mode: in std_logic;
            load: in std_logic_vector(BITS-1 downto 0);
            val:  out std_logic_vector(BITS-1 downto 0)
        );
    end component down_counter;

    component fifo is
        generic (
            SIZE: natural := 32;
            BITS: natural := 8 
        );
    
        port (
            clk:   in std_logic;
            reset: in std_logic;
    
            wr:      in  std_logic;
            wr_en:   out std_logic;
            wr_data: in  std_logic_vector(BITS-1 downto 0);
    
            rd:       in  std_logic;
            rd_en:    out std_logic;
            rd_data:  out std_logic_vector(BITS-1 downto 0)
        );
    end component fifo;

    component piso is
        generic(
            BITS: natural
        );
    
        port (
            clk:  in  std_logic;
            clr:  in  std_logic;
            en:   in  std_logic;
            mode: in  std_logic;
            load: in  std_logic_vector(BITS-1 downto 0);
            ser:  out std_logic
        );
    end component piso;

    component sipo is
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
    end component sipo;
    
    component uart_tx is
        port (
            clk:      in  std_logic;
            reset:    in  std_logic;
            baud_div: in  std_logic_vector(15 downto 0);
            rd:       out std_logic;
            rd_en:    in  std_logic;
            rd_data:  in  std_logic_vector(7 downto 0);
            busy:     out std_logic;
            tx:       out std_logic
        );
    end component uart_tx;

    component uart_rx is
        port (
            clk:      in  std_logic;
            reset:    in  std_logic;
            baud_div: in  std_logic_vector(15 downto 0);
            wr:       out std_logic;
            wr_en:    in  std_logic;
            wr_data:  out std_logic_vector(7 downto 0);
            busy:     out std_logic;
            rx:       in  std_logic
        );
    end component uart_rx;

    component uart is
        port (
            clk:   in  std_logic;
            reset: in  std_logic;

            rd:      in  std_logic;
            rd_addr: in  std_logic_vector(1  downto 0);
            rd_data: out std_logic_vector(15 downto 0);

            wr:      in std_logic;
            wr_addr: in std_logic_vector(1  downto 0);
            wr_data: in std_logic_vector(15 downto 0);

            rx: in  std_logic;
            tx: out std_logic
        );
    end component uart;
    
end package uart_pkg;