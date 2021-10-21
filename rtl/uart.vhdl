library IEEE;
use IEEE.std_logic_1164.all;
use work.uart_pkg.all;

entity uart is
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
end entity uart;

architecture uar_arch of uart is

    constant STAT_ADDR: std_logic_vector(1 downto 0) := b"00";
    constant CTRL_ADDR: std_logic_vector(1 downto 0) := b"01";
    constant BRDV_ADDR: std_logic_vector(1 downto 0) := b"10";
    constant TXRX_ADDR: std_logic_vector(1 downto 0) := b"11";

    signal status: std_logic_vector(5 downto 0);

    signal baud_div: std_logic_vector(15 downto 0);

    signal rx_fifo_wr:      std_logic;
    signal rx_fifo_wr_en:   std_logic;
    signal rx_fifo_rd:      std_logic;
    signal rx_fifo_rd_en:   std_logic;
    signal rx_fifo_wr_data: std_logic_vector(7 downto 0);
    signal rx_fifo_rd_data: std_logic_vector(7 downto 0);

    signal rx_wr:      std_logic;
    signal rx_wr_en:   std_logic;
    signal rx_busy:    std_logic;
    signal rx_wr_data: std_logic_vector(7 downto 0);

    signal tx_fifo_wr:      std_logic;
    signal tx_fifo_wr_en:   std_logic;
    signal tx_fifo_rd:      std_logic;
    signal tx_fifo_rd_en:   std_logic;
    signal tx_fifo_wr_data: std_logic_vector(7 downto 0);
    signal tx_fifo_rd_data: std_logic_vector(7 downto 0);

    signal tx_rd:      std_logic;
    signal tx_rd_en:   std_logic;
    signal tx_busy:    std_logic;
    signal tx_rd_data: std_logic_vector(7 downto 0);
    
begin

    ------------------ baud rate divider register ------------------------

    baud_div_reg: process(reset, clk)
    begin
        
        if reset = '1' then

            baud_div <= (others => '1');

        elsif rising_edge(clk) then
            
            if wr = '1' and wr_addr = BRDV_ADDR then
               
                baud_div <= wr_data;

            end if;

        end if;

    end process baud_div_reg;

    -------------------------- receiver buffer ----------------------------

    rx_fifo_rd <= '1' when rd = '1' and rd_addr = TXRX_ADDR else '0';

    rx_fifo: fifo generic map (
        SIZE => 8,
        BITS => 8 
    ) port map (
        clk     => clk,
        reset   => reset,
        wr      => rx_fifo_wr,
        wr_en   => rx_fifo_wr_en,
        wr_data => rx_fifo_wr_data,
        rd      => rx_fifo_rd,
        rd_en   => rx_fifo_rd_en,
        rd_data => rx_fifo_rd_data
    );

    ---------------------------- receiver --------------------------------

    rx_fifo_wr      <= rx_wr;
    rx_wr_en        <= rx_fifo_wr_en;
    rx_fifo_wr_data <= rx_wr_data;

    receiver: uart_rx port map (
        clk      => clk,
        reset    => reset,
        baud_div => baud_div,
        wr       => rx_wr,
        wr_en    => rx_wr_en,
        wr_data  => rx_wr_data,
        busy     => rx_busy,
        rx       => rx
    );

    ----------------------- transmitter buffer --------------------------

    tx_fifo_wr      <= '1' when wr = '1' and wr_addr = TXRX_ADDR else '0';
    tx_fifo_wr_data <= wr_data(7 downto 0);

    tx_fifo: fifo generic map (
        SIZE => 8,
        BITS => 8 
    ) port map (
        clk     => clk,
        reset   => reset,
        wr      => tx_fifo_wr,
        wr_en   => tx_fifo_wr_en,
        wr_data => tx_fifo_wr_data,
        rd      => tx_fifo_rd,
        rd_en   => tx_fifo_rd_en,
        rd_data => tx_fifo_rd_data
    );

    --------------------------- transmitter ------------------------------

    tx_fifo_rd <= tx_rd;
    tx_rd_en   <= tx_fifo_rd_en;
    tx_rd_data <= tx_fifo_rd_data;

    transmitter: uart_tx port map (
        clk       => clk,
        reset     => reset,
        baud_div  => baud_div,
        rd        => tx_rd,
        rd_en     => tx_rd_en,
        rd_data   => tx_rd_data,
        busy      => tx_busy,
        tx        => tx
    );

    -------------------------- module status -----------------------------

    status(5 downto 4) <= tx_fifo_wr_en & rx_fifo_wr_en;
    status(3 downto 2) <= tx_fifo_rd_en & rx_fifo_rd_en;
    status(1 downto 0) <= tx_busy & rx_busy;

    -------------------------- read registers ----------------------------

    rd_reg: process(rd, rd_addr, status, baud_div, rx_fifo_rd_data)
    begin
        
        if rd = '1' then
            
            case rd_addr is
                
                when STAT_ADDR => 
                
                    rd_data(5  downto 0) <= status;
                    rd_data(15 downto 6) <= (others => '0');
                
                when CTRL_ADDR => 
                    
                    rd_data <= (1 downto 0 => '1', others => '0');
                
                when BRDV_ADDR => 
                    
                    rd_data <= baud_div;
                
                when TXRX_ADDR => 
                    
                    rd_data(7  downto 0) <= rx_fifo_rd_data;
                    rd_data(15 downto 8) <= (others => '0');
                
                when others => 
                
                    rd_data <= (others => '0');
                
            end case;
            
        else 

            rd_data <= (others => '0');

        end if;

    end process rd_reg;

end architecture uar_arch;