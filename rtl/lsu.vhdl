library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.core_pkg.all;

entity lsu is
    
    port (
        rd_mem_data: in std_logic_vector(31 downto 0);
        rd_wr_addr: in std_logic_vector(31 downto 0);
        wr_data: in std_logic_vector(31 downto 0);
        data_type: in std_logic_vector(2 downto 0);
        mode, en: in std_logic;
        rd_mem_en, wr_mem_en: out std_logic;
        rd_wr_mem_addr, wr_mem_data: out std_logic_vector(31 downto 0);
        rd_data: out std_logic_vector(31 downto 0)
    );

end entity lsu;

architecture lsu_arch of lsu is
    
    signal conv_in_data: std_logic_vector(31 downto 0);
    signal conv_out_data: std_logic_vector(31 downto 0);

begin
    
    rd_mem_en <= not (mode) and en;
    
    wr_mem_en <= mode and en;
    
    conv_in_data <= wr_data when mode = '1' else rd_mem_data;
    
    conv_out_data <= 
        
        std_logic_vector(resize(signed(conv_in_data(7 downto 0)), 32))      when data_type = LSU_BYTE  else
        
        std_logic_vector(resize(unsigned(conv_in_data(7 downto 0)), 32))    when data_type = LSU_BYTEU else
        
        std_logic_vector(resize(signed(conv_in_data(15 downto 0)), 32))     when data_type = LSU_HALF  else
        
        std_logic_vector(resize(unsigned(conv_in_data(15 downto 0)), 32))   when data_type = LSU_HALFU else
        
        conv_in_data;

    rd_wr_mem_addr <= rd_wr_addr when en = '1' else x"00000000";

    wr_mem_data <= conv_out_data when (mode = '1' and en = '1') else x"00000000";

    rd_data <= conv_out_data when (mode = '0' and en = '1') else x"00000000";

end architecture lsu_arch;