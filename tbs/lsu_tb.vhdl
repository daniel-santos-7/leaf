library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity lsu_tb is 
end lsu_tb;

architecture lsu_tb_arch of lsu_tb is

    signal rd_data:         std_logic_vector(31 downto 0);
    signal wr_data:         std_logic_vector(31 downto 0);
    signal rd_wr_addr:      std_logic_vector(31 downto 0);
    signal data_type:       std_logic_vector(2 downto 0);
    signal mode, en:        std_logic;
    signal rd_mem_en:       std_logic;
    signal wr_mem_en:       std_logic;
    signal rd_mem_data:     std_logic_vector(31 downto 0);
    signal wr_mem_data:     std_logic_vector(31 downto 0);
    signal rd_wr_mem_addr:  std_logic_vector(31 downto 0);
    signal wr_mem_byte_en:  std_logic_vector(3 downto 0);

begin
    
    uut: lsu port map (
        rd_data        => rd_data,
        wr_data        => wr_data,
        rd_wr_addr     => rd_wr_addr,
        data_type      => data_type,
        mode           => mode, 
        en             => en,
        rd_mem_en      => rd_mem_en, 
        wr_mem_en      => wr_mem_en,
        rd_mem_data    => rd_mem_data,
        wr_mem_data    => wr_mem_data,
        rd_wr_mem_addr => rd_wr_mem_addr,
        wr_mem_byte_en => wr_mem_byte_en
    );

    process

        constant period: time := 50 ns;

        begin

            rd_mem_data <= x"0000FFFF";
            rd_wr_addr  <= x"00000001";
            wr_data     <= x"FFFF0000";
            
            -- read byte --

            data_type   <= LSU_BYTE;
            mode        <= '0';
            en          <= '0';

            wait for period;
            
            assert rd_mem_en        = '0';
            assert wr_mem_en        = '0';
            assert rd_wr_mem_addr   = x"00000000";
            assert wr_mem_data      = x"00000000";
            assert rd_data          = x"00000000";
            assert wr_mem_byte_en   = b"0000";

            -- read word --

            data_type   <= LSU_WORD;
            mode        <= '0';
            en          <= '1';

            wait for period;
            
            assert rd_mem_en        = '1';
            assert wr_mem_en        = '0';
            assert rd_wr_mem_addr   = x"00000001";
            assert wr_mem_data      = x"00000000";
            assert rd_data          = x"0000FFFF";
            assert wr_mem_byte_en   = b"0000";

            -- write word --

            data_type   <= LSU_WORD;
            mode        <= '1';
            en          <= '1';

            wait for period;
            
            assert rd_mem_en        = '0';
            assert wr_mem_en        = '1';
            assert rd_wr_mem_addr   = x"00000001";
            assert wr_mem_data      = x"FFFF0000";
            assert rd_data          = x"00000000";
            assert wr_mem_byte_en   = b"1111";

            wait;

    end process;
    
end architecture lsu_tb_arch;