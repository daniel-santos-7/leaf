library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity csrs_tb is 
end csrs_tb;

architecture csrs_tb_arch of csrs_tb is

    signal clk:   std_logic;
    signal reset: std_logic;

    signal ex_irq: std_logic;
    signal sw_irq: std_logic;
    signal tm_irq: std_logic;

    signal wr_mode: std_logic_vector(2 downto 0);
    signal wr_en:   std_logic;

    signal rd_wr_addr:  std_logic_vector(11 downto 0);
    signal wr_reg_data: std_logic_vector(31 downto 0);
    signal wr_imm_data: std_logic_vector(31 downto 0);
    signal rd_data:     std_logic_vector(31 downto 0);

    procedure tick(signal clk: out std_logic) is

    begin
        
        clk <= '0';
        wait for 5 ns;
        
        clk <= '1';
        wait for 5 ns;

    end procedure;

begin
    
    uut: csrs 
    generic map (
        MHART_ID => (others => '0')
    )
    port map (
        clk         => clk,
        reset       => reset,
        ex_irq      => ex_irq,
        sw_irq      => sw_irq,
        tm_irq      => tm_irq,
        wr_mode     => wr_mode,
        wr_en       => wr_en,
        rd_wr_addr  => rd_wr_addr,
        wr_reg_data => wr_reg_data,
        wr_imm_data => wr_imm_data,
        rd_data     => rd_data
    );

    process

        constant period: time := 50 ns;

    begin

        -- setup --
        
        clk   <= '0';
        reset <= '1';

        ex_irq <= '0';
        sw_irq <= '0';
        tm_irq <= '0';

        wr_mode <= b"000";
        wr_en   <= '0';

        rd_wr_addr  <= (others => '0');
        wr_reg_data <= (others => '0');
        wr_imm_data <= (others => '0');

        tick(clk);

        reset <= '0';

        -- read MHARTID --

        rd_wr_addr <= CSR_ADDR_MHARTID;

        tick(clk);

        assert rd_data = x"00000000";

        -- read MISA --

        rd_wr_addr <= CSR_ADDR_MISA;

        tick(clk);

        assert rd_data = x"40000100";

        -- write/read MSTATUS --

        rd_wr_addr  <= CSR_ADDR_MSTATUS;

        tick(clk);

        assert rd_data = x"00000080";

        wr_en       <= '1';
        wr_reg_data <= x"FFFFFFFF";
        wr_mode     <= b"001";

        tick(clk);

        wr_en       <= '0';

        assert rd_data = x"00000088";

        -- read/set MIE --

        rd_wr_addr  <= CSR_ADDR_MIE;
        wr_en       <= '1';
        wr_reg_data <= x"FFFFFFFF";
        wr_mode     <= b"010";

        tick(clk);

        wr_en       <= '0';

        assert rd_data = x"00000888";

        -- read/clear MTVEC --

        rd_wr_addr  <= CSR_ADDR_MTVEC;
        wr_en       <= '1';
        wr_reg_data <= x"FFFFFFFF";
        wr_mode     <= b"011";

        tick(clk);

        wr_en       <= '0';

        assert rd_data = x"00000000";

        -- read/write imm MSCRATCH --

        rd_wr_addr  <= CSR_ADDR_MSCRATCH;
        wr_en       <= '1';
        wr_imm_data <= x"0000001F";
        wr_mode     <= b"101";

        tick(clk);

        wr_en       <= '0';

        assert rd_data = x"0000001F";

        -- read/set imm MEPC --

        rd_wr_addr  <= CSR_ADDR_MEPC;
        wr_en       <= '1';
        wr_imm_data <= x"0000001C";
        wr_mode     <= b"110";

        tick(clk);

        wr_en       <= '0';

        assert rd_data = x"0000001C";

        -- read/clear imm MCAUSE --

        rd_wr_addr  <= CSR_ADDR_MCAUSE;
        wr_en       <= '1';
        wr_imm_data <= x"0000001F";
        wr_mode     <= b"111";

        tick(clk);

        wr_en       <= '0';

        assert rd_data = x"00000000";

        -- read/write imm MTVAL --

        rd_wr_addr  <= CSR_ADDR_MTVAL;
        wr_en       <= '1';
        wr_imm_data <= x"0000001F";
        wr_mode     <= b"101";

        tick(clk);

        wr_en       <= '0';

        assert rd_data = x"0000001F";

        -- read MIP --

        rd_wr_addr  <= CSR_ADDR_MIP;
        
        ex_irq      <= '1';
        tm_irq      <= '1';
        sw_irq      <= '1';
        
        wr_mode     <= b"000";

        tick(clk);

        assert rd_data = x"00000888";

        wait;

    end process;
    
end architecture csrs_tb_arch;