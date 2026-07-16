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

    signal taken_reg         : std_logic;
    signal target_reg        : std_logic_vector(XLEN-1 downto 2);
    signal taken             : std_logic;
    signal target            : std_logic_vector(XLEN-1 downto 2);

    -- Registers
    signal adr_reg           : std_logic_vector(XLEN-1 downto 2);
    signal epoch_reg         : std_logic;

    -- Address buffer
    signal adr_data          : std_logic_vector(XLEN-2 downto 0);
    signal adr_valid         : std_logic;
    signal adr_ready         : std_logic;
    signal if_adr_buf_data   : std_logic_vector(XLEN-2 downto 0);
    signal if_adr_buf_valid  : std_logic;
    signal if_adr_buf_ready  : std_logic;

    -- Instruction buffer
    signal inst_data         : std_logic_vector(XLEN downto 0);
    signal inst_valid        : std_logic;
    signal if_inst_buf_data  : std_logic_vector(XLEN downto 0);
    signal if_inst_buf_valid : std_logic;
    signal if_inst_buf_ready : std_logic;

begin

    taken_reg_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                taken_reg  <= '0';
                target_reg <= (others => '0');
            elsif (if_adr_buf_ready = '1' and inst_stall_i = '0') then
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

    epoch_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                epoch_reg <= '0';
            elsif (if_adr_buf_ready = '1' and inst_stall_i = '0') then
                if taken_i = '1' then
                    epoch_reg <= not epoch_reg;
                end if;
            end if;
        end if;
    end process epoch_proc;

    adr_reg_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                adr_reg <= RESET_ADDR(XLEN-1 downto 2);
            elsif (if_adr_buf_ready = '1' and inst_stall_i = '0') then
                if taken = '1' then
                    adr_reg <= target;
                else
                    adr_reg <= std_logic_vector(unsigned(adr_reg) + 1);
                end if;
            end if;
        end if;
    end process adr_reg_proc;

    adr_data   <= epoch_reg & adr_reg;
    adr_valid  <= not inst_stall_i;
    adr_ready  <= if_inst_buf_valid and ready_i;
    inst_data  <= inst_err_i & inst_dat_i;
    inst_valid <= (inst_ack_i or inst_err_i) and if_adr_buf_valid;

    if_adr_buf: fifo_buffer generic map (
        DATA_WIDTH => XLEN-1
    ) port map (
        clk_i   => clk_i,
        reset_i => reset_i,
        data_i  => adr_data,
        valid_i => adr_valid,
        ready_i => adr_ready,
        data_o  => if_adr_buf_data,
        valid_o => if_adr_buf_valid,
        ready_o => if_adr_buf_ready
    );

    if_inst_buf: fifo_buffer generic map (
        DATA_WIDTH => XLEN + 1
    ) port map (
        clk_i   => clk_i,
        reset_i => reset_i,
        data_i  => inst_data,
        valid_i => inst_valid,
        ready_i => ready_i,
        data_o  => if_inst_buf_data,
        valid_o => if_inst_buf_valid,
        ready_o => if_inst_buf_ready
    );

    -- Output assignments --
    inst_cyc_o <= if_inst_buf_ready;
    inst_stb_o <= if_adr_buf_ready;
    inst_adr_o <= adr_reg;
    stale_o    <= if_adr_buf_valid and (if_adr_buf_data(XLEN-2) xor epoch_reg);
    next_pc_o  <= std_logic_vector(unsigned(if_adr_buf_data(XLEN-3 downto 0)) + 1);
    pc_o       <= if_adr_buf_data(XLEN-3 downto 0);
    valid_o    <= if_adr_buf_valid and if_inst_buf_valid;
    inst_err_o <= if_inst_buf_data(XLEN);
    inst_o     <= if_inst_buf_data(XLEN-1 downto 0);
    retire_o   <= if_adr_buf_valid and if_inst_buf_valid and ready_i;

end architecture rtl;
