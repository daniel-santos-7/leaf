----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: data memory load/store block
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_pkg.all;

entity dmls_block is
    port (
        dmrd_err_i   : in  std_logic;
        dmwr_err_i   : in  std_logic;
        dmls_mode_i  : in  std_logic;
        dmls_en_i    : in  std_logic;
        dmls_dtype_i : in  std_logic_vector(2           downto 0);
        dmst_data_i  : in  std_logic_vector(XLEN-1      downto 0);
        dmls_addr_i  : in  std_logic_vector(XLEN-1      downto 0);
        dmrd_data_i  : in  std_logic_vector(XLEN-1      downto 0);
        dmld_malgn_o : out std_logic;
        dmld_fault_o : out std_logic;
        dmst_malgn_o : out std_logic;
        dmst_fault_o : out std_logic;
        dmrd_en_o    : out std_logic;
        dmwr_en_o    : out std_logic;
        dmwr_data_o  : out std_logic_vector(XLEN-1      downto 0);
        dmrw_addr_o  : out std_logic_vector(XLEN-1      downto 0);
        dm_byte_en_o : out std_logic_vector(3           downto 0);
        dmld_data_o  : out std_logic_vector(XLEN-1      downto 0)
    );
end entity dmls_block;

architecture dmls_block_arch of dmls_block is

    signal dmem_rd : std_logic;
    signal dmem_wr : std_logic;

    signal addr_base : std_logic_vector(1 downto 0);

begin

    dmem_rd <= not dmls_mode_i and dmls_en_i;
    dmem_wr <= dmls_mode_i and dmls_en_i;

    addr_base <= dmls_addr_i(1 downto 0);

    read_dmem: process(dmem_rd, dmls_dtype_i, dmrd_data_i, addr_base)
    begin
        if dmem_rd = '1' then
            case dmls_dtype_i is
                when LSU_BYTE  =>
                    case addr_base is
                        when b"00" => dmld_data_o <= std_logic_vector(resize(signed(dmrd_data_i(7  downto 0)), XLEN));
                        when b"01" => dmld_data_o <= std_logic_vector(resize(signed(dmrd_data_i(15 downto 8)), XLEN));
                        when b"10" => dmld_data_o <= std_logic_vector(resize(signed(dmrd_data_i(23 downto 16)), XLEN));
                        when b"11" => dmld_data_o <= std_logic_vector(resize(signed(dmrd_data_i(31 downto 24)), XLEN));
                        when others => dmld_data_o <= (others => '-');
                    end case;
                    dmld_malgn_o <= '0';
                    dmrd_en_o    <= '1';
                when LSU_BYTEU =>
                    case addr_base is
                        when b"00" => dmld_data_o <= std_logic_vector(resize(unsigned(dmrd_data_i(7  downto 0)), XLEN));
                        when b"01" => dmld_data_o <= std_logic_vector(resize(unsigned(dmrd_data_i(15 downto 8)), XLEN));
                        when b"10" => dmld_data_o <= std_logic_vector(resize(unsigned(dmrd_data_i(23 downto 16)), XLEN));
                        when b"11" => dmld_data_o <= std_logic_vector(resize(unsigned(dmrd_data_i(31 downto 24)), XLEN));
                        when others => dmld_data_o <= (others => '-');
                    end case;
                    dmld_malgn_o <= '0';
                    dmrd_en_o    <= '1';
                when LSU_HALF  =>
                    case addr_base is
                        when b"00" =>
                            dmld_data_o  <= std_logic_vector(resize(signed(dmrd_data_i(15 downto 0)), XLEN));
                            dmld_malgn_o <= '0';
                            dmrd_en_o    <= '1';
                        when b"01" =>
                            dmld_data_o  <= std_logic_vector(resize(signed(dmrd_data_i(15 downto 0)), XLEN));
                            dmld_malgn_o <= '1';
                            dmrd_en_o    <= '0';
                        when b"10" =>
                            dmld_data_o  <= std_logic_vector(resize(signed(dmrd_data_i(31 downto 16)), XLEN));
                            dmld_malgn_o <= '0';
                            dmrd_en_o    <= '1';
                        when b"11" =>
                            dmld_data_o  <= std_logic_vector(resize(signed(dmrd_data_i(31 downto 16)), XLEN));
                            dmld_malgn_o <= '1';
                            dmrd_en_o    <= '0';
                        when others =>
                            dmld_data_o  <= (others => '-');
                            dmld_malgn_o <= '-';
                            dmrd_en_o    <= '-';
                    end case;
                when LSU_HALFU =>
                    case addr_base is
                        when b"00" =>
                            dmld_data_o  <= std_logic_vector(resize(unsigned(dmrd_data_i(15 downto 0)), XLEN));
                            dmld_malgn_o <= '0';
                            dmrd_en_o    <= '1';
                        when b"01" =>
                            dmld_data_o  <= std_logic_vector(resize(unsigned(dmrd_data_i(15 downto 0)), XLEN));
                            dmld_malgn_o <= '1';
                            dmrd_en_o    <= '0';
                        when b"10" =>
                            dmld_data_o  <= std_logic_vector(resize(unsigned(dmrd_data_i(31 downto 16)), XLEN));
                            dmld_malgn_o <= '0';
                            dmrd_en_o    <= '1';
                        when b"11" =>
                            dmld_data_o  <= std_logic_vector(resize(unsigned(dmrd_data_i(31 downto 16)), XLEN));
                            dmld_malgn_o <= '1';
                            dmrd_en_o    <= '0';
                        when others =>
                            dmld_data_o  <= (others => '-');
                            dmld_malgn_o <= '-';
                            dmrd_en_o    <= '-';
                    end case;
                when LSU_WORD =>
                    dmld_data_o <= dmrd_data_i;
                    if addr_base = b"00" then
                        dmld_malgn_o <= '0';
                        dmrd_en_o    <= '1';
                    else
                        dmld_malgn_o <= '1';
                        dmrd_en_o    <= '0';
                    end if;
                when others =>
                    dmld_data_o  <= (others => '0');
                    dmld_malgn_o <= '0';
                    dmrd_en_o    <= '0';
            end case;
        else
            dmld_data_o  <= (others => '0');
            dmld_malgn_o <= '0';
            dmrd_en_o    <= '0';
        end if;
    end process read_dmem;

    write_dmem: process(dmem_wr, dmls_dtype_i, dmst_data_i, addr_base)
    begin
        if dmem_wr = '1' then
            case dmls_dtype_i is
                when LSU_BYTE  =>
                    case addr_base is
                        when b"00" =>
                            dmwr_data_o  <= dmst_data_i;
                            dm_byte_en_o <= b"0001";
                        when b"01" =>
                            dmwr_data_o  <= dmst_data_i(23 downto 0) & dmst_data_i(31 downto 24);
                            dm_byte_en_o <= b"0010";
                        when b"10" =>
                            dmwr_data_o  <= dmst_data_i(15 downto 0) & dmst_data_i(31 downto 16);
                            dm_byte_en_o <= b"0100";
                        when b"11" =>
                            dmwr_data_o  <= dmst_data_i(7  downto 0) & dmst_data_i(31 downto  8);
                            dm_byte_en_o <= b"1000";
                        when others =>
                            dmwr_data_o  <= (others => '-');
                            dm_byte_en_o <= (others => '-');
                    end case;
                    dmst_malgn_o <= '0';
                    dmwr_en_o    <= '1';
                when LSU_HALF  =>
                    case addr_base is
                        when b"00" =>
                            dmwr_data_o  <= dmst_data_i;
                            dm_byte_en_o <= b"0011";
                            dmst_malgn_o <= '0';
                            dmwr_en_o    <= '1';
                        when b"01" =>
                            dmwr_data_o  <= dmst_data_i;
                            dm_byte_en_o <= b"0011";
                            dmst_malgn_o <= '1';
                            dmwr_en_o    <= '0';
                        when b"10" =>
                            dmwr_data_o  <= dmst_data_i(15 downto 0) & dmst_data_i(31 downto 16);
                            dm_byte_en_o <= b"1100";
                            dmst_malgn_o <= '0';
                            dmwr_en_o    <= '1';
                        when b"11" =>
                            dmwr_data_o  <= dmst_data_i(15 downto 0) & dmst_data_i(31 downto 16);
                            dm_byte_en_o <= b"1100";
                            dmst_malgn_o <= '1';
                            dmwr_en_o    <= '0';
                        when others =>
                            dmwr_data_o  <= (others => '-');
                            dm_byte_en_o <= (others => '-');
                            dmst_malgn_o <= '-';
                            dmwr_en_o    <= '-';
                    end case;
                when LSU_WORD  =>
                    dmwr_data_o  <= dmst_data_i;
                    dm_byte_en_o <= b"1111";
                    if addr_base = b"00" then
                        dmst_malgn_o <= '0';
                        dmwr_en_o    <= '1';
                    else
                        dmst_malgn_o <= '1';
                        dmwr_en_o    <= '0';
                    end if;
                when others =>
                    dmwr_data_o  <= (others => '0');
                    dm_byte_en_o <= b"0000";
                    dmst_malgn_o <= '0';
                    dmwr_en_o    <= '0';
            end case;
        else
            dmwr_data_o  <= (others => '0');
            dm_byte_en_o <= b"0000";
            dmst_malgn_o <= '0';
            dmwr_en_o    <= '0';
        end if;
    end process write_dmem;

    dmrw_addr_o <= dmls_addr_i(XLEN-1 downto 2) & b"00" when dmls_en_i = '1' else (others => '0');

    dmld_fault_o <= dmrd_err_i and dmem_rd;
    dmst_fault_o <= dmwr_err_i and dmem_wr;

end architecture dmls_block_arch;
