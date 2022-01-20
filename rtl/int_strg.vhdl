library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity int_strg is
    port (
        clk:        in  std_logic;
        wr_en:      in  std_logic;
        wr_addr:    in  std_logic_vector(4  downto 0);
        wr_src0:    in  std_logic_vector(31 downto 0);
        wr_src1:    in  std_logic_vector(31 downto 0);
        wr_src2:    in  std_logic_vector(31 downto 0);
        wr_src3:    in  std_logic_vector(31 downto 0);
        wr_src_sel: in  std_logic_vector(1  downto 0);
        rd_addr0:   in  std_logic_vector(4  downto 0);
        rd_addr1:   in  std_logic_vector(4  downto 0);
        rd_data0:   out std_logic_vector(31 downto 0);
        rd_data1:   out std_logic_vector(31 downto 0)
    );
end entity int_strg;

architecture int_strg_arch of int_strg is
    
    signal wr_data: std_logic_vector(31 downto 0);

begin
    
    wr_data_mux: process(wr_src_sel, wr_src0, wr_src1, wr_src2, wr_src3)
    begin
        
        case wr_src_sel is
            when b"00"  => wr_data <= wr_src0;
            when b"01"  => wr_data <= wr_src1;
            when b"10"  => wr_data <= wr_src2;
            when b"11"  => wr_data <= wr_src3;
            when others => null;
        end case;

    end process wr_data_mux;
    
    int_strg_rf: reg_file port map (
        clk          => clk,
        rd_reg_addr0 => rd_addr0,
        rd_reg_addr1 => rd_addr1,
        wr_reg_addr  => wr_addr,
        wr_reg_data  => wr_data,
        wr_reg_en    => wr_en,
        rd_reg_data0 => rd_data0, 
        rd_reg_data1 => rd_data1
    );

end architecture int_strg_arch;