----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- 2022
----------------------------------------------------------------------

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
        dmls_ctrl:  in  dmls_ctrl_type;
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

    signal byte_en: std_logic_vector(3  downto 0);

begin

    en      <= dmls_ctrl.en;
    mode    <= dmls_ctrl.mode;

    dmem_rd <= not mode and en;
    dmem_wr <= mode and en;

    -- read_dmem: process(dmem_rd, dmls_dtype, dmrd_data)
    -- begin
    --     if dmem_rd = '1' then
    --         case dmls_dtype is
    --             when LSU_BYTE  => dmld_data <= std_logic_vector(resize(signed(dmrd_data(7 downto 0)), 32));
    --             when LSU_BYTEU => dmld_data <= std_logic_vector(resize(unsigned(dmrd_data(7 downto 0)), 32));
    --             when LSU_HALF  => dmld_data <= std_logic_vector(resize(signed(dmrd_data(15 downto 0)), 32));
    --             when LSU_HALFU => dmld_data <= std_logic_vector(resize(unsigned(dmrd_data(15 downto 0)), 32));
    --             when others    => dmld_data <= dmrd_data;
    --         end case;
    --     else
    --         dmld_data <= (others => '0');
    --     end if;
    -- end process read_dmem;

    read_dmem: process(dmem_rd, dmls_dtype, dmrd_data)
        variable addr_align : std_logic_vector(1 downto 0);
    begin
        if dmem_rd = '1' then
            addr_align := dmls_addr(1 downto 0);
            case dmls_dtype is
                when LSU_BYTE  => 
                    case addr_align is
                        when b"00" => dmld_data <= std_logic_vector(resize(signed(dmrd_data(7  downto 0)), 32));
                        when b"01" => dmld_data <= std_logic_vector(resize(signed(dmrd_data(15 downto 8)), 32));
                        when b"10" => dmld_data <= std_logic_vector(resize(signed(dmrd_data(23 downto 16)), 32));
                        when b"11" => dmld_data <= std_logic_vector(resize(signed(dmrd_data(31 downto 24)), 32));
                        when others => null;
                    end case;
                when LSU_BYTEU => 
                    case addr_align is
                        when b"00" => dmld_data <= std_logic_vector(resize(unsigned(dmrd_data(7  downto 0)), 32));
                        when b"01" => dmld_data <= std_logic_vector(resize(unsigned(dmrd_data(15 downto 8)), 32));
                        when b"10" => dmld_data <= std_logic_vector(resize(unsigned(dmrd_data(23 downto 16)), 32));
                        when b"11" => dmld_data <= std_logic_vector(resize(unsigned(dmrd_data(31 downto 24)), 32));
                        when others => null;
                    end case;
                when LSU_HALF  => 
                    case addr_align is
                        when b"00" => dmld_data <= std_logic_vector(resize(signed(dmrd_data(15 downto 0)), 32));
                        when b"01" => dmld_data <= std_logic_vector(resize(signed(dmrd_data(23 downto 8)), 32));
                        when b"10" => dmld_data <= std_logic_vector(resize(signed(dmrd_data(31 downto 16)), 32));
                        when b"11" => dmld_data <= std_logic_vector(resize(signed(dmrd_data(31 downto 24)), 32));
                        when others => null;
                    end case;
                when LSU_HALFU => 
                    case addr_align is
                        when b"00" => dmld_data <= std_logic_vector(resize(unsigned(dmrd_data(15 downto 0)), 32));
                        when b"01" => dmld_data <= std_logic_vector(resize(unsigned(dmrd_data(23 downto 8)), 32));
                        when b"10" => dmld_data <= std_logic_vector(resize(unsigned(dmrd_data(31 downto 16)), 32));
                        when b"11" => dmld_data <= std_logic_vector(resize(unsigned(dmrd_data(31 downto 24)), 32));
                        when others => null;
                    end case;
                when others => dmld_data <= dmrd_data;
            end case;
        else
            dmld_data <= (others => '0');
        end if;
    end process read_dmem;

    write_dmem: process(dmem_wr, dmls_addr, dmst_data)
        variable addr_align : std_logic_vector(1 downto 0);
    begin
        if dmem_wr = '1' then
            addr_align := dmls_addr(1 downto 0);
            case addr_align is
                when b"01"  => dmwr_data <= dmst_data(23 downto 0) & dmst_data(31 downto 24);
                when b"10"  => dmwr_data <= dmst_data(15 downto 0) & dmst_data(31 downto 16);
                when b"11"  => dmwr_data <= dmst_data(7  downto 0) & dmst_data(31 downto  8);
                when others => dmwr_data <= dmst_data;
            end case;
        else
            dmwr_data <= (others => '0');
        end if;
    end process write_dmem;

    byte_en_gen: process(dmls_dtype, dmls_addr)
        variable addr_align : std_logic_vector(1 downto 0);
    begin
        addr_align := dmls_addr(1 downto 0);
        case dmls_dtype is
            when LSU_BYTE | LSU_BYTEU => 
                case addr_align is
                    when b"00"  => byte_en <= b"0001";
                    when b"01"  => byte_en <= b"0010";
                    when b"10"  => byte_en <= b"0100";
                    when b"11"  => byte_en <= b"1000";
                    when others => null;
                end case;
            when LSU_HALF | LSU_HALFU => 
                case addr_align is
                    when b"00"  => byte_en <= b"0011";
                    when b"01"  => byte_en <= b"0110";
                    when b"10"  => byte_en <= b"1100";
                    when b"11"  => byte_en <= b"1000";
                    when others => null;
                end case;
            when others => byte_en <= b"1111";
        end case;
    end process byte_en_gen;

    dmrw_addr  <= dmls_addr when en = '1' else (others => '0');
    dm_byte_en <= byte_en when dmem_wr = '1' else (others => '0');

    dmrd_en <= dmem_rd;
    dmwr_en <= dmem_wr;

end architecture lsu_arch;