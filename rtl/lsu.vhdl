library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;

entity lsu is
    
    port (
        
        mode, en:   in std_logic;
        data_type:  in std_logic_vector(2 downto 0);

        rd_wr_addr: in  std_logic_vector(31 downto 0);
        wr_data:    in  std_logic_vector(31 downto 0);
        rd_data:    out std_logic_vector(31 downto 0);        

        rd_mem_en:      out std_logic; 
        wr_mem_en:      out std_logic;

        rd_wr_mem_addr: out std_logic_vector(31 downto 0);
        rd_mem_data:    in  std_logic_vector(31 downto 0);
        wr_mem_data:    out std_logic_vector(31 downto 0);
        wr_mem_byte_en: out std_logic_vector(3  downto 0)

    );

end entity lsu;

architecture lsu_arch of lsu is

    signal data_in, data_out: std_logic_vector(31 downto 0);

begin

    convert: process(data_type, data_in)

    begin

        case data_type is
            
            when LSU_BYTE =>    data_out <= std_logic_vector(resize(signed(data_in(7 downto 0)), 32));
            
            when LSU_BYTEU =>   data_out <= std_logic_vector(resize(unsigned(data_in(7 downto 0)), 32));
            
            when LSU_HALF =>    data_out <= std_logic_vector(resize(signed(data_in(15 downto 0)), 32));
            
            when LSU_HALFU =>   data_out <= std_logic_vector(resize(unsigned(data_in(15 downto 0)), 32));
            
            when others =>      data_out <= data_in;
        
        end case;

    end process convert;

    wr_mem: process(mode, en, data_out, data_type)
    
    begin
        
        if mode = '1' and en = '1' then
    
            wr_mem_en   <= '1';
            wr_mem_data <= data_out;

            case data_type is
                
                when LSU_BYTE =>    wr_mem_byte_en <= b"0001";

                when LSU_BYTEU =>   wr_mem_byte_en <= b"0001";

                when LSU_HALF =>    wr_mem_byte_en <= b"0011";

                when LSU_HALFU =>   wr_mem_byte_en <= b"0011";
            
                when others =>      wr_mem_byte_en <= b"1111";
            
            end case;

        else

            wr_mem_en       <= '0';
            wr_mem_data     <= (others => '0');
            wr_mem_byte_en  <= (others => '0');

        end if;

    end process wr_mem;

    rd_mem: process(mode, en, data_out)
    
    begin
    
        if mode = '0' and en = '1' then
            
            rd_mem_en   <= '1';
            rd_data     <= data_out;

        else

            rd_mem_en   <= '0';
            rd_data     <= (others => '0');

        end if;

    end process rd_mem;

    data_in <= rd_mem_data when mode = '0' and en = '1' else wr_data when mode = '1' and en = '1' else (others => '0');
    
    rd_wr_mem_addr <= rd_wr_addr when en = '1' else (others => '0');

end architecture lsu_arch;