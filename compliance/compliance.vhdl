library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;
use work.compliance_pkg.all;

entity compliance is
    generic (
        PROGRAM_FILE:   string;
        DUMP_FILE:      string;
        MEMORY_SIZE:       integer
    );
end entity compliance;

architecture compliance_arch of compliance is
    
    signal clk        : std_logic;
    signal reset      : std_logic;
    signal imem_data  : std_logic_vector(31 downto 0);
    signal imem_addr  : std_logic_vector(31 downto 0);
    signal dmrw_addr  : std_logic_vector(31 downto 0);
    signal dmrd_data  : std_logic_vector(31 downto 0);
    signal dmwr_data  : std_logic_vector(31 downto 0);
    signal dmrd_en    : std_logic;
    signal dmwr_en    : std_logic;
    signal dm_byte_en : std_logic_vector(3  downto 0);
    signal ex_irq     : std_logic := '0';
    signal sw_irq     : std_logic := '0';
    signal tm_irq     : std_logic := '0';

    constant CLK_PERIOD : time := 20 ns;

    shared variable ram : byte_array(0 to MEMORY_SIZE-1) := (others => x"00");
        
    signal halt_sim_data  : std_logic_vector(31 downto 0);
    signal begin_sig_data : std_logic_vector(31 downto 0);
    signal end_sig_data   : std_logic_vector(31 downto 0);

    signal sim_started  : boolean := false;
    signal sim_finished : boolean := false;

begin
    
    uut: core port map (
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

    mem_wr: process (sim_started, clk)
        variable addr: integer;
    begin
        if sim_started then
            if rising_edge(clk) then
                if dmwr_en = '1' then
                    addr := to_integer(unsigned(dmrw_addr));
                    case dm_byte_en is
                        when b"0001" => 
                            ram(addr + 0) := dmwr_data(7 downto 0);
                        when b"0011" => 
                            ram(addr + 0) := dmwr_data(7  downto 0);
                            ram(addr + 1) := dmwr_data(15 downto 8);
                        when others => 
                            ram(addr + 0) := dmwr_data(7  downto 0);
                            ram(addr + 1) := dmwr_data(15 downto 8);
                            ram(addr + 2) := dmwr_data(23 downto 16);
                            ram(addr + 3) := dmwr_data(31 downto 24);
                    end case;
                end if;
            end if;
        else
            read_bin_file(PROGRAM_FILE, ram);
        end if;
    end process mem_wr;

    rd_instr: process(imem_addr)
        variable addr : integer;
    begin
        addr := to_integer(unsigned(imem_addr));
        imem_data(7  downto  0) <= ram(addr + 0);
        imem_data(15 downto  8) <= ram(addr + 1);
        imem_data(23 downto 16) <= ram(addr + 2);
        imem_data(31 downto 24) <= ram(addr + 3);
    end process rd_instr;

    rd_data: process (clk, dmrd_en, dmrd_data)
        variable addr: integer;
    begin
        if dmrd_en = '1' then
            addr := to_integer(unsigned(dmrw_addr));
            dmrd_data(7  downto  0) <= ram(addr + 0);
            dmrd_data(15 downto  8) <= ram(addr + 1);
            dmrd_data(23 downto 16) <= ram(addr + 2);
            dmrd_data(31 downto 24) <= ram(addr + 3);
        else
            dmrd_data <= (others => '0');
        end if;
    end process rd_data;

    halt_sim_reg: process(clk)
        constant ADDR : integer := MEMORY_SIZE - 13;
    begin
        if rising_edge(clk) then
            halt_sim_data(7  downto  0)  <= ram(ADDR + 0);
            halt_sim_data(15 downto  8)  <= ram(ADDR + 1);
            halt_sim_data(23 downto 16)  <= ram(ADDR + 2);
            halt_sim_data(31 downto 24)  <= ram(ADDR + 3);
        end if;
    end process halt_sim_reg;

    begin_sig_reg: process(clk)
        constant ADDR : integer := MEMORY_SIZE - 9;
    begin
        if rising_edge(clk) then
            begin_sig_data(7  downto  0)  <= ram(ADDR + 0);
            begin_sig_data(15 downto  8)  <= ram(ADDR + 1);
            begin_sig_data(23 downto 16)  <= ram(ADDR + 2);
            begin_sig_data(31 downto 24)  <= ram(ADDR + 3);
        end if;
    end process begin_sig_reg;

    end_sig_reg: process(clk)
        constant ADDR : integer := MEMORY_SIZE - 5;
    begin
        if rising_edge(clk) then
            end_sig_data(7  downto  0)  <= ram(ADDR + 0);
            end_sig_data(15 downto  8)  <= ram(ADDR + 1);
            end_sig_data(23 downto 16)  <= ram(ADDR + 2);
            end_sig_data(31 downto 24)  <= ram(ADDR + 3);
        end if;
    end process end_sig_reg;

    wr_dump: process(sim_finished)
        variable begin_addr : integer;
        variable end_addr   : integer;
    begin
        if sim_finished then
            begin_addr := to_integer(unsigned(begin_sig_data));
            end_addr   := to_integer(unsigned(end_sig_data));
            write_txt_file(DUMP_FILE, ram, begin_addr, end_addr);
        end if;
    end process wr_dump;

    clk <= not clk after (CLK_PERIOD/2) when sim_started and not sim_finished else '0';
    
    reset <= '0' after CLK_PERIOD when sim_started else '1';

    sim_finished <= halt_sim_data = x"00000001";

    sim_started <= false, true after CLK_PERIOD;

end architecture compliance_arch;