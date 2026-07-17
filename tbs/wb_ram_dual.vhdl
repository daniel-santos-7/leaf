library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_tb_pkg.all;

entity wb_ram_dual is
    generic (
        PROGRAM   : string;
        DUMP_FILE : string
    );
    port (
        clk_i : in std_logic;
        rst_i : in std_logic;

        inst_cyc_i : in  std_logic;
        inst_stb_i : in  std_logic;
        inst_adr_i : in  std_logic_vector(31 downto 2);
        inst_dat_o : out std_logic_vector(31 downto 0);
        inst_ack_o : out std_logic;

        data_cyc_i : in  std_logic;
        data_stb_i : in  std_logic;
        data_adr_i : in  std_logic_vector(31 downto 2);
        data_sel_i : in  std_logic_vector(3 downto 0);
        data_we_i  : in  std_logic;
        data_dat_i : in  std_logic_vector(31 downto 0);
        data_dat_o : out std_logic_vector(31 downto 0);
        data_ack_o : out std_logic;

        wr_mem_i : in std_logic;
        rd_mem_i : in std_logic;
        halt_o   : out std_logic
    );
end entity wb_ram_dual;

architecture arch of wb_ram_dual is

    constant MEM_BASE_ADDR : unsigned(29 downto 0) := unsigned(RESET_ADDR(31 downto 2));

    signal inst_addr : integer;
    signal data_addr : integer;

    signal inst_ack_reg : std_logic;
    signal data_ack_reg : std_logic;

    procedure dump_memory (
        constant file_path : in string;
        variable memory    : in memory_array
    ) is
        variable dump_start : integer;
        variable dump_stop  : integer;
        variable stop_val : std_logic_vector(31 downto 0);
        variable start_val : std_logic_vector(31 downto 0);
    begin
        stop_val := memory(DUMP_STOP_ADDR);
        start_val := memory(DUMP_START_ADDR);
        if is_x(stop_val) then
            report "MEM_STOP contains X/U" severity note;
        end if;
        dump_start := to_integer(unsigned(start_val(31 downto 2))-MEM_BASE_ADDR);
        dump_stop  := to_integer(unsigned(stop_val(31 downto 2))-MEM_BASE_ADDR) - 1;
        report "dump_memory: start=" & integer'image(dump_start) & 
               " stop=" & integer'image(dump_stop) & 
               " file=" & file_path severity note;
        if dump_stop >= dump_start and dump_stop < MEM_SIZE/4 then
            report "Writing memory..." severity note;
            write_memory(file_path, memory(dump_start to dump_stop));
        else
            report "Condition failed!" severity note;
        end if;
    end procedure;

begin

    inst_addr <= to_integer(unsigned(inst_adr_i) - MEM_BASE_ADDR);
    data_addr <= to_integer(unsigned(data_adr_i) - MEM_BASE_ADDR);

    inst_ack_o <= inst_ack_reg;
    data_ack_o <= data_ack_reg;

    process(clk_i)
        variable mem : memory_array(0 to MEM_SIZE/4-1);
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                if rd_mem_i = '1' then
                    read_memory(PROGRAM, mem);
                end if;
                inst_dat_o <= (others => '0');
                data_dat_o <= (others => '0');
                inst_ack_reg <= '0';
                data_ack_reg <= '0';
                halt_o <= '0';
            else
                inst_ack_reg <= inst_cyc_i and inst_stb_i;
                data_ack_reg <= data_cyc_i and data_stb_i;

                if inst_addr < mem'length then
                    inst_dat_o <= mem(inst_addr);
                else
                    inst_dat_o <= (others => '0');
                end if;

                if data_addr < mem'length then
                    data_dat_o <= mem(data_addr);
                    if data_we_i = '1' and data_cyc_i = '1' and data_stb_i = '1' then
                        if data_sel_i(0) = '1' then
                            mem(data_addr)(7  downto 0) := data_dat_i(7  downto 0);
                        end if;
                        if data_sel_i(1) = '1' then
                            mem(data_addr)(15 downto 8) := data_dat_i(15 downto 8);
                        end if;
                        if data_sel_i(2) = '1' then
                            mem(data_addr)(23 downto 16) := data_dat_i(23 downto 16);
                        end if;
                        if data_sel_i(3) = '1' then
                            mem(data_addr)(31 downto 24) := data_dat_i(31 downto 24);
                        end if;
                    end if;
                else
                    data_dat_o <= (others => '0');
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
    end process;

end architecture arch;
