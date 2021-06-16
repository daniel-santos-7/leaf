library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_chip_pkg.all;

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
    
    signal busy: std_logic;
    signal done: std_logic;

    signal buffer_reg:   std_logic_vector(31 downto 0);
    signal buffer_count: std_logic_vector(3  downto 0);

    signal en:   std_logic;
    signal cpol: std_logic;
    signal cpha: std_logic;

    signal tx_data: std_logic_vector(7 downto 0);
    signal rx_data: std_logic_vector(7 downto 0);

begin
    
    master: spi_master port map (
        clk     => clk,
        reset   => reset,
        en      => en,
        tx_data => tx_data,
        rx_data => rx_data,
        busy    => busy,
        done    => done,
        cpol    => cpol,
        cpha    => cpha,
        sdo     => sdo,
        sdi     => sdi,
        sclk    => sclk,
        cs      => cs
    ); 

    rd_reg: process(rd_addr, cpha, cpol, en, buffer_count)

        variable ctrl_reg:   std_logic_vector(31 downto 0);
        variable status_reg: std_logic_vector(31 downto 0);

    begin

        case rd_addr is
            
            when b"00" =>
                
                rd_data <= (11 => cpha, 7 => cpol, 3 => en, others => '0');

            when b"01" =>

                rd_data <= (
                    31 downto 24 => buffer_count(3), 
                    23 downto 16 => buffer_count(2), 
                    15 downto 8  => buffer_count(1),
                    7 downto 0   => buffer_count(0) 
                );
        
            when b"10" =>

                rd_data <= buffer_reg;

            when others =>
                
                rd_data <= (others => '0');
            
        end case;

    end process rd_reg;

    wr_reg: process(clk)
    
    begin
    
        if rising_edge(clk) then
            
            if reset = '1' then
                
                en   <= '0';
                cpol <= '0';
                cpha <= '0';

                buffer_reg   <= (others => '0');
                buffer_count <= (others => '0');

            else

                if wr_en = '1' then
                    
                    if wr_addr = b"00" then
                        
                        en   <= wr_data(3);
                        cpol <= wr_data(7);
                        cpha <= wr_data(11);

                    elsif wr_addr = b"10" then
                        
                        en <= '0';

                        case wr_byte_en is
                            
                            when b"0001" =>
                                
                                buffer_reg   <= wr_data(31 downto 24) & (23 downto 0 => '0');
                                buffer_count <= b"0111";
                        
                            when b"0011" =>

                                buffer_reg   <= wr_data(31 downto 16) & (15 downto 0 => '0');
                                buffer_count <= b"0011";
        
                            when others =>

                                buffer_reg   <= wr_data;
                                buffer_count <= b"0000";
                        
                        end case;

                    end if;

                elsif en = '1' then 
                    
                    if buffer_count = b"1111" then
                        
                        en <= '0';

                    elsif busy = '0' and done = '1' then
                        
                        buffer_reg <= buffer_reg(23 downto 0) & rx_data;

                        buffer_count <= buffer_count(2 downto 0) & '1';

                    end if;

                end if;

            end if;

        end if;

    end process wr_reg;
    
    tx_data <= buffer_reg(31 downto 24);

end architecture spi_arch;