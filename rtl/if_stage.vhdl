----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: instruction fetch stage
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_pkg.all;

entity if_stage is
    generic (
        RESET_ADDR : std_logic_vector(XLEN-1 downto 0) := (others => '0')
    );
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        ready_i      : in  std_logic;
        inst_ack_i   : in  std_logic;
        inst_err_i   : in  std_logic;
        inst_stall_i : in  std_logic;
        taken_i      : in  std_logic;
        target_i     : in  std_logic_vector(XLEN-1 downto 0);
        inst_dat_i   : in  std_logic_vector(XLEN-1 downto 0);
        inst_err_o   : out std_logic;
        inst_cyc_o   : out std_logic;
        inst_stb_o   : out std_logic;
        valid_o      : out std_logic;
        stale_o      : out std_logic;
        inst_adr_o   : out std_logic_vector(XLEN-1 downto 2);
        pc_o         : out std_logic_vector(XLEN-1 downto 2);
        next_pc_o    : out std_logic_vector(XLEN-1 downto 2);
        inst_o       : out std_logic_vector(XLEN-1 downto 0);
        retire_o     : out std_logic
    );
end entity if_stage;

architecture rtl of if_stage is

    signal taken_reg    : std_logic;
    signal target_reg   : std_logic_vector(XLEN-1 downto 2);
    signal taken        : std_logic;
    signal target       : std_logic_vector(XLEN-1 downto 2);

    type state_t is (BUS_REQUEST, BUS_WAIT);
    signal state_reg   : state_t;
    signal adr_reg : std_logic_vector(XLEN-1 downto 2);
    signal cyc_reg : std_logic;
    signal stb_reg : std_logic;
    signal epoch_reg : std_logic;

    signal adr_buf_data_out  : std_logic_vector(XLEN-2 downto 0);
    signal adr_buf_valid_in  : std_logic;
    signal adr_buf_valid_out : std_logic;
    signal adr_buf_ready_out : std_logic;
    signal adr_buf_ready_in  : std_logic;
    signal tag_match         : std_logic;

    signal inst_buf_data_out  : std_logic_vector(XLEN downto 0);
    signal inst_buf_valid_out : std_logic;
    signal inst_buf_ready_out : std_logic;
    signal inst_buf_valid_in  : std_logic;
    signal inst_buf_data_in   : std_logic_vector(XLEN downto 0);

    signal adr_buf_data_in : std_logic_vector(XLEN-2 downto 0);

begin

    taken_reg_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                taken_reg  <= '0';
                target_reg <= (others => '0');
            elsif (stb_reg = '1' and inst_stall_i = '0') then
                taken_reg  <= '0';
                target_reg <= (others => '0');
            elsif taken_i = '1' then
                taken_reg  <= '1';
                target_reg <= target_i(XLEN-1 downto 2);
            end if;
        end if;
    end process taken_reg_proc;

    taken  <= taken_i or taken_reg;
    target <= target_i(XLEN-1 downto 2) when taken_i = '1' else target_reg;

    tag_match <= '1' when adr_buf_valid_out = '1' and adr_buf_data_out(XLEN-2) = epoch_reg else '0';

    epoch_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                epoch_reg <= '0';
            elsif (stb_reg = '1' and inst_stall_i = '0') then
                if taken_i = '1' then
                    epoch_reg <= not epoch_reg;
                end if;
            end if;
        end if;
    end process epoch_proc;

    --stb_reg_proc: process(clk_i)
    --begin
    --    if rising_edge(clk_i) then
    --        if reset_i = '1' then
    --            cyc_reg <= '0';
    --            stb_reg <= '0';
    --        else
    --            stb_reg <= (adr_buf_ready_out or adr_buf_ready_in) and ready_i;
    --            cyc_reg <= adr_buf_ready_out or adr_buf_ready_in or adr_buf_valid_out;
    --        end if;
    --    end if;
    --end process stb_reg_proc;

    adr_reg_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                adr_reg <= RESET_ADDR(XLEN-1 downto 2);
            elsif (adr_buf_ready_out = '1' and inst_stall_i = '0') then
                if taken = '1' then
                    adr_reg <= target;
                else
                    adr_reg <= std_logic_vector(unsigned(adr_reg) + 1);
                end if;
            end if;
        end if;
    end process adr_reg_proc;

    --fsm_proc: process(clk_i)
    --begin
    --    if rising_edge(clk_i) then
    --        if reset_i = '1' then
    --            state_reg <= BUS_REQUEST;
    --            adr_reg <= RESET_ADDR(XLEN-1 downto 2);
    --            cyc_reg <= '1';
    --            stb_reg <= '1';
    --            adr_buf_valid_in <= '1';
    --        else
    --            case state_reg is
    --                when BUS_REQUEST =>
    --                    if inst_stall_i = '0' then
    --                        if adr_buf_ready_out = '0' then
    --                            state_reg <= BUS_WAIT;
    --                            cyc_reg <= '1';
    --                            stb_reg <= '0';
    --                            adr_reg <= adr_reg;
    --                        else
    --                            if taken = '1' then
    --                                adr_reg <= target;
    --                            else
    --                                adr_reg <= std_logic_vector(unsigned(adr_reg) + 1);
    --                            end if;
    --                        end if;
    --                        adr_buf_valid_in <= '1';
    --                    else
    --                        adr_buf_valid_in <= '0';
    --                    end if;
    --                when BUS_WAIT =>
    --                    if adr_buf_ready_out = '1' then
    --                        state_reg <= BUS_REQUEST;
    --                        cyc_reg <= '1';
    --                        stb_reg <= '1';
    --                        adr_reg <= std_logic_vector(unsigned(adr_reg) + 1);
    --                        adr_buf_valid_in <= '1';
    --                    end if;
    --            end case;
    --        end if;
    --    end if;
    --end process fsm_proc;

    adr_buf_data_in  <= epoch_reg & adr_reg;
    --adr_buf_valid_in <= stb_reg and not inst_stall_i;
    adr_buf_valid_in <= not inst_stall_i;
    adr_buf_ready_in <= inst_buf_valid_out and ready_i;

    adr_buf: skid_buffer generic map (
        DATA_WIDTH => XLEN-1
    ) port map (
        clk_i   => clk_i,
        reset_i => reset_i,
        data_i  => adr_buf_data_in,
        valid_i => adr_buf_valid_in,
        ready_i => adr_buf_ready_in,
        data_o  => adr_buf_data_out,
        valid_o => adr_buf_valid_out,
        ready_o => adr_buf_ready_out
    );

    inst_buf_data_in  <= inst_err_i & inst_dat_i;
    inst_buf_valid_in <= (inst_ack_i or inst_err_i) and adr_buf_valid_out;

    inst_buf: skid_buffer generic map (
        DATA_WIDTH => XLEN + 1
    ) port map (
        clk_i   => clk_i,
        reset_i => reset_i,
        data_i  => inst_buf_data_in,
        valid_i => inst_buf_valid_in,
        ready_i => ready_i,
        data_o  => inst_buf_data_out,
        valid_o => inst_buf_valid_out,
        ready_o => inst_buf_ready_out
    );

    -- Output assignments --
    --inst_cyc_o <= cyc_reg;
    --inst_stb_o <= stb_reg;
    stb_reg <= adr_buf_ready_out;

    inst_cyc_o <= inst_buf_ready_out;
    inst_stb_o <= adr_buf_ready_out;
    inst_adr_o <= adr_reg;
    valid_o    <= adr_buf_valid_out and inst_buf_valid_out;
    stale_o    <= not tag_match;
    next_pc_o  <= std_logic_vector(unsigned(adr_buf_data_out(XLEN-3 downto 0)) + 1);
    pc_o       <= adr_buf_data_out(XLEN-3 downto 0);
    inst_o     <= inst_buf_data_out(XLEN-1 downto 0);
    inst_err_o <= inst_buf_data_out(XLEN);
    retire_o   <= adr_buf_valid_out and inst_buf_valid_out and ready_i;

end architecture rtl;
