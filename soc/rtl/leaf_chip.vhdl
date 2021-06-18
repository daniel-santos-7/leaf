library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.leaf_chip_pkg.all;

entity leaf_chip is
    
    port (
        clk:   in std_logic;
        reset: in std_logic;

        sdo:  out std_logic;
        sdi:  in  std_logic;
        sclk: out std_logic;
        cs:   out std_logic
    );

end entity leaf_chip;

architecture leaf_chip_arch of leaf_chip is
    
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

    signal rom_rd_data: std_logic_vector(31 downto 0);
    signal rom_rd_addr: std_logic_vector(5 downto 0);

    signal ram_rd_addr0:   std_logic_vector(7  downto 0);
    signal ram_rd_data0:   std_logic_vector(31 downto 0);
    signal ram_rd_addr1:   std_logic_vector(7  downto 0);
    signal ram_rd_data1:   std_logic_vector(31 downto 0);
    signal ram_wr_addr:    std_logic_vector(7  downto 0);
    signal ram_wr_data:    std_logic_vector(31 downto 0);
    signal ram_wr_byte_en: std_logic_vector(3  downto 0);
    signal ram_wr_en:      std_logic;

    signal spi_rd_addr:    std_logic_vector(1  downto 0);
    signal spi_rd_data:    std_logic_vector(31 downto 0);
    signal spi_wr_addr:    std_logic_vector(1  downto 0);
    signal spi_wr_data:    std_logic_vector(31 downto 0);
    signal spi_wr_byte_en: std_logic_vector(3 downto 0);
    signal spi_wr_en:      std_logic;

begin
    
    instr_arbiter: process(core_rd_instr_mem_addr, rom_rd_data, ram_rd_data0)
   
    begin
   
        if core_rd_instr_mem_addr < x"00000100" then
            
            core_rd_instr_mem_data <= x"00000013";

        elsif core_rd_instr_mem_addr < x"00000200" then

            core_rd_instr_mem_data <= rom_rd_data;

        elsif core_rd_instr_mem_addr < x"00000400" then

            core_rd_instr_mem_data <= x"00000013";

        elsif core_rd_instr_mem_addr < x"00000800" then

            core_rd_instr_mem_data <= ram_rd_data0;

        else

            core_rd_instr_mem_data <= x"00000013";

        end if;

    end process instr_arbiter;

    data_arbiter: process(core_rd_wr_mem_addr, core_rd_mem_en, core_wr_mem_en, spi_rd_data, rom_rd_data, ram_rd_data1)
    
    begin
    
        if core_rd_mem_en = '1' then
            
            if core_rd_wr_mem_addr < x"00000100" then
            
                core_rd_mem_data <= spi_rd_data;

            elsif core_rd_wr_mem_addr < x"00000200" then
    
                core_rd_mem_data <= rom_rd_data;
    
            elsif core_rd_wr_mem_addr < x"00000400" then
    
                core_rd_mem_data <= (others => '0');
    
            elsif core_rd_wr_mem_addr < x"00000800" then
    
                core_rd_mem_data <= ram_rd_data1;
    
            else
    
                core_rd_mem_data <= (others => '0');
    
            end if;

        else

            core_rd_mem_data <= (others => '0');

        end if;

        if core_wr_mem_en = '1' then
            
            if core_rd_wr_mem_addr < x"00000100" then
                
                ram_wr_en <= '0';
                spi_wr_en <= '1';

            elsif core_rd_wr_mem_addr < x"00000400" then

                ram_wr_en <= '0';
                spi_wr_en <= '0';

            elsif core_rd_wr_mem_addr < x"00000800" then

                ram_wr_en <= '1';
                spi_wr_en <= '0';

            else

                ram_wr_en <= '0';
                spi_wr_en <= '0';

            end if;

        else

            ram_wr_en <= '0';
            spi_wr_en <= '0';

        end if;
        
    end process data_arbiter;

    rom_rd_addr <= core_rd_instr_mem_addr(7 downto 2);

    ram_rd_addr0   <= core_rd_instr_mem_addr(9 downto 2);
    ram_rd_addr1   <= core_rd_wr_mem_addr(9 downto 2);
    ram_wr_addr    <= core_rd_wr_mem_addr(9 downto 2);
    ram_wr_data    <= core_wr_mem_data;
    ram_wr_byte_en <= core_wr_mem_byte_en;

    spi_rd_addr    <= core_rd_wr_mem_addr(3 downto 2);
    spi_wr_data    <= core_wr_mem_data;
    spi_wr_addr    <= core_rd_wr_mem_addr(3 downto 2);
    spi_wr_byte_en <= core_wr_mem_byte_en;

    core_ex_irq <= '0';
    core_sw_irq <= '0';
    core_tm_irq <= '0';

    leaf_rom: rom generic map (
        MEM_SIZE  => 256,
        ADDR_BITS => 8
    ) port map (
        rd_addr => rom_rd_addr,
        rd_data => rom_rd_data
    );
    
    leaf_ram: ram generic map (
        MEM_SIZE  => 1024,
        ADDR_BITS => 10
    ) port map (
        clk         => clk,
        rd_addr0    => ram_rd_addr0,
        rd_data0    => ram_rd_data0,
        rd_addr1    => ram_rd_addr1,
        rd_data1    => ram_rd_data1,
        wr_addr     => ram_wr_addr,
        wr_data     => ram_wr_data,
        wr_byte_en  => ram_wr_byte_en,
        wr_en       => ram_wr_en
    );

    leaf_spi: spi port map (
        clk        => clk,
        reset      => reset,
        rd_addr    => spi_rd_addr,
        rd_data    => spi_rd_data,
        wr_addr    => spi_wr_addr,
        wr_data    => spi_wr_data,
        wr_byte_en => spi_wr_byte_en,
        wr_en      => spi_wr_en,
        sdo        => sdo,
        sdi        => sdi,
        sclk       => sclk,
        cs         => cs
    );

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