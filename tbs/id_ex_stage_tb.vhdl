library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;
use work.tbs_pkg.all;

entity id_ex_stage_tb is
end entity id_ex_stage_tb;

architecture id_ex_stage_tb_arch of id_ex_stage_tb is
    
    signal clk:   std_logic;
    signal reset: std_logic;
    
    signal pc:      std_logic_vector(31 downto 0);
    signal next_pc: std_logic_vector(31 downto 0);
    signal instr:   std_logic_vector(31 downto 0);
    signal flush:   std_logic;
    
    signal rd_mem_data:    std_logic_vector(31 downto 0);
    signal wr_mem_data:    std_logic_vector(31 downto 0);
    signal rd_wr_mem_addr: std_logic_vector(31 downto 0);
    signal wr_mem_byte_en: std_logic_vector(3  downto 0);
    signal rd_mem_en:      std_logic;
    signal wr_mem_en:      std_logic;

    signal ex_irq: std_logic := '0';
    signal sw_irq: std_logic := '0';
    signal tm_irq: std_logic := '0';
    
    signal branch:  std_logic; 
    signal jmp:     std_logic; 
    signal trap:    std_logic;

    signal target: std_logic_vector(31 downto 0);

    procedure tick(signal clk: out std_logic) is

    begin
        
        clk <= '0';
        wait for 50 ns;

        clk <= '1';
        wait for 50 ns;

    end procedure;
    
begin
    
    uut: id_ex_stage port map (
        clk            => clk,
        reset          => reset,
        pc             => pc,
        next_pc        => next_pc,
        instr          => instr,
        flush          => flush,
        rd_mem_data    => rd_mem_data,
        wr_mem_data    => wr_mem_data,
        rd_wr_mem_addr => rd_wr_mem_addr,
        wr_mem_byte_en => wr_mem_byte_en,
        rd_mem_en      => rd_mem_en,
        wr_mem_en      => wr_mem_en,
        ex_irq         => ex_irq,
        sw_irq         => sw_irq,
        tm_irq         => tm_irq,
        branch         => branch, 
        jmp            => jmp, 
        trap           => trap,
        target         => target
    );

    process

    begin

        -- setup --

        clk         <= '0';
        reset       <= '1';

        tick(clk);

        reset       <= '0';

        -- no op instruction --

        pc          <= x"00000000";
        next_pc     <= x"00000004";
        instr       <= x"00000013";
        flush       <= '0';
        rd_mem_data <= x"00000000";
       
        tick(clk);

        assert wr_mem_data    = x"00000000";
        assert rd_wr_mem_addr = x"00000000";
        assert wr_mem_byte_en = b"0000";
        assert rd_mem_en      = '0';
        assert wr_mem_en      = '0';
        assert branch         = '0';
        assert jmp            = '0';
        -- assert trap           = '0';
        assert target         = x"00000000";

        wait;

    end process;
    
end architecture id_ex_stage_tb_arch;