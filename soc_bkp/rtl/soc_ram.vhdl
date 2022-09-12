library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity soc_ram is
    generic (
        BITS  : natural := 8
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
end entity soc_ram;

architecture rtl of soc_ram is
    
    constant MEM_SIZE: natural := 2**BITS;

    type byte_array is array (0 to MEM_SIZE/4-1) of std_logic_vector(7 downto 0);

    signal mem0: byte_array;
    signal mem1: byte_array;
    signal mem2: byte_array;
    signal mem3: byte_array;

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

    main: process(clk_i)
        variable addr: integer range 0 to MEM_SIZE/4-1;
    begin
        if rising_edge(clk_i) then
            addr := to_integer(unsigned(adr_i));
            if next_state = ACKNOWLEDGEMENT then
                if we_i = '1' then
                    if sel_i(0) = '1' then
                        mem0(addr) <= dat_i(7  downto 0);
                    end if;
                    if sel_i(1) = '1' then
                        mem1(addr) <= dat_i(15 downto 8);
                    end if;
                    if sel_i(2) = '1' then
                        mem2(addr) <= dat_i(23 downto 16);
                    end if;
                    if sel_i(3) = '1' then
                        mem3(addr) <= dat_i(31 downto 24);
                    end if;
                else
                    dat_o(7  downto  0) <= mem0(addr);
                    dat_o(15 downto  8) <= mem1(addr);
                    dat_o(23 downto 16) <= mem2(addr);
                    dat_o(31 downto 24) <= mem3(addr);
                end if;
            end if;
        end if;
    end process main;

    ack_o <= '1' when curr_state = ACKNOWLEDGEMENT else '0';

end architecture rtl;

architecture sim of soc_ram is
    
    constant MEM_SIZE: natural := 2**BITS;

    type byte_array is array (0 to MEM_SIZE/4-1) of std_logic_vector(7 downto 0);

    shared variable mem0: byte_array;
    shared variable mem1: byte_array;
    shared variable mem2: byte_array;
    shared variable mem3: byte_array;

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

    main: process(clk_i)
        variable addr: integer range 0 to MEM_SIZE/4-1;
    begin
        if rising_edge(clk_i) then
            addr := to_integer(unsigned(adr_i));
            if next_state = ACKNOWLEDGEMENT then
                if we_i = '1' then
                    if sel_i(0) = '1' then
                        mem0(addr) := dat_i(7  downto 0);
                    end if;
                    if sel_i(1) = '1' then
                        mem1(addr) := dat_i(15 downto 8);
                    end if;
                    if sel_i(2) = '1' then
                        mem2(addr) := dat_i(23 downto 16);
                    end if;
                    if sel_i(3) = '1' then
                        mem3(addr) := dat_i(31 downto 24);
                    end if;
                else
                    dat_o(7  downto  0) <= mem0(addr);
                    dat_o(15 downto  8) <= mem1(addr);
                    dat_o(23 downto 16) <= mem2(addr);
                    dat_o(31 downto 24) <= mem3(addr);
                end if;
            end if;
        end if;
    end process main;

    ack_o <= '1' when curr_state = ACKNOWLEDGEMENT else '0';
    
end architecture sim;