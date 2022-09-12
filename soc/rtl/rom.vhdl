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
        x"1b200293",
        x"00501423",
        x"03100293",
        x"08c000ef",
        x"fea29ee3",
        x"00000593",
        x"09c000ef",
        x"07900593",
        x"094000ef",
        x"00400293",
        x"070000ef",
        x"00831313",
        x"00a30333",
        x"fff28293",
        x"fe0298e3",
        x"00030293",
        x"00010337",
        x"00537c63",
        x"00000593",
        x"068000ef",
        x"01f00593",
        x"060000ef",
        x"fb1ff06f",
        x"00000593",
        x"054000ef",
        x"07900593",
        x"04c000ef",
        x"00010337",
        x"006282b3",
        x"024000ef",
        x"00a30023",
        x"00130313",
        x"fe536ae3",
        x"00000593",
        x"02c000ef",
        x"07900593",
        x"024000ef",
        x"65d0f06f",
        x"00000393",
        x"00400e13",
        x"00004383",
        x"0043f393",
        x"ffc39ce3",
        x"00c02503",
        x"00008067",
        x"00000393",
        x"02000e13",
        x"00004383",
        x"0203f393",
        x"ffc39ce3",
        x"00b00623",
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