----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- 2021
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.leaf_chip_pkg.all;
use work.uart_pkg.all;

entity leaf_chip is
    port (
        clk:   in  std_logic;
        reset: in  std_logic;
        rx:    in  std_logic;
        tx:    out std_logic
    );
end entity leaf_chip;

architecture leaf_chip_arch of leaf_chip is


    ------------------------ leaf core signals ----------------------------

    signal core_rd_instr_mem_data: std_logic_vector(31 downto 0);
    signal core_rd_instr_mem_addr: std_logic_vector(31 downto 0);
    signal core_rd_mem_data:       std_logic_vector(31 downto 0);
    signal core_wr_mem_data:       std_logic_vector(31 downto 0);
    signal core_rd_mem_en:         std_logic;
    signal core_wr_mem_en:         std_logic;
    signal core_rd_wr_mem_addr:    std_logic_vector(31 downto 0);
    signal core_wr_mem_byte_en:    std_logic_vector(3 downto 0);
    signal core_ex_irq:            std_logic;
    signal core_sw_irq:            std_logic;
    signal core_tm_irq:            std_logic;


    --------------------------- ROM signals ------------------------------

    signal rom_rd:      std_logic;
    signal rom_rd_data: std_logic_vector(31 downto 0);
    signal rom_rd_addr: std_logic_vector(5 downto 0);

    --------------------------- RAM signals ------------------------------

    signal ram_rd_addr0:   std_logic_vector(7  downto 2);
    signal ram_rd_data0:   std_logic_vector(31 downto 0);
    signal ram_rd_addr1:   std_logic_vector(7  downto 2);
    signal ram_rd_data1:   std_logic_vector(31 downto 0);
    signal ram_wr_addr:    std_logic_vector(7  downto 2);
    signal ram_wr_data:    std_logic_vector(31 downto 0);
    signal ram_wr_byte_en: std_logic_vector(3  downto 0);
    signal ram_wr:      std_logic;

    --------------------------- RAM signals ------------------------------

    signal uart_rd_addr: std_logic_vector(1  downto 0);
    signal uart_rd_data: std_logic_vector(15 downto 0);
    signal uart_wr_addr: std_logic_vector(1  downto 0);
    signal uart_wr_data: std_logic_vector(15 downto 0);
    signal uart_wr:      std_logic;
    signal uart_rd:      std_logic;

begin
    
    --------------------- read instructions ----------------------------

    read_instruction: process(core_rd_instr_mem_addr, rom_rd_data, ram_rd_data0)
   
        variable base_addr: std_logic_vector(23 downto 0);

    begin
   
        base_addr := core_rd_instr_mem_addr(31 downto 8);

        case base_addr is
            
            when x"000001" => 

                core_rd_instr_mem_data <= rom_rd_data;

            when x"000002" => 

                core_rd_instr_mem_data <= ram_rd_data0;

            when others => 

                core_rd_instr_mem_data <= x"00000013";
                
        end case;

    end process read_instruction;


    --------------------------- read data --------------------------------
    
    read_data: process(core_rd_wr_mem_addr, core_rd_mem_en, uart_rd_data, rom_rd_data, ram_rd_data1)

        variable base_addr: std_logic_vector(23 downto 0);

    begin

        base_addr := core_rd_wr_mem_addr(31 downto 8);

        if core_rd_mem_en = '1' then

            case base_addr is
                
                when x"000000" =>
                    
                    core_rd_mem_data(31 downto 16) <= (others => '0');
                    core_rd_mem_data(15 downto  0) <= uart_rd_data;
                    uart_rd <= '1';
            
                when x"000001" =>

                    core_rd_mem_data <= rom_rd_data;
                    uart_rd <= '0';

                when x"000002" =>

                    core_rd_mem_data <= ram_rd_data1;
                    uart_rd <= '0';

                when others =>
                    
                    core_rd_mem_data <= (others => '0');
                    uart_rd <= '0';
            
            end case;

        else

            core_rd_mem_data <= (others => '0');
            uart_rd <= '0';

        end if;
        
    end process read_data;

    -------------------------- write data --------------------------------

    data_write: process(core_rd_wr_mem_addr, core_wr_mem_en)
    
        variable base_addr: std_logic_vector(23 downto 0);

    begin

        base_addr := core_rd_wr_mem_addr(31 downto 8);

        if core_wr_mem_en = '1' then
            
            case base_addr is
                
                when x"000000" =>
                    
                    ram_wr <= '0';
                    uart_wr   <= '1';
            
                when x"000002" =>
                    
                    ram_wr <= '1';
                    uart_wr   <= '0';

                when others =>
                    
                    ram_wr <= '0';
                    uart_wr   <= '0';
            
            end case;

        else

            ram_wr  <= '0';
            uart_wr <= '0';

        end if;
        
    end process data_write;

    -------------------------- ROM memory --------------------------------

    rom_rd      <= '1';
    rom_rd_addr <= core_rd_instr_mem_addr(7 downto 2);

    leaf_rom: rom generic map (
        BITS => 8
    ) port map (
        rd      => rom_rd,
        rd_addr => rom_rd_addr,
        rd_data => rom_rd_data
    );

    -------------------------- RAM memory --------------------------------

    ram_rd_addr0   <= core_rd_instr_mem_addr(7 downto 2);
    ram_rd_addr1   <= core_rd_wr_mem_addr(7 downto 2);
    ram_wr_addr    <= core_rd_wr_mem_addr(7 downto 2);
    ram_wr_data    <= core_wr_mem_data;
    ram_wr_byte_en <= core_wr_mem_byte_en;
    
    leaf_ram: ram generic map (
        BITS => 8
    ) port map (
        clk         => clk,
        rd_addr0    => ram_rd_addr0,
        rd_data0    => ram_rd_data0,
        rd_addr1    => ram_rd_addr1,
        rd_data1    => ram_rd_data1,
        wr_addr     => ram_wr_addr,
        wr_data     => ram_wr_data,
        wr_byte_en  => ram_wr_byte_en,
        wr          => ram_wr
    );

    -------------------------- uart module -------------------------------

    uart_wr_data <= core_wr_mem_data(15 downto 0);
    uart_rd_addr <= core_rd_wr_mem_addr(3 downto 2);
    uart_wr_addr <= core_rd_wr_mem_addr(3 downto 2);

    leaf_uart: uart port map(
        clk        => clk,
        reset      => reset,
        rd         => uart_rd,
        rd_addr    => uart_rd_addr,
        rd_data    => uart_rd_data,
        wr         => uart_wr,
        wr_addr    => uart_wr_addr,
        wr_data    => uart_wr_data,
        rx         => rx,
        tx         => tx
    );

    ---------------------------- leaf core -------------------------------

    core_ex_irq <= '0';
    core_sw_irq <= '0';
    core_tm_irq <= '0';

    leaf_core: core generic map (
        RESET_ADDR => x"00000100"
    ) port map (
        clk               => clk,
        reset             => reset,
        rd_instr_mem_data => core_rd_instr_mem_data,
        rd_instr_mem_addr => core_rd_instr_mem_addr,
        rd_mem_data       => core_rd_mem_data,
        wr_mem_data       => core_wr_mem_data,
        rd_mem_en         => core_rd_mem_en,
        wr_mem_en         => core_wr_mem_en,
        rd_wr_mem_addr    => core_rd_wr_mem_addr,
        wr_mem_byte_en    => core_wr_mem_byte_en,
        ex_irq            => core_ex_irq,
        sw_irq            => core_sw_irq,
        tm_irq            => core_tm_irq
    );

end architecture leaf_chip_arch;