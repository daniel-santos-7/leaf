library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity rom is
    generic (
        BITS: natural := 8
    );
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;
        cyc_i : in  std_logic;
        stb_i : in  std_logic;
        adr_i : in  std_logic_vector(BITS-3 downto 0);
        ack_o : out std_logic;
        dat_o : out std_logic_vector(31 downto 0)
    );
end entity rom;

architecture rtl of rom is
    type state is (START, IDLE, ACKNOWLEDGEMENT);

    signal curr_state : state;
    signal next_state : state;

    type mem_array is array (0 to 2**BITS/4-1) of std_logic_vector(31 downto 0);

    constant mem: mem_array := (
        x"00000293",
        x"00000313",
        x"00000393",
        x"00000e13",
        x"000012b7",
        x"45828293",
        x"00501423",
        x"0ff00293",
        x"00500823",
        x"03100293",
        x"038000ef",
        x"fea29ee3",
        x"00f00293",
        x"00500823",
        x"000102b7",
        x"00010337",
        x"00530333",
        x"01c000ef",
        x"00a28023",
        x"00128293",
        x"fe629ae3",
        x"00000293",
        x"00500823",
        x"6a50f06f",
        x"00000393",
        x"00400e13",
        x"00004383",
        x"0043f393",
        x"ffc39ce3",
        x"00c00503",
        x"00008067",
        others => x"00000013"
    );
    
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
    begin
        if rising_edge(clk_i) then
            if next_state = ACKNOWLEDGEMENT then
                dat_o <= mem(to_integer(unsigned(adr_i)));
            end if;
        end if;
    end process main;

    ack_o <= '1' when curr_state = ACKNOWLEDGEMENT else '0';
    
end architecture rtl;