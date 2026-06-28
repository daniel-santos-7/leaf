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
        taken_i  : in  std_logic;
        target_i : in  std_logic_vector(XLEN-1 downto 0);
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

    type fetch_state is (FETCH, DONE, ERROR);
    
    signal state : fetch_state;

    signal req_reg      : std_logic;
    signal valid_reg    : std_logic;
    signal inst_reg     : std_logic_vector(XLEN-1 downto 0);
    signal inst_err_reg : std_logic;
    signal pc_reg       : std_logic_vector(XLEN-1 downto 2);
    signal next_pc_reg  : std_logic_vector(XLEN-1 downto 2);
    signal next_pc      : std_logic_vector(XLEN-1 downto 2);

begin

    fsm_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state        <= FETCH;
                req_reg      <= '1';
                valid_reg    <= '0';
                inst_err_reg <= '0';
            else
                case state is
                    when FETCH =>
                        if inst_ack_i = '1' then
                            state        <= DONE;
                            req_reg      <= '0';
                            valid_reg    <= '1';
                            inst_err_reg <= '0';
                        elsif inst_err_i = '1' then
                            state        <= ERROR;
                            req_reg      <= '0';
                            valid_reg    <= '1';
                            inst_err_reg <= '1';
                        end if;
                    when DONE =>
                        if ready_i = '1' then
                            state        <= FETCH;
                            req_reg      <= '1';
                            valid_reg    <= '0';
                            inst_err_reg <= '0';
                        end if;
                    when ERROR =>
                        if ready_i = '1' then
                            state        <= FETCH;
                            req_reg      <= '1';
                            valid_reg    <= '0';
                            inst_err_reg <= '0';
                        end if;
                end case;
            end if;
        end if;
    end process fsm_proc;

    inst_reg_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                inst_reg <= (others => '0');
            elsif inst_ack_i = '1' and req_reg = '1' then
                inst_reg <= inst_dat_i;
            end if;
        end if;
    end process inst_reg_proc;

    pc_reg_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                pc_reg <= RESET_ADDR(XLEN-1 downto 2);
            elsif ready_i = '1' and valid_reg = '1' then
                if taken_i = '1' then
                    pc_reg <= target_i(XLEN-1 downto 2);
                else
                    pc_reg <= next_pc_reg;
                end if;
            end if;
        end if;
    end process pc_reg_proc;

    next_pc_reg_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                next_pc_reg <= RESET_ADDR(XLEN-1 downto 2);
            elsif ready_i = '1' and valid_reg = '1' and taken_i = '1' then
                next_pc_reg <= target_i(XLEN-1 downto 2);
            elsif state = FETCH and (inst_ack_i = '1' or inst_err_i = '1') then
                next_pc_reg <= next_pc;
            end if;
        end if;
    end process next_pc_reg_proc;

    -- Outputs --
    next_pc     <= std_logic_vector(unsigned(pc_reg) + 1);
    inst_adr_o  <= pc_reg;
    inst_err_o  <= inst_err_reg;
    inst_cyc_o  <= req_reg;
    inst_stb_o  <= req_reg;
    valid_o     <= valid_reg;
    pc_o        <= pc_reg;
    next_pc_o   <= next_pc;
    inst_o      <= inst_reg;
    retire_o    <= valid_reg and ready_i;

end architecture rtl;
