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

    signal core_imem_data: std_logic_vector(31 downto 0);
    signal core_imem_addr: std_logic_vector(31 downto 0);
    signal core_dmrd_data:       std_logic_vector(31 downto 0);
    signal core_dmwr_data:       std_logic_vector(31 downto 0);
    signal core_dmrd_en:         std_logic;
    signal core_dmwr_en:         std_logic;
    signal core_dmrw_addr:    std_logic_vector(31 downto 0);
    signal core_dm_byte_en:    std_logic_vector(3 downto 0);
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

    read_instruction: process(core_imem_addr, rom_rd_data, ram_rd_data0)
        variable base_addr: std_logic_vector(23 downto 0);
    begin
        base_addr := core_imem_addr(31 downto 8);

        case base_addr is
            when x"000001" => core_imem_data <= rom_rd_data;
            when x"000002" => core_imem_data <= ram_rd_data0;
            when others    => core_imem_data <= x"00000013";
        end case;
    end process read_instruction;

    --------------------------- read data --------------------------------
    
    read_data: process(core_dmrw_addr, core_dmrd_en, uart_rd_data, rom_rd_data, ram_rd_data1)
        
        variable base_addr: std_logic_vector(23 downto 0);

    begin

        base_addr := core_dmrw_addr(31 downto 8);

        if core_dmrd_en = '1' then
            case base_addr is
                when x"000000" =>
                    core_dmrd_data(31 downto 16) <= (others => '0');
                    core_dmrd_data(15 downto  0) <= uart_rd_data;
                    uart_rd <= '1';
                when x"000001" =>
                    core_dmrd_data <= rom_rd_data;
                    uart_rd <= '0';
                when x"000002" =>
                    core_dmrd_data <= ram_rd_data1;
                    uart_rd <= '0';
                when others =>
                    core_dmrd_data <= (others => '0');
                    uart_rd <= '0';
            end case;
        else
            core_dmrd_data <= (others => '0');
            uart_rd <= '0';
        end if;
        
    end process read_data;

    -------------------------- write data --------------------------------

    data_write: process(core_dmrw_addr, core_dmwr_en, core_dm_byte_en, core_dmwr_data)
    
        variable base_addr:   std_logic_vector(23 downto 0);
        variable addr_offset: std_logic_vector(1 downto 0);

    begin

        base_addr   := core_dmrw_addr(31 downto 8);
        addr_offset := core_dmrw_addr(1  downto 0);

        if core_dmwr_en = '1' then
            
            case base_addr is
                
                when x"000000" =>
                    ram_wr         <= '0';
                    uart_wr        <= '1';
                    ram_wr_byte_en <= (others => '0');
            
                when x"000002" =>
                    ram_wr         <= '1';
                    uart_wr        <= '0';
                    
                    case core_dm_byte_en is
                        
                        when b"0001" =>

                            case addr_offset is
                                when b"00"  => ram_wr_byte_en <= b"0001";
                                when b"01"  => ram_wr_byte_en <= b"0010";
                                when b"10"  => ram_wr_byte_en <= b"0100";
                                when b"11"  => ram_wr_byte_en <= b"1000";
                                when others => null;
                            end case;

                        when b"0011" =>
                        
                            case addr_offset is
                                when b"00"  => ram_wr_byte_en <= b"0011";
                                when b"01"  => ram_wr_byte_en <= b"0110";
                                when b"10"  => ram_wr_byte_en <= b"1100";
                                when b"11"  => ram_wr_byte_en <= b"1000";
                                when others => null;
                            end case;

                        when others =>

                            ram_wr_byte_en <= core_dm_byte_en;
                    
                    end case;

                when others =>
                    ram_wr         <= '0';
                    uart_wr        <= '0';
                    ram_wr_byte_en <= (others => '0');
            
            end case;

            case addr_offset is
                when b"01"  => ram_wr_data <= core_dmwr_data(23 downto 0) & core_dmwr_data(31 downto 24);
                when b"10"  => ram_wr_data <= core_dmwr_data(15 downto 0) & core_dmwr_data(31 downto 16);
                when b"11"  => ram_wr_data <= core_dmwr_data(7  downto 0) & core_dmwr_data(31 downto  8);
                when others => ram_wr_data <= core_dmwr_data;
            end case;

        else

            ram_wr  <= '0';
            uart_wr <= '0';
            ram_wr_byte_en <= (others => '0');
            ram_wr_data <= (others => '0');

        end if;
        
    end process data_write;

    -------------------------- ROM memory --------------------------------

    rom_rd      <= '1';
    rom_rd_addr <= core_imem_addr(7 downto 2);

    leaf_rom: rom generic map (
        BITS => 8
    ) port map (
        rd      => rom_rd,
        rd_addr => rom_rd_addr,
        rd_data => rom_rd_data
    );

    -------------------------- RAM memory --------------------------------

    ram_rd_addr0   <= core_imem_addr(7 downto 2);
    ram_rd_addr1   <= core_dmrw_addr(7 downto 2);
    ram_wr_addr    <= core_dmrw_addr(7 downto 2);
    
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

    uart_wr_data <= core_dmwr_data(15 downto 0);
    uart_rd_addr <= core_dmrw_addr(3 downto 2);
    uart_wr_addr <= core_dmrw_addr(3 downto 2);

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
        clk        => clk,
        reset      => reset,
        imem_data  => core_imem_data,
        imem_addr  => core_imem_addr,
        dmrd_data  => core_dmrd_data,
        dmwr_data  => core_dmwr_data,
        dmrd_en    => core_dmrd_en,
        dmwr_en    => core_dmwr_en,
        dmrw_addr  => core_dmrw_addr,
        dm_byte_en => core_dm_byte_en,
        ex_irq     => core_ex_irq,
        sw_irq     => core_sw_irq,
        tm_irq     => core_tm_irq
    );

end architecture leaf_chip_arch;