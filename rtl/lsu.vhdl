library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity lsu is
    
    port (
        rd_mem_data: in std_logic_vector(31 downto 0);
        wr_data: in std_logic_vector(31 downto 0);
        data_type: in std_logic_vector(2 downto 0);
        mode, en: in std_logic;
        rd_mem_en, wr_mem_en: out std_logic;
        wr_mem_data: out std_logic_vector(31 downto 0);
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
        
        std_logic_vector(resize(signed(conv_in_data(7 downto 0)), 32))      when data_type = b"000" else
        
        std_logic_vector(resize(unsigned(conv_in_data(7 downto 0)), 32))    when data_type = b"100" else
        
        std_logic_vector(resize(signed(conv_in_data(15 downto 0)), 32))     when data_type = b"001" else
        
        std_logic_vector(resize(unsigned(conv_in_data(15 downto 0)), 32))   when data_type = b"101" else
        
        conv_in_data;

    wr_mem_data <= conv_out_data when (mode = '1' and en = '1') else x"0000_0000";

    rd_data <= conv_out_data when (mode = '0' and en = '1') else x"0000_0000";

end architecture lsu_arch;