library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;

entity lsu is
    port (
        dmst_data:  in  std_logic_vector(31 downto 0);
        dmls_addr:  in  std_logic_vector(31 downto 0);
        dmls_dtype: in  std_logic_vector(2  downto 0);
        dmls_ctrl:  in  std_logic_vector(1  downto 0);
        dmrd_data:  in  std_logic_vector(31 downto 0);
        dmwr_data:  out std_logic_vector(31 downto 0);
        dmrw_addr:  out std_logic_vector(31 downto 0);
        dm_byte_en: out std_logic_vector(3  downto 0);
        dmrd_en:    out std_logic; 
        dmwr_en:    out std_logic;
        dmld_data:  out std_logic_vector(31 downto 0)       
    );
end entity lsu;

architecture lsu_arch of lsu is

    signal en:      std_logic;
    signal mode:    std_logic;

    signal dmem_rd: std_logic;
    signal dmem_wr: std_logic;

    signal data_in:  std_logic_vector(31 downto 0);
    signal data_out: std_logic_vector(31 downto 0);

    signal byte_en: std_logic_vector(3  downto 0);

begin

    en      <= dmls_ctrl(0);
    mode    <= dmls_ctrl(1);

    dmem_rd <= not mode and en;
    dmem_wr <= mode and en;

    data_in <= dmrd_data when dmem_rd = '1' else dmst_data when dmem_wr = '1' else (others => '0');

    convert: process(dmls_dtype, data_in)
    begin

        case dmls_dtype is
        
            when LSU_BYTE  => data_out <= std_logic_vector(resize(signed(data_in(7 downto 0)), 32));
            when LSU_BYTEU => data_out <= std_logic_vector(resize(unsigned(data_in(7 downto 0)), 32));
            when LSU_HALF  => data_out <= std_logic_vector(resize(signed(data_in(15 downto 0)), 32));
            when LSU_HALFU => data_out <= std_logic_vector(resize(unsigned(data_in(15 downto 0)), 32));
            when others    => data_out <= data_in;

        end case;

    end process convert;

    byte_en_gen: process(dmls_dtype)
    begin
            
        case dmls_dtype is
            when LSU_BYTE | LSU_BYTEU => byte_en <= b"0001";
            when LSU_HALF | LSU_HALFU => byte_en <= b"0011";
            when others               => byte_en <= b"1111";
        end case;

    end process byte_en_gen;

    dmwr_data <= data_out and (31 downto 0 => dmem_wr);
    dmld_data <= data_out and (31 downto 0 => dmem_rd);

    dmrw_addr  <= dmls_addr when en = '1' else (others => '0');
    dm_byte_en <= byte_en when dmem_wr = '1' else (others => '0');

    dmrd_en <= dmem_rd;
    dmwr_en <= dmem_wr;

end architecture lsu_arch;