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
        pcwr_en_i    : in  std_logic;
        imrd_err_i   : in  std_logic;
        taken_i      : in  std_logic;
        target_i     : in  std_logic_vector(XLEN-1 downto 0);
        imrd_data_i  : in  std_logic_vector(XLEN-1 downto 0);
        imrd_en_o    : out std_logic;
        imrd_fault_o : out std_logic;
        flush_o      : out std_logic;
        retire_o     : out std_logic;
        imrd_addr_o  : out std_logic_vector(XLEN-1 downto 0);
        pc_o         : out std_logic_vector(XLEN-1 downto 0);
        next_pc_o    : out std_logic_vector(XLEN-1 downto 0);
        instr_o      : out std_logic_vector(XLEN-1 downto 0)
    );
end entity if_stage;

architecture rtl of if_stage is

    signal pc_reg   : std_logic_vector(XLEN-1 downto 2);
    signal next_res : std_logic_vector(XLEN-1 downto 2);
    signal flush_val : std_logic;
    signal flush_reg : std_logic;

begin

    next_res   <= std_logic_vector(unsigned(pc_reg) + 1);
    flush_val  <= taken_i or imrd_err_i or not pcwr_en_i;
    imrd_en_o  <= pcwr_en_i;
    imrd_addr_o <= pc_reg & b"00";
    flush_o    <= flush_reg;
    retire_o   <= pcwr_en_i and not flush_reg;

    pc_reg_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                pc_reg <= RESET_ADDR(XLEN-1 downto 2);
            elsif taken_i = '1' then
                pc_reg <= target_i(XLEN-1 downto 2);
            elsif pcwr_en_i = '1' then
                pc_reg <= next_res;
            end if;
        end if;
    end process pc_reg_proc;

    out_pipe_proc: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                imrd_fault_o <= '0';
                flush_reg    <= '1';
                pc_o         <= (others => '0');
                next_pc_o    <= (others => '0');
                instr_o      <= (others => '0');
            else
                imrd_fault_o <= imrd_err_i;
                flush_reg    <= flush_val;
                pc_o         <= pc_reg & b"00";
                next_pc_o    <= next_res & b"00";
                instr_o      <= imrd_data_i;
            end if;
        end if;
    end process out_pipe_proc;

end architecture rtl;
