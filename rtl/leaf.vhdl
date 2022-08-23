library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;

entity leaf is
    generic (
        RESET_ADDR : std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        clk_i : in  std_logic;
        rst_i : in  std_logic;
        ack_i : in  std_logic;
        dat_i : in  std_logic_vector(31 downto 0);
        cyc_o : out std_logic;
        stb_o : out std_logic;
        we_o  : out std_logic;
        sel_o : out std_logic_vector(3  downto 0);
        adr_o : out std_logic_vector(31 downto 0);
        dat_o : out std_logic_vector(31 downto 0)
    );
end entity leaf;

architecture leaf_arch of leaf is
    
    -- internal clock and reset
    signal clk   : std_logic;
    signal reset : std_logic;

    -- instruction memory signals --
    signal imem_data : std_logic_vector(31 downto 0);
    signal imem_addr : std_logic_vector(31 downto 0);

    -- data memory signals --
    signal dmrd_data : std_logic_vector(31 downto 0);
    signal dmwr_data : std_logic_vector(31 downto 0);
    signal dmrd_en   : std_logic;
    signal dmwr_en   : std_logic;
    signal dmrw_addr : std_logic_vector(31 downto 0);
    signal dm_byte_en: std_logic_vector(3  downto 0);

    -- interruptions --
    signal ex_irq : std_logic;
    signal sw_irq : std_logic;
    signal tm_irq : std_logic;

    type state is (START, READ_INSTR, BRD_CYCLE, READ_DATA, RMW_CYCLE, WRITE_DATA, EXECUTE);

    signal curr_state: state;
    signal next_state: state;  

    signal tclk : std_logic;

begin

    fsm: process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            curr_state <= START;
        elsif rising_edge(clk_i) then
            curr_state <= next_state;
        end if;
    end process fsm;

    fsm_next_state: process(curr_state, ack_i, dmrd_en, dmwr_en)
    begin
        case curr_state is
            when START => 
                next_state <= READ_INSTR;
            when READ_INSTR =>
                if ack_i = '1' then
                    if dmrd_en = '1' then
                        next_state <= BRD_CYCLE;
                    elsif dmwr_en = '1' then
                        next_state <= RMW_CYCLE;
                    else
                        next_state <= EXECUTE;
                    end if;
                else
                    next_state <= READ_INSTR;
                end if;
            when BRD_CYCLE =>
                next_state <= READ_DATA;
            when READ_DATA =>
                if ack_i = '1' then
                    next_state <= EXECUTE;
                else
                    next_state <= READ_DATA;
                end if;
            when RMW_CYCLE =>
                next_state <= WRITE_DATA;
            when WRITE_DATA =>
                if ack_i = '1' then
                    next_state <= EXECUTE;
                else
                    next_state <= WRITE_DATA;
                end if;
            when EXECUTE =>
                next_state <= READ_INSTR;
        end case;
    end process fsm_next_state;

    cyc_o <= '0' when curr_state = EXECUTE or curr_state = START else '1';
    stb_o <= '1' when curr_state = READ_INSTR or curr_state = READ_DATA or curr_state = WRITE_DATA else '0';
    we_o  <= '1' when curr_state = WRITE_DATA else '0';
    sel_o <= dm_byte_en when curr_state = WRITE_DATA else (others => '0');
    
    adr_o <= dmrw_addr when curr_state = READ_DATA or curr_state = WRITE_DATA else imem_addr;
    dat_o <= dmwr_data;

    clk   <= clk_i when curr_state = START or curr_state = EXECUTE;
    reset <= '1' when curr_state = START else '0';
        
    ex_irq <= '0';
    sw_irq <= '0';
    tm_irq <= '0';

    wr_imem_data: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if ack_i = '1' and curr_state = READ_INSTR then
                imem_data <= dat_i;
            end if;
        end if;
    end process wr_imem_data;

    wr_dmwr_data: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if ack_i = '1' and curr_state = READ_DATA then
                dmrd_data <= dat_i;
            end if;
        end if;
    end process wr_dmwr_data;
    
    leaf_core: core generic map (
        RESET_ADDR  => RESET_ADDR
    ) port map (
        clk         => clk, 
        reset       => reset,
        imem_data   => imem_data,
        imem_addr   => imem_addr,
        dmrd_data   => dmrd_data,
        dmwr_data   => dmwr_data,
        dmrd_en     => dmrd_en,
        dmwr_en     => dmwr_en,
        dmrw_addr   => dmrw_addr,
        dm_byte_en  => dm_byte_en,
        ex_irq      => ex_irq,
        sw_irq      => sw_irq,
        tm_irq      => tm_irq
    );
    
end architecture leaf_arch;