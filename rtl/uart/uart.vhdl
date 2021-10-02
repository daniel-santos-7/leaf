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
    
    signal rx_pointer: std_logic_vector(3 downto 0);
    signal tx_pointer: std_logic_vector(3 downto 0);

    signal tx_wr:      std_logic;
    signal rx_rd_en:   std_logic;
    signal tx_wr_en:   std_logic;
    signal rx_rd_data: std_logic_vector(7 downto 0);
    signal tx_wr_data: std_logic_vector(7 downto 0);
    
begin

    ----------------------------------------------------------------------
    -- read module registers
    ----------------------------------------------------------------------

    status_reg <= x"000000" & tx_pointer & rx_pointer;

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

    ----------------------------------------------------------------------
    -- receive data
    ----------------------------------------------------------------------

    receive: process(clk)
    begin
        
        if rising_edge(clk) then

            if rd_en = '1' and rd_addr = RX_ADDR then
                
                rx_pointer <= (others => '0');

                rx_reg <= (others => '1');

            elsif rx_rd_en = '1' and rx_pointer /= x"FF" then 

                rx_pointer <= '1' & rx_pointer(3 downto 1);

                rx_reg <= rx_rd_data & rx_reg(31 downto 8);

            end if;
           
        end if;

    end process receive;

    ----------------------------------------------------------------------
    -- transmit data
    ----------------------------------------------------------------------

    transmit: process(clk)
    begin
        
        if rising_edge(clk) then
            
            if wr_en = '1' then
                
                tx_pointer <= not wr_byte_en;

                tx_reg <= wr_data;

            elsif tx_wr_en = '1' and tx_pointer /= x"FF" then
                
                tx_pointer <= '1' & tx_pointer(3 downto 1);
                    
                tx_reg <= x"FF" & tx_reg(31 downto 8);

            end if;

        end if;

    end process transmit;

    ----------------------------------------------------------------------
    -- receiver
    ----------------------------------------------------------------------

    receiver: uart_rx generic map (
        UART_BAUD => UART_BAUD
    ) port map (
        clk     => clk,
        reset   => reset,
        rx      => rx,
        rd_data => rx_rd_data,
        rd_en   => rx_rd_en
    );

    ----------------------------------------------------------------------
    -- transmitter
    ----------------------------------------------------------------------

    tx_wr <= '0' when tx_pointer = x"FF" else '0';

    tx_wr_data <= tx_reg(7 downto 0);

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