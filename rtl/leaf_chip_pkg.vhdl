library IEEE;
use IEEE.std_logic_1164.all;

package leaf_chip_pkg is
    
    component rom is
        generic (
            BITS: natural := 8
        );
    
        port (
            addr: in  std_logic_vector(BITS-3  downto 0);
            dout: out std_logic_vector(31 downto 0)
        );
    end component rom;

    component ram is
    
        generic (
            MEM_SIZE:  natural := 256;
            ADDR_BITS: natural := 8
        );
    
        port (
            clk: in std_logic;
            
            rd_addr0: in  std_logic_vector(ADDR_BITS-1 downto 0);
            rd_data0: out std_logic_vector(31 downto 0);
    
            rd_addr1: in  std_logic_vector(ADDR_BITS-1 downto 0);
            rd_data1: out std_logic_vector(31 downto 0);
    
            wr_addr:    in  std_logic_vector(ADDR_BITS-1 downto 0);
            wr_data:    in  std_logic_vector(31 downto 0);
            wr_byte_en: in  std_logic_vector(3  downto 0);
            wr_en:      in  std_logic
        );
    
    end component ram;

    component spi is
    
        port (
            clk:   in std_logic;
            reset: in std_logic; 
            
            rd_addr: in  std_logic_vector(1  downto 0);
            rd_data: out std_logic_vector(31 downto 0);
    
            wr_addr:    in std_logic_vector(1  downto 0);
            wr_data:    in std_logic_vector(31 downto 0);
            wr_byte_en: in std_logic_vector(3  downto 0);
            wr_en:      in std_logic;
    
            sdo:  out std_logic;
            sdi:  in  std_logic;
            sclk: out std_logic;
            cs:   out std_logic
        );
    
    end component spi;

    component uart_rx is

        generic(
            UART_BAUD: integer
        );
    
        port (
            clk:    in std_logic;
            reset:  in std_logic;
            rx:     in std_logic;
    
            rd_en: out std_logic;
            rdata: out std_logic_vector(7 downto 0)
        );
    
    end component uart_rx;

    component uart_tx is

        generic(
            UART_BAUD: integer
        );
    
        port (
            clk:   in  std_logic;
            reset: in  std_logic;
            wr:    in  std_logic;
            wr_en: out std_logic;
            tx:    out std_logic;
            wdata: in  std_logic_vector(7 downto 0)
        );
    end component uart_tx;

    component core is
    
        generic (
            RESET_ADDR: std_logic_vector(31 downto 0) := (others => '0')
        );
        
        port (
            clk:   in std_logic; 
            reset: in std_logic;
            
            rd_instr_mem_data: in  std_logic_vector(31 downto 0);
            rd_instr_mem_addr: out std_logic_vector(31 downto 0);
            
            rd_mem_data: in  std_logic_vector(31 downto 0);
            wr_mem_data: out std_logic_vector(31 downto 0);
            
            rd_mem_en: out std_logic;
            wr_mem_en: out std_logic;
            
            rd_wr_mem_addr: out std_logic_vector(31 downto 0);
            wr_mem_byte_en: out std_logic_vector(3 downto 0);
    
            ex_irq: in std_logic;
            sw_irq: in std_logic;
            tm_irq: in std_logic
        );
    
    end component core;

    component leaf_chip is

        generic (
            UART_BAUD: integer := 5802
        );
        
        port (
            clk:   in  std_logic;
            reset: in  std_logic;
            rx:    in  std_logic;
            tx:    out std_logic
        );
    
    end component leaf_chip;
    
end package leaf_chip_pkg;