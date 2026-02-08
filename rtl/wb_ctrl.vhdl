----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: wishbone master control
-- 2022
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity wb_ctrl is
    port (
        clk_i     : in  std_logic;
        rst_i     : in  std_logic;
        imrd_en   : in  std_logic;
        dmrd_en   : in  std_logic;
        dmwr_en   : in  std_logic;
        ack_i     : in  std_logic;
        err_i     : in  std_logic;
        dat_i     : in  std_logic_vector(31 downto 0);
        dmwr_be   : in  std_logic_vector(3  downto 0);
        imrd_addr : in  std_logic_vector(31 downto 0);
        dmrw_addr : in  std_logic_vector(31 downto 0);
        dmwr_data : in  std_logic_vector(31 downto 0);
        cyc_o     : out std_logic;
        stb_o     : out std_logic;
        we_o      : out std_logic;
        clk_en    : out std_logic;
        reset     : out std_logic;
        imrd_err  : out std_logic;
        dmrd_err  : out std_logic;
        dmwr_err  : out std_logic;
        sel_o     : out std_logic_vector(3  downto 0);
        adr_o     : out std_logic_vector(31 downto 0);
        dat_o     : out std_logic_vector(31 downto 0);
        imrd_data : out std_logic_vector(31 downto 0);
        dmrd_data : out std_logic_vector(31 downto 0)
    );
end entity wb_ctrl;

architecture rtl of wb_ctrl is
    
    type state is (START, IDLE, READ_INSTR, BRD_CYCLE, READ_DATA, RMW_CYCLE, WRITE_DATA, EXECUTE, ERROR);

    signal curr_state: state;
    signal next_state: state;

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

    fsm_next_state: process(curr_state, ack_i, err_i, imrd_en, dmrd_en, dmwr_en)
    begin
        case curr_state is
            when START => 
                next_state <= IDLE;
            when IDLE =>
                if imrd_en = '1' then
                    next_state <= READ_INSTR;
                else
                    next_state <= IDLE;
                end if;
            when READ_INSTR =>
                if ack_i = '1' then
                    if dmrd_en = '1' then
                        next_state <= BRD_CYCLE;
                    elsif dmwr_en = '1' then
                        next_state <= RMW_CYCLE;
                    else
                        next_state <= EXECUTE;
                    end if;
                elsif err_i = '1' then
                    next_state <= ERROR;
                else
                    next_state <= READ_INSTR;
                end if;
            when BRD_CYCLE =>
                next_state <= READ_DATA;
            when READ_DATA =>
                if ack_i = '1' then
                    next_state <= EXECUTE;
                elsif err_i = '1' then
                    next_state <= ERROR;
                else
                    next_state <= READ_DATA;
                end if;
            when RMW_CYCLE =>
                next_state <= WRITE_DATA;
            when WRITE_DATA =>
                if ack_i = '1' then
                    next_state <= EXECUTE;
                elsif err_i = '1' then
                    next_state <= ERROR;
                else
                    next_state <= WRITE_DATA;
                end if;
            when EXECUTE =>
                next_state <= IDLE;
            when ERROR => 
                next_state <= IDLE;
        end case;
    end process fsm_next_state;

    cyc_o <= '0' when curr_state = EXECUTE or curr_state = START or curr_state = ERROR else '1';
    stb_o <= '1' when curr_state = READ_INSTR or curr_state = READ_DATA or curr_state = WRITE_DATA else '0';
    we_o  <= '1' when curr_state = WRITE_DATA else '0';
    
    sel_o <= dmwr_be when curr_state = WRITE_DATA else (others => '1');
    adr_o <= dmrw_addr when curr_state = READ_DATA or curr_state = WRITE_DATA else imrd_addr;
    dat_o <= dmwr_data;

    clk_en <= '1' when curr_state = START or curr_state = EXECUTE or curr_state = ERROR else '0';
    reset  <= '1' when curr_state = START else '0';

    imrd_err <= imrd_en when curr_state = ERROR else '0';
    dmrd_err <= dmrd_en when curr_state = ERROR else '0';
    dmwr_err <= dmwr_en when curr_state = ERROR else '0';

    wr_imrd_data: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                imrd_data <= (others => '0');
            elsif curr_state = READ_INSTR and next_state /= READ_INSTR then
                imrd_data <= dat_i;
            end if;
        end if;
    end process wr_imrd_data;
    
    wr_dmrd_data: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                dmrd_data <= (others => '0');
            elsif curr_state = READ_DATA and next_state /= READ_DATA then
                dmrd_data <= dat_i;
            end if;
        end if;
    end process wr_dmrd_data;

end architecture rtl;