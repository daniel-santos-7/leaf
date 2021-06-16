library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi is
    
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

end entity spi;

architecture spi_arch of spi is

    signal cpol: std_logic;
    signal cpha: std_logic;

    signal buffer_reg: std_logic_vector(31 downto 0);
    
    signal tx_reg:  std_logic_vector(31 downto 0);
    signal rx_reg:  std_logic_vector(31 downto 0);

    signal tx_count: std_logic_vector(31 downto 0);
    signal rx_count: std_logic_vector(31 downto 0);

    signal sclk_i: std_logic;
    signal cs_i:   std_logic;
    signal cyc:    std_logic;

begin

    communication: process(clk)

    begin
        
        if rising_edge(clk) then
            
            if reset = '1' then
                
                cpol       <= '0';
                cpha       <= '0';
                buffer_reg <= (others => '0');
                tx_reg     <= (others => '0');
                rx_reg     <= (others => '0');
                tx_count   <= (others => '0');
                rx_count   <= (others => '0');

                sclk_i  <= '0';
                cs_i    <= '1';
                cyc     <= '1';

            elsif wr_en = '1' then

                if wr_addr = b"00" then
                    
                    cpol <= wr_data(3);
                    cpha <= wr_data(7);

                elsif wr_addr = b"10" then

                    case wr_byte_en is
                            
                        when b"0001" =>
                            
                            buffer_reg <= wr_data(31 downto 24) & (23 downto 0 => '0');
                            tx_reg     <= wr_data(31 downto 24) & (23 downto 0 => '0');
                            rx_reg     <= (others => '0');
                            tx_count   <= (31 downto 24 => '0', others => '1');
                            rx_count   <= (31 downto 24 => '0', others => '1');
                    
                        when b"0011" =>

                            buffer_reg <= wr_data(31 downto 16) & (15 downto 0 => '0');
                            tx_reg     <= wr_data(31 downto 16) & (15 downto 0 => '0');
                            rx_reg     <= (others => '0');
                            tx_count   <= (31 downto 16 => '0', others => '1');
                            rx_count   <= (31 downto 16 => '0', others => '1');
    
                        when others =>

                            buffer_reg <= wr_data;
                            tx_reg     <= wr_data;
                            rx_reg     <= (others => '0');
                            tx_count   <= (others => '0');
                            rx_count   <= (others => '0');
                    
                    end case;

                    cs_i   <= '0';
                    sclk_i <= cpol;
                    cyc    <= not cpha;

                end if;

            elsif cs_i = '0' then

                if rx_count = x"FFFFFFFF" and tx_count = x"FFFFFFFF" then
                       
                    sclk_i <= cpol;

                    buffer_reg <= rx_reg;

                    cs_i <= '1';

                else

                    sclk_i <= not sclk_i;

                end if;

                cyc <= not cyc;

                if cyc = '0' and rx_count /= x"FFFFFFFF" then
                        
                    rx_reg <= rx_reg(30 downto 0) & sdi;

                    rx_count <= rx_count(30 downto 0) & '1';
                    
                end if;

                if cyc = '1' and tx_count /= x"FFFFFFFF" then
                    
                    sdo <= tx_reg(31);
                    
                    tx_reg <= tx_reg(30 downto 0) & '0';

                    tx_count <= tx_count(30 downto 0) & '1';

                end if;

            end if;

        end if;

    end process communication;

    rd_reg: process(rd_addr, cpha, cpol, tx_count, rx_count, buffer_reg)

    begin

        case rd_addr is
            
            when b"00" =>
                
                rd_data <= (7 => cpha, 3 => cpol, others => '0');

            when b"01" =>

                rd_data <= tx_count and rx_count;
        
            when b"10" =>

                rd_data <= buffer_reg;

            when others =>
                
                rd_data <= (others => '0');
            
        end case;

    end process rd_reg;

    sclk <= sclk_i;
    cs   <= cs_i;

end architecture spi_arch;