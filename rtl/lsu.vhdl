library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;

entity lsu is
    
    port (
        rd_data:    out std_logic_vector(31 downto 0);        
        wr_data:    in  std_logic_vector(31 downto 0);
        rd_wr_addr: in  std_logic_vector(31 downto 0);
        
        data_type: in std_logic_vector(2 downto 0);
        mode:      in std_logic;
        en:        in std_logic;

        rd_mem_en: out std_logic; 
        wr_mem_en: out std_logic;

        rd_mem_data:    in  std_logic_vector(31 downto 0);
        wr_mem_data:    out std_logic_vector(31 downto 0);
        rd_wr_mem_addr: out std_logic_vector(31 downto 0);
        wr_mem_byte_en: out std_logic_vector(3  downto 0)
    );

end entity lsu;

architecture lsu_arch of lsu is

    signal rd_mem_en_i: std_logic;
    signal wr_mem_en_i: std_logic;

    signal data_in:  std_logic_vector(31 downto 0);
    signal data_out: std_logic_vector(31 downto 0);

    signal wr_mem_byte_en_i: std_logic_vector(3  downto 0);

begin

    rd_mem_en_i <= not mode and en;
    wr_mem_en_i <= mode and en;

    data_in <= rd_mem_data when rd_mem_en_i = '1' else wr_data when wr_mem_en_i = '1' else (others => '0');

    convert: process(data_type, data_in)

    begin

        case data_type is
        
            when LSU_BYTE =>    
                
                data_out <= std_logic_vector(resize(signed(data_in(7 downto 0)), 32));
            
            when LSU_BYTEU =>   
                
                data_out <= std_logic_vector(resize(unsigned(data_in(7 downto 0)), 32));
            
            when LSU_HALF =>    
            
                data_out <= std_logic_vector(resize(signed(data_in(15 downto 0)), 32));
            
            when LSU_HALFU =>   
            
                data_out <= std_logic_vector(resize(unsigned(data_in(15 downto 0)), 32));
            
            when others =>      
            
                data_out <= data_in;
        
        end case;

    end process convert;

    byte_en: process(data_type)
    
    begin
            
        case data_type is
            
            when LSU_BYTE | LSU_BYTEU =>    
            
                wr_mem_byte_en_i <= b"0001";

            when LSU_HALF | LSU_HALFU =>    
            
                wr_mem_byte_en_i <= b"0011";
        
            when others =>      
            
                wr_mem_byte_en_i <= b"1111";
        
        end case;

    end process byte_en;

    rd_mem_en <= rd_mem_en_i;
    wr_mem_en <= wr_mem_en_i;

    rd_data     <= data_out when rd_mem_en_i = '1' else (others => '0');
    wr_mem_data <= data_out when wr_mem_en_i = '1' else (others => '0');

    rd_wr_mem_addr <= rd_wr_addr when en = '1' else (others => '0');
    
    wr_mem_byte_en <= wr_mem_byte_en_i when wr_mem_en_i = '1' else (others => '0');

end architecture lsu_arch;