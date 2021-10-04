library IEEE;
use IEEE.std_logic_1164.all;
use work.uart_pkg.all;

entity uart is
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
end entity uart;

architecture uar_arch of uart is

    constant STATUS_ADDR: std_logic_vector(1 downto 0) := b"00";
    constant CTRL_ADDR:   std_logic_vector(1 downto 0) := b"01";
    constant RX_ADDR:     std_logic_vector(1 downto 0) := b"10";
    constant TX_ADDR:     std_logic_vector(1 downto 0) := b"11";

    signal status_reg: std_logic_vector(31 downto 0);
    signal ctrl_reg:   std_logic_vector(31 downto 0);
    signal rx_reg:     std_logic_vector(31 downto 0);
    signal tx_reg:     std_logic_vector(31 downto 0);

    signal tx_wr:      std_logic;
    signal rx_rd_en:   std_logic;
    signal tx_wr_en:   std_logic;
    signal rx_rd_data: std_logic_vector(7 downto 0);
    signal tx_wr_data: std_logic_vector(7 downto 0);
    
begin

    ------------------- read module registers ----------------------------

    status_reg <= x"0000" & (7 downto 0 => tx_wr_en) & (7 downto 0 => rx_rd_en);

    ctrl_reg <= (others => '0');
    
    rx_reg <= x"000000" & rx_rd_data;

    wr_reg: process(reset, clk)
    begin
        
        if reset = '1' then
            
            tx_reg <= (others => '0');

        elsif rising_edge(clk) then
            
            if wr_en = '1' and wr_addr = TX_ADDR then
                
                tx_reg <= wr_data;

            end if;

        end if;

    end process wr_reg;

    rd_reg: process(rd_en, rd_addr)
    begin
        
        if rd_en = '1' then
            
            case rd_addr is
            
                when STATUS_ADDR =>
    
                    rd_data <= status_reg;
    
                when CTRL_ADDR => 
    
                    rd_data <= ctrl_reg;
    
                when RX_ADDR =>
    
                    rd_data <= rx_reg;
    
                when others =>
    
                    rd_data <= (others => '0');
            
            end case;
            
        else 

            rd_data <= (others => '0');

        end if;

    end process rd_reg;

    ---------------------------- receiver --------------------------------

    receiver: uart_rx generic map (
        UART_BAUD => UART_BAUD
    ) port map (
        clk     => clk,
        reset   => reset,
        rx      => rx,
        rd_data => rx_rd_data,
        rd_en   => rx_rd_en
    );

    --------------------------- transmitter ------------------------------

    tx_wr_data <= tx_reg(7 downto 0);

    tx_wr <= wr_en when wr_addr = TX_ADDR else '0';

    transmitter: uart_tx generic map (
        UART_BAUD => UART_BAUD
    ) port map (
        clk     => clk,
        reset   => reset,
        wr      => tx_wr,
        wr_data => tx_wr_data,
        wr_en   => tx_wr_en,
        tx      => tx
    );
    
end architecture uar_arch;