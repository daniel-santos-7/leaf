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
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        dmls_mode_i  : in  std_logic;
        dmls_en_i    : in  std_logic;
        dmls_dtype_i : in  std_logic_vector(2           downto 0);
        dmst_data_i  : in  std_logic_vector(XLEN-1      downto 0);
        dmls_addr_i  : in  std_logic_vector(XLEN-1      downto 0);
        data_dat_i  : in  std_logic_vector(XLEN-1      downto 0);
        data_ack_i  : in  std_logic;
        data_err_i  : in  std_logic;
        data_cyc_o   : out std_logic;
        data_stb_o   : out std_logic;
        dmld_malgn_o : out std_logic;
        dmld_fault_o : out std_logic;
        dmst_malgn_o : out std_logic;
        dmst_fault_o : out std_logic;
        data_dat_o  : out std_logic_vector(XLEN-1      downto 0);
        data_adr_o  : out std_logic_vector(XLEN-1      downto 2);
        data_sel_o : out std_logic_vector(3           downto 0);
        data_we_o  : out std_logic;
        dmls_ready_o : out std_logic;
        dmld_data_o  : out std_logic_vector(XLEN-1      downto 0)
    );
end entity dmls_block;

architecture dmls_block_arch of dmls_block is

    type state_t is (IDLE, BUSY, DONE);
    signal state : state_t;

    signal dmem_rd : std_logic;
    signal dmem_wr : std_logic;

    signal dmrd_en : std_logic;
    signal dmwr_en : std_logic;

    signal addr_base   : std_logic_vector(1 downto 0);
    signal addr_base_wr : std_logic_vector(1 downto 0);


    signal data_adr_reg : std_logic_vector(XLEN-1 downto 0);
    signal data_dat_int : std_logic_vector(XLEN-1 downto 0);
    signal data_sel_int : std_logic_vector(3 downto 0);
    signal data_cyc_reg : std_logic;
    signal data_stb_reg : std_logic;
    signal data_we_reg  : std_logic;
    signal data_dat_reg : std_logic_vector(XLEN-1 downto 0);
    signal data_sel_reg : std_logic_vector(3 downto 0);

    signal dmld_data_comb : std_logic_vector(XLEN-1 downto 0);
    signal dmld_data_reg  : std_logic_vector(XLEN-1 downto 0);

    signal dmld_fault_reg : std_logic;
    signal dmst_fault_reg : std_logic;
    signal dmls_ready_reg : std_logic;

begin

    dmem_rd <= not dmls_mode_i and dmls_en_i;
    dmem_wr <= dmls_mode_i and dmls_en_i;

    addr_base    <= data_adr_reg(1 downto 0) when data_cyc_reg = '1' else dmls_addr_i(1 downto 0);
    addr_base_wr <= dmls_addr_i(1 downto 0);

    read_dmem: process(dmem_rd, dmls_dtype_i, data_dat_i, addr_base)
    begin
        if dmem_rd = '1' then
            case dmls_dtype_i is
                when LSU_BYTE  =>
                    case addr_base is
                        when b"00" => dmld_data_comb <= std_logic_vector(resize(signed(data_dat_i(7  downto 0)), XLEN));
                        when b"01" => dmld_data_comb <= std_logic_vector(resize(signed(data_dat_i(15 downto 8)), XLEN));
                        when b"10" => dmld_data_comb <= std_logic_vector(resize(signed(data_dat_i(23 downto 16)), XLEN));
                        when b"11" => dmld_data_comb <= std_logic_vector(resize(signed(data_dat_i(31 downto 24)), XLEN));
                        when others => dmld_data_comb <= (others => '-');
                    end case;
                    dmld_malgn_o <= '0';
                    dmrd_en    <= '1';
                when LSU_BYTEU =>
                    case addr_base is
                        when b"00" => dmld_data_comb <= std_logic_vector(resize(unsigned(data_dat_i(7  downto 0)), XLEN));
                        when b"01" => dmld_data_comb <= std_logic_vector(resize(unsigned(data_dat_i(15 downto 8)), XLEN));
                        when b"10" => dmld_data_comb <= std_logic_vector(resize(unsigned(data_dat_i(23 downto 16)), XLEN));
                        when b"11" => dmld_data_comb <= std_logic_vector(resize(unsigned(data_dat_i(31 downto 24)), XLEN));
                        when others => dmld_data_comb <= (others => '-');
                    end case;
                    dmld_malgn_o <= '0';
                    dmrd_en    <= '1';
                when LSU_HALF  =>
                    case addr_base is
                        when b"00" =>
                            dmld_data_comb  <= std_logic_vector(resize(signed(data_dat_i(15 downto 0)), XLEN));
                            dmld_malgn_o <= '0';
                            dmrd_en    <= '1';
                        when b"01" =>
                            dmld_data_comb  <= std_logic_vector(resize(signed(data_dat_i(15 downto 0)), XLEN));
                            dmld_malgn_o <= '1';
                            dmrd_en    <= '0';
                        when b"10" =>
                            dmld_data_comb  <= std_logic_vector(resize(signed(data_dat_i(31 downto 16)), XLEN));
                            dmld_malgn_o <= '0';
                            dmrd_en    <= '1';
                        when b"11" =>
                            dmld_data_comb  <= std_logic_vector(resize(signed(data_dat_i(31 downto 16)), XLEN));
                            dmld_malgn_o <= '1';
                            dmrd_en    <= '0';
                        when others =>
                            dmld_data_comb  <= (others => '-');
                            dmld_malgn_o <= '-';
                            dmrd_en    <= '-';
                    end case;
                when LSU_HALFU =>
                    case addr_base is
                        when b"00" =>
                            dmld_data_comb  <= std_logic_vector(resize(unsigned(data_dat_i(15 downto 0)), XLEN));
                            dmld_malgn_o <= '0';
                            dmrd_en    <= '1';
                        when b"01" =>
                            dmld_data_comb  <= std_logic_vector(resize(unsigned(data_dat_i(15 downto 0)), XLEN));
                            dmld_malgn_o <= '1';
                            dmrd_en    <= '0';
                        when b"10" =>
                            dmld_data_comb  <= std_logic_vector(resize(unsigned(data_dat_i(31 downto 16)), XLEN));
                            dmld_malgn_o <= '0';
                            dmrd_en    <= '1';
                        when b"11" =>
                            dmld_data_comb  <= std_logic_vector(resize(unsigned(data_dat_i(31 downto 16)), XLEN));
                            dmld_malgn_o <= '1';
                            dmrd_en    <= '0';
                        when others =>
                            dmld_data_comb  <= (others => '-');
                            dmld_malgn_o <= '-';
                            dmrd_en    <= '-';
                    end case;
                when LSU_WORD =>
                    dmld_data_comb <= data_dat_i;
                    if addr_base = b"00" then
                        dmld_malgn_o <= '0';
                        dmrd_en    <= '1';
                    else
                        dmld_malgn_o <= '1';
                        dmrd_en    <= '0';
                    end if;
                when others =>
                    dmld_data_comb  <= (others => '0');
                    dmld_malgn_o <= '0';
                    dmrd_en    <= '0';
            end case;
        else
            dmld_data_comb  <= (others => '0');
            dmld_malgn_o <= '0';
            dmrd_en    <= '0';
        end if;
    end process read_dmem;

    write_dmem: process(dmem_wr, dmls_dtype_i, dmst_data_i, addr_base_wr)
    begin
        if dmem_wr = '1' then
            case dmls_dtype_i is
                when LSU_BYTE  =>
                    case addr_base_wr is
                        when b"00" =>
                            data_dat_int  <= dmst_data_i;
                            data_sel_int <= b"0001";
                        when b"01" =>
                            data_dat_int  <= dmst_data_i(23 downto 0) & dmst_data_i(31 downto 24);
                            data_sel_int <= b"0010";
                        when b"10" =>
                            data_dat_int  <= dmst_data_i(15 downto 0) & dmst_data_i(31 downto 16);
                            data_sel_int <= b"0100";
                        when b"11" =>
                            data_dat_int  <= dmst_data_i(7  downto 0) & dmst_data_i(31 downto  8);
                            data_sel_int <= b"1000";
                        when others =>
                            data_dat_int  <= (others => '-');
                            data_sel_int <= (others => '-');
                    end case;
                    dmst_malgn_o <= '0';
                    dmwr_en    <= '1';
                when LSU_HALF  =>
                    case addr_base_wr is
                        when b"00" =>
                            data_dat_int  <= dmst_data_i;
                            data_sel_int <= b"0011";
                            dmst_malgn_o <= '0';
                            dmwr_en    <= '1';
                        when b"01" =>
                            data_dat_int  <= dmst_data_i;
                            data_sel_int <= b"0011";
                            dmst_malgn_o <= '1';
                            dmwr_en    <= '0';
                        when b"10" =>
                            data_dat_int  <= dmst_data_i(15 downto 0) & dmst_data_i(31 downto 16);
                            data_sel_int <= b"1100";
                            dmst_malgn_o <= '0';
                            dmwr_en    <= '1';
                        when b"11" =>
                            data_dat_int  <= dmst_data_i(15 downto 0) & dmst_data_i(31 downto 16);
                            data_sel_int <= b"1100";
                            dmst_malgn_o <= '1';
                            dmwr_en    <= '0';
                        when others =>
                            data_dat_int  <= (others => '-');
                            data_sel_int <= (others => '-');
                            dmst_malgn_o <= '-';
                            dmwr_en    <= '-';
                    end case;
                when LSU_WORD  =>
                    data_dat_int  <= dmst_data_i;
                    data_sel_int <= b"1111";
                    if addr_base_wr = b"00" then
                        dmst_malgn_o <= '0';
                        dmwr_en    <= '1';
                    else
                        dmst_malgn_o <= '1';
                        dmwr_en    <= '0';
                    end if;
                when others =>
                    data_dat_int  <= (others => '0');
                    data_sel_int <= b"0000";
                    dmst_malgn_o <= '0';
                    dmwr_en    <= '0';
            end case;
        else
            data_dat_int  <= (others => '0');
            data_sel_int <= b"1111";
            dmst_malgn_o <= '0';
            dmwr_en    <= '0';
        end if;
    end process write_dmem;

    fsm_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state           <= IDLE;
                data_cyc_reg    <= '0';
                data_stb_reg    <= '0';
                data_we_reg     <= '0';
                data_dat_reg    <= (others => '0');
                data_adr_reg    <= (others => '0');
                data_sel_reg    <= (others => '0');
                dmld_data_reg   <= (others => '0');
                dmls_ready_reg  <= '0';
                dmld_fault_reg  <= '0';
                dmst_fault_reg  <= '0';
            else
                case state is
                    when IDLE =>
                        if dmwr_en = '1' or dmrd_en = '1' then
                            state        <= BUSY;
                            data_cyc_reg <= dmrd_en or dmwr_en;
                            data_stb_reg <= dmrd_en or dmwr_en;
                            data_we_reg  <= dmwr_en;
                            data_adr_reg <= dmls_addr_i;
                            data_dat_reg <= data_dat_int;
                            data_sel_reg <= data_sel_int;
                        end if;
                    when BUSY =>
                        if data_ack_i = '1' or data_err_i = '1' then
                            state          <= DONE;
                            dmls_ready_reg <= '1';
                            dmld_data_reg  <= dmld_data_comb;
                            data_cyc_reg   <= '0';
                            data_stb_reg   <= '0';
                            data_we_reg    <= '0';
                            data_dat_reg   <= (others => '0');
                            data_sel_reg   <= (others => '0');
                        end if;
                    when DONE =>
                        state          <= IDLE;
                        dmls_ready_reg <= '0';
                end case;

                dmld_fault_reg <= data_err_i and dmem_rd;
                dmst_fault_reg <= data_err_i and dmem_wr;
            end if;
        end if;
    end process fsm_proc;

    dmld_fault_o <= dmld_fault_reg;
    dmst_fault_o <= dmst_fault_reg;

    data_cyc_o   <= data_cyc_reg;
    data_stb_o   <= data_stb_reg;
    data_we_o    <= data_we_reg;
    data_dat_o   <= data_dat_reg;
    data_sel_o   <= data_sel_reg;
    data_adr_o   <= data_adr_reg(XLEN-1 downto 2);
    dmls_ready_o <= dmls_ready_reg;
    dmld_data_o  <= dmld_data_reg;

end architecture dmls_block_arch;
