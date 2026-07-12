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
        inst_adr_o   : out std_logic_vector(XLEN-1 downto 2);
        pc_o         : out std_logic_vector(XLEN-1 downto 2);
        next_pc_o    : out std_logic_vector(XLEN-1 downto 2);
        inst_o       : out std_logic_vector(XLEN-1 downto 0);
        retire_o     : out std_logic
    );
end entity if_stage;

architecture rtl of if_stage is

    type fetch_state is (REQUEST, WFETCH, IDLE);

    signal state : fetch_state;

    signal cyc_reg      : std_logic;
    signal stb_reg      : std_logic;
    signal valid_reg    : std_logic;
    signal inst_reg     : std_logic_vector(XLEN-1 downto 0);
    signal inst_err_reg : std_logic;
    signal pc_reg       : std_logic_vector(XLEN-1 downto 2);
    signal adr_reg      : std_logic_vector(XLEN-1 downto 2);
    signal taken_reg    : std_logic;
    signal target_reg   : std_logic_vector(XLEN-1 downto 2);
    signal taken        : std_logic;
    signal target       : std_logic_vector(XLEN-1 downto 2);
    signal next_adr     : std_logic_vector(XLEN-1 downto 2);
    signal pending_cnt  : unsigned(1 downto 0);

begin

    fsm_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state   <= REQUEST;
                cyc_reg <= '1';
                stb_reg <= '1';
            else
                case state is
                    when REQUEST =>
                        if inst_stall_i = '0' then
                            if ready_i = '1' then
                                if pending_cnt = 1 then
                                    state <= WFETCH;
                                    stb_reg <= '0';
                                end if;
                            else
                                if pending_cnt = 0 then
                                    state <= IDLE;
                                    cyc_reg <= '0';
                                    stb_reg <= '0';
                                else
                                    state <= WFETCH;
                                    stb_reg <= '0';
                                end if;
                            end if;
                        end if;
                    when WFETCH =>
                        if inst_ack_i = '1' or inst_err_i = '1' then
                            if ready_i = '1' then
                                state <= REQUEST;
                                stb_reg <= '1';
                            elsif pending_cnt = 1 then
                                state <= IDLE;
                                cyc_reg <= '0';
                                stb_reg <= '0';
                            end if;
                        end if;
                    when IDLE =>
                        if ready_i = '1' then
                            if pending_cnt = 0 then
                                state   <= REQUEST;
                                cyc_reg <= '1';
                                stb_reg <= '1';
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process fsm_proc;

    next_adr <= std_logic_vector(unsigned(adr_reg) + 1);

    pending_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                pending_cnt <= (others => '0');
            elsif (stb_reg = '1' and inst_stall_i = '0') and not (inst_ack_i = '1' or inst_err_i = '1') and pending_cnt /= 2 then
                pending_cnt <= pending_cnt + 1;
            elsif (inst_ack_i = '1' or inst_err_i = '1') and not ((stb_reg = '1' and inst_stall_i = '0') and pending_cnt /= 2) then
                pending_cnt <= pending_cnt - 1;
            end if;
        end if;
    end process pending_proc;

    pc_reg_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                pc_reg      <= (others => '0');
                adr_reg <= RESET_ADDR(XLEN-1 downto 2);
                inst_reg    <= (others => '0');
                inst_err_reg <= '0';
                valid_reg   <= '0';
            else
                case state is
                    when REQUEST | WFETCH =>
                        if inst_ack_i = '1' or inst_err_i = '1' then
                            if ready_i = '1' then
                                if taken = '1' then
                                    pc_reg      <= adr_reg;
                                    adr_reg <= target;
                                    inst_reg    <= (others => '0');
                                    inst_err_reg <= '0';
                                    valid_reg    <= '0';
                                else
                                    pc_reg      <= adr_reg;
                                    adr_reg <= next_adr;
                                    inst_reg    <= inst_dat_i;
                                    inst_err_reg <= inst_err_i;
                                    valid_reg   <= '1';
                                end if;
                            else
                                pc_reg       <= adr_reg;
                                adr_reg  <= next_adr;
                                inst_reg     <= inst_dat_i;
                                inst_err_reg <= inst_err_i;
                                valid_reg    <= '1';
                            end if;
                        else
                            inst_reg     <= (others => '0');
                            inst_err_reg <= '0';
                            valid_reg    <= '0';
                        end if;
                    when IDLE =>
                        if ready_i = '1' then
                            if taken = '1' then
                                pc_reg      <= adr_reg;
                                adr_reg <= target;
                            end if;
                            inst_reg <= (others => '0');
                            inst_err_reg <= '0';
                            valid_reg   <= '0';
                        end if;
                end case;
            end if;
        end if;
    end process pc_reg_proc;

    taken_reg_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                taken_reg  <= '0';
                target_reg <= (others => '0');
            elsif (inst_ack_i = '1' or inst_err_i = '1') and ready_i = '1' then
                taken_reg  <= '0';
                target_reg <= (others => '0');
            elsif state = IDLE and ready_i = '1' then
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

    -- Output assignments --
    inst_cyc_o <= cyc_reg;
    inst_stb_o <= stb_reg;
    inst_adr_o <= adr_reg;
    valid_o    <= valid_reg;
    pc_o       <= pc_reg;
    next_pc_o  <= adr_reg;
    inst_o     <= inst_reg;
    inst_err_o <= inst_err_reg;
    retire_o   <= valid_reg and ready_i;

end architecture rtl;
