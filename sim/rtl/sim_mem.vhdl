----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: memory (simulator) with wishbone interface
-- 2022
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sim_mem is
    generic (
        BITS    : natural := 8;
        PROGRAM : string
    );
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;
        dat_i : in  std_logic_vector(31 downto 0);
        cyc_i : in  std_logic;
        stb_i : in  std_logic;
        we_i  : in  std_logic;
        sel_i : in  std_logic_vector(3  downto 0);        
        adr_i : in  std_logic_vector(BITS-3 downto 0);
        ack_o : out std_logic;
        dat_o : out std_logic_vector(31 downto 0)
    );
end entity sim_mem;

architecture sim_mem_arch of sim_mem is
    
    constant MEM_SIZE: natural := 2**BITS;

    type byte_array is array (0 to MEM_SIZE/4-1) of std_logic_vector(7 downto 0);

    shared variable mem0: byte_array;
    shared variable mem1: byte_array;
    shared variable mem2: byte_array;
    shared variable mem3: byte_array;

    signal ack : std_logic;

    type state is (START, IDLE, ACKNOWLEDGEMENT);

    signal curr_state : state;
    signal next_state : state;

begin

    fsm: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                curr_state <= START;
            else
                curr_state <= next_state;
            end if;
        end if;
    end process fsm;

    fsm_next_state: process(curr_state, cyc_i, stb_i)
    begin
        case curr_state is
            when START =>
                next_state <= IDLE;
            when IDLE =>
                if cyc_i = '1' and stb_i = '1' then
                    next_state <= ACKNOWLEDGEMENT;
                else
                    next_state <= IDLE;
                end if;
            when ACKNOWLEDGEMENT =>
                if cyc_i = '1' and stb_i = '1' then
                    next_state <= IDLE;
                else
                    next_state <= ACKNOWLEDGEMENT;
                end if;
        end case;
    end process fsm_next_state;

    wr_data: process(clk_i)
        subtype byte_type is character;
        type bin_type is file of byte_type;

        file bin: bin_type;
        variable byte: byte_type;

        variable addr: integer range 0 to MEM_SIZE/4-1;

        variable mem0_wr: std_logic;
        variable mem1_wr: std_logic;
        variable mem2_wr: std_logic;
        variable mem3_wr: std_logic;
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                file_open(bin, PROGRAM);
                addr := 0;
                while not endfile(bin) and addr <= MEM_SIZE/4-1 loop
                    read(bin, byte);
                    mem0(addr) := std_logic_vector(to_unsigned(byte_type'pos(byte), 8));
                    read(bin, byte);
                    mem1(addr) := std_logic_vector(to_unsigned(byte_type'pos(byte), 8));
                    read(bin, byte);
                    mem2(addr) := std_logic_vector(to_unsigned(byte_type'pos(byte), 8));
                    read(bin, byte);
                    mem3(addr) := std_logic_vector(to_unsigned(byte_type'pos(byte), 8));
                    addr := addr + 1;
                end loop;
                file_close(bin);
            elsif next_state = ACKNOWLEDGEMENT and we_i = '1' then
                addr := to_integer(unsigned(adr_i));

                mem0_wr := sel_i(0);
                mem1_wr := sel_i(1);
                mem2_wr := sel_i(2);
                mem3_wr := sel_i(3);

                if mem0_wr = '1' then
                    mem0(addr) := dat_i(7  downto 0);
                end if;

                if mem1_wr = '1' then
                    mem1(addr) := dat_i(15 downto 8);
                end if;

                if mem2_wr = '1' then
                    mem2(addr) := dat_i(23 downto 16);
                end if;

                if mem3_wr = '1' then
                    mem3(addr) := dat_i(31 downto 24);
                end if;
            end if;
        end if;
    end process wr_data;

    rd_data: process(clk_i)
        variable addr: integer range 0 to MEM_SIZE/4-1;
    begin
        addr := to_integer(unsigned(adr_i));
        if rising_edge(clk_i) then
            if next_state = ACKNOWLEDGEMENT and we_i = '0' then
                dat_o(7  downto  0) <= mem0(addr);
                dat_o(15 downto  8) <= mem1(addr);
                dat_o(23 downto 16) <= mem2(addr);
                dat_o(31 downto 24) <= mem3(addr);
            end if;
        end if;
    end process rd_data;

    ack_o <= '1' when curr_state = ACKNOWLEDGEMENT else '0';

end architecture sim_mem_arch;