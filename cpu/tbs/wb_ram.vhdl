----------------------------------------------------------------------
-- Project: Leaf
-- Developed by: Daniel Santos
-- Module: Simulator memory with wishbone interface.
-- Date: 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_tb_pkg.all;

entity wb_ram is
    generic (
        PROGRAM   : string;
        DUMP_FILE : string
    );
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;
        dat_i : in  std_logic_vector(31 downto 0);
        cyc_i : in  std_logic;
        stb_i : in  std_logic;
        we_i  : in  std_logic;
        sel_i : in  std_logic_vector(3  downto 0);
        adr_i : in  std_logic_vector(31 downto 0);
        ack_o : out std_logic;
        dat_o : out std_logic_vector(31 downto 0);
        wr_mem_i : in std_logic;
        rd_mem_i : in std_logic;
        halt_o   : out std_logic
    );
end entity wb_ram;

architecture arch of wb_ram is

    signal addr : integer;

    -- idle state --
    signal idle : std_logic;

    -- enable signals --
    signal mem0_en : std_logic;
    signal mem1_en : std_logic;
    signal mem2_en : std_logic;
    signal mem3_en : std_logic;

    -- write enable signals --
    signal mem0_we : std_logic;
    signal mem1_we : std_logic;
    signal mem2_we : std_logic;
    signal mem3_we : std_logic;

    -- read enable signals --
    signal mem0_re : std_logic;
    signal mem1_re : std_logic;
    signal mem2_re : std_logic;
    signal mem3_re : std_logic;

    procedure dump_memory (
        variable file_path : in string;
        variable memory    : in memory_array
    ) is
        variable dump_start : integer;
        variable dump_stop  : integer;
    begin
        dump_start := to_integer(unsigned(mem(DUMP_START_ADDR)(31 downto 2)));
        dump_stop  := to_integer(unsigned(mem(DUMP_STOP_ADDR)(31 downto 2))) - 1;
        if dump_stop >= dump_start and dump_stop < MEM_SIZE/4 then
            write_memory(file_path, memory(dump_start to dump_stop));
        end if;
    end procedure;

begin

    addr <= to_integer(unsigned(adr_i(31 downto 2)));

    idle_reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                idle <= '1';
            elsif idle = '1' then
                idle <= not (cyc_i and stb_i);
            else
                idle <= '1';
            end if;
        end if;
    end process idle_reg;

    mem0_en <= idle and cyc_i and stb_i and sel_i(0);
    mem1_en <= idle and cyc_i and stb_i and sel_i(1);
    mem2_en <= idle and cyc_i and stb_i and sel_i(2);
    mem3_en <= idle and cyc_i and stb_i and sel_i(3);

    mem0_we <= mem0_en and we_i;
    mem1_we <= mem1_en and we_i;
    mem2_we <= mem2_en and we_i;
    mem3_we <= mem3_en and we_i;

    mem0_re <= mem0_en and not we_i;
    mem1_re <= mem1_en and not we_i;
    mem2_re <= mem2_en and not we_i;
    mem3_re <= mem3_en and not we_i;

    write_mem: process(clk_i)

        variable mem : memory_array(0 to MEM_SIZE/4-1);

    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                if rd_mem_i = '1' then
                    read_memory(PROGRAM, mem);
                end if;
                dat_o <= (others => '0');
                halt_o <= '0';
            else
                if addr < mem'length then
                    if mem0_we = '1' then
                        mem(addr)(7  downto 0) := dat_i(7  downto 0);
                    end if;
                    if mem1_we = '1' then
                        mem(addr)(15 downto 8) := dat_i(15 downto 8);
                    end if;
                    if mem2_we = '1' then
                        mem(addr)(23 downto 16) := dat_i(23 downto 16);
                    end if;
                    if mem3_we = '1' then
                        mem(addr)(31 downto 24) := dat_i(31 downto 24);
                    end if;
                    if mem0_re = '1' then
                        dat_o(7  downto  0) <= mem(addr)(7  downto  0);
                    end if;
                    if mem1_re = '1' then
                        dat_o(15 downto  8) <= mem(addr)(15 downto  8);
                    end if;
                    if mem2_re = '1' then
                        dat_o(23 downto 16) <= mem(addr)(23 downto 16);
                    end if;
                    if mem3_re = '1' then
                        dat_o(31 downto 24) <= mem(addr)(31 downto 24);
                    end if;
                end if;
            end if;
            if mem(HALT_CMD_ADDR) = HALT_CMD_DATA then
                halt_o <= '1';
            else
                halt_o <= '0';
            end if;
            if wr_mem_i = '1' then
                dump_memory(DUMP_FILE, mem);
            end if;
        end if;
    end process write_mem;

    ack_o  <= not idle;

end architecture arch;
