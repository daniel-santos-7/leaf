----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: data memory load/store block
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;

entity dmls_block is
    port (
        dmrd_err   : in  std_logic;
        dmwr_err   : in  std_logic;
        dmls_ctrl  : in  std_logic_vector(1  downto 0);
        dmls_dtype : in  std_logic_vector(2  downto 0);
        dmst_data  : in  std_logic_vector(31 downto 0);
        dmls_addr  : in  std_logic_vector(31 downto 0);
        dmrd_data  : in  std_logic_vector(31 downto 0);
        dmld_malgn : out std_logic;
        dmld_fault : out std_logic;
        dmst_malgn : out std_logic;
        dmst_fault : out std_logic;
        dmrd_en    : out std_logic; 
        dmwr_en    : out std_logic;
        dmwr_data  : out std_logic_vector(31 downto 0);
        dmrw_addr  : out std_logic_vector(31 downto 0);
        dm_byte_en : out std_logic_vector(3  downto 0);
        dmld_data  : out std_logic_vector(31 downto 0)       
    );
end entity dmls_block;

architecture dmls_block_arch of dmls_block is

    signal mode    : std_logic;
    signal en      : std_logic;
    signal dmem_rd : std_logic;
    signal dmem_wr : std_logic;

    signal addr_base : std_logic_vector(1 downto 0);

begin

    mode    <= dmls_ctrl(1);
    en      <= dmls_ctrl(0);
    dmem_rd <= not mode and en;
    dmem_wr <= mode and en;

    addr_base <= dmls_addr(1 downto 0);

    read_dmem: process(dmem_rd, dmls_dtype, dmrd_data, addr_base)
    begin
        if dmem_rd = '1' then
            case dmls_dtype is
                when LSU_BYTE  => 
                    case addr_base is
                        when b"00" => dmld_data <= std_logic_vector(resize(signed(dmrd_data(7  downto 0)), 32));
                        when b"01" => dmld_data <= std_logic_vector(resize(signed(dmrd_data(15 downto 8)), 32));
                        when b"10" => dmld_data <= std_logic_vector(resize(signed(dmrd_data(23 downto 16)), 32));
                        when b"11" => dmld_data <= std_logic_vector(resize(signed(dmrd_data(31 downto 24)), 32));
                        when others => null;
                    end case;
                    dmld_malgn <= '0';
                    dmrd_en    <= '1';
                when LSU_BYTEU => 
                    case addr_base is
                        when b"00" => dmld_data <= std_logic_vector(resize(unsigned(dmrd_data(7  downto 0)), 32));
                        when b"01" => dmld_data <= std_logic_vector(resize(unsigned(dmrd_data(15 downto 8)), 32));
                        when b"10" => dmld_data <= std_logic_vector(resize(unsigned(dmrd_data(23 downto 16)), 32));
                        when b"11" => dmld_data <= std_logic_vector(resize(unsigned(dmrd_data(31 downto 24)), 32));
                        when others => null;
                    end case;
                    dmld_malgn <= '0';
                    dmrd_en    <= '1';
                when LSU_HALF  => 
                    case addr_base is
                        when b"00" => 
                            dmld_data  <= std_logic_vector(resize(signed(dmrd_data(15 downto 0)), 32));
                            dmld_malgn <= '0';
                            dmrd_en    <= '1';
                        when b"01" =>
                            dmld_data  <= std_logic_vector(resize(signed(dmrd_data(15 downto 0)), 32));
                            dmld_malgn <= '1';
                            dmrd_en    <= '0';
                        when b"10" => 
                            dmld_data  <= std_logic_vector(resize(signed(dmrd_data(31 downto 16)), 32));
                            dmld_malgn <= '0';
                            dmrd_en    <= '1';
                        when b"11" => 
                            dmld_data  <= std_logic_vector(resize(signed(dmrd_data(31 downto 16)), 32));
                            dmld_malgn <= '1';
                            dmrd_en    <= '0';
                        when others => null;
                    end case;
                when LSU_HALFU => 
                    case addr_base is
                        when b"00" => 
                            dmld_data  <= std_logic_vector(resize(unsigned(dmrd_data(15 downto 0)), 32));
                            dmld_malgn <= '0';
                            dmrd_en    <= '1';
                        when b"01" => 
                            dmld_data  <= std_logic_vector(resize(unsigned(dmrd_data(15 downto 0)), 32));
                            dmld_malgn <= '1';
                            dmrd_en    <= '0';
                        when b"10" => 
                            dmld_data  <= std_logic_vector(resize(unsigned(dmrd_data(31 downto 16)), 32));
                            dmld_malgn <= '0';
                            dmrd_en    <= '1';
                        when b"11" => 
                            dmld_data  <= std_logic_vector(resize(unsigned(dmrd_data(31 downto 16)), 32));
                            dmld_malgn <= '1';
                            dmrd_en    <= '0';
                        when others => null;
                    end case;
                when LSU_WORD => 
                    dmld_data <= dmrd_data;
                    if addr_base = b"00" then
                        dmld_malgn <= '0';
                        dmrd_en    <= '1';
                    else
                        dmld_malgn <= '1';
                        dmrd_en    <= '0';
                    end if;
                when others =>
                    dmld_data  <= (others => '0');
                    dmld_malgn <= '0';
                    dmrd_en    <= '0';
            end case;
        else
            dmld_data  <= (others => '0');
            dmld_malgn <= '0';
            dmrd_en    <= '0';
        end if;
    end process read_dmem;

    write_dmem: process(dmem_wr, dmls_dtype, dmst_data, addr_base)
    begin
        if dmem_wr = '1' then
            case dmls_dtype is
                when LSU_BYTE  =>
                    case addr_base is
                        when b"00" =>
                            dmwr_data  <= dmst_data;
                            dm_byte_en <= b"0001";
                        when b"01" =>
                            dmwr_data  <= dmst_data(23 downto 0) & dmst_data(31 downto 24);
                            dm_byte_en <= b"0010";
                        when b"10" =>
                            dmwr_data  <= dmst_data(15 downto 0) & dmst_data(31 downto 16);
                            dm_byte_en <= b"0100";
                        when b"11" =>
                            dmwr_data  <= dmst_data(7  downto 0) & dmst_data(31 downto  8);
                            dm_byte_en <= b"1000";
                        when others => null;
                    end case;
                    dmst_malgn <= '0';
                    dmwr_en    <= '1';
                when LSU_HALF  =>
                    case addr_base is
                        when b"00" =>
                            dmwr_data  <= dmst_data;
                            dm_byte_en <= b"0011";
                            dmst_malgn <= '0';
                            dmwr_en    <= '1';
                        when b"01" =>
                            dmwr_data  <= dmst_data;
                            dm_byte_en <= b"0011";
                            dmst_malgn <= '1';
                            dmwr_en    <= '0';
                        when b"10" =>
                            dmwr_data  <= dmst_data(15 downto 0) & dmst_data(31 downto 16);
                            dm_byte_en <= b"1100";
                            dmst_malgn <= '0';
                            dmwr_en    <= '1';
                        when b"11" =>
                            dmwr_data  <= dmst_data(15 downto 0) & dmst_data(31 downto 16);
                            dm_byte_en <= b"1100";
                            dmst_malgn <= '1';
                            dmwr_en    <= '0';
                        when others => null;
                    end case;
                when LSU_WORD  =>
                    dmwr_data  <= dmst_data;
                    dm_byte_en <= b"1111";
                    if addr_base = b"00" then
                        dmst_malgn <= '0';
                        dmwr_en    <= '1';
                    else
                        dmst_malgn <= '1';
                        dmwr_en    <= '0';
                    end if;
                when others => 
                    dmwr_data  <= (others => '0');
                    dm_byte_en <= b"0000";
                    dmst_malgn <= '0';
                    dmwr_en    <= '0';
            end case;
        else
            dmwr_data  <= (others => '0');
            dm_byte_en <= b"0000";
            dmst_malgn <= '0';
            dmwr_en    <= '0';
        end if;
    end process write_dmem;

    dmrw_addr <= dmls_addr(31 downto 2) & b"00" when en = '1' else (others => '0');

    dmld_fault <= dmrd_err and dmem_rd;
    dmst_fault <= dmwr_err and dmem_wr;

end architecture dmls_block_arch;