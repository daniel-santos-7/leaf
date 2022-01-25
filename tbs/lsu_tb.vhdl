library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity lsu_tb is 
end lsu_tb;

architecture lsu_tb_arch of lsu_tb is

    signal dmld_data:         std_logic_vector(31 downto 0);
    signal dmst_data:         std_logic_vector(31 downto 0);
    signal dmls_addr:      std_logic_vector(31 downto 0);
    signal mode, en:        std_logic;

    signal dmls_dtype: std_logic_vector(2 downto 0);
    signal dmls_ctrl:  std_logic_vector(1 downto 0);

    signal dmrd_en:       std_logic;
    signal dmwr_en:       std_logic;
    signal dmrd_data:     std_logic_vector(31 downto 0);
    signal dmwr_data:     std_logic_vector(31 downto 0);
    signal dmrw_addr:  std_logic_vector(31 downto 0);
    signal dm_byte_en:  std_logic_vector(3 downto 0);

begin
    
    dmls_ctrl <= mode & en;

    uut: lsu port map (
        dmld_data        => dmld_data,
        dmst_data        => dmst_data,
        dmls_addr     => dmls_addr,
        dmls_dtype     => dmls_dtype,
        dmls_ctrl      => dmls_ctrl,
        dmrd_en      => dmrd_en, 
        dmwr_en      => dmwr_en,
        dmrd_data    => dmrd_data,
        dmwr_data    => dmwr_data,
        dmrw_addr => dmrw_addr,
        dm_byte_en => dm_byte_en
    );

    process

        constant period: time := 50 ns;

        begin

            dmrd_data <= x"0000FFFF";
            dmls_addr  <= x"00000001";
            dmst_data     <= x"FFFF0000";
            
            -- read byte --

            dmls_dtype   <= LSU_BYTE;
            mode        <= '0';
            en          <= '0';

            wait for period;
            
            assert dmrd_en        = '0';
            assert dmwr_en        = '0';
            assert dmrw_addr   = x"00000000";
            assert dmwr_data      = x"00000000";
            assert dmld_data          = x"00000000";
            assert dm_byte_en   = b"0000";

            -- read word --

            dmls_dtype   <= LSU_WORD;
            mode        <= '0';
            en          <= '1';

            wait for period;
            
            assert dmrd_en        = '1';
            assert dmwr_en        = '0';
            assert dmrw_addr   = x"00000001";
            assert dmwr_data      = x"00000000";
            assert dmld_data          = x"0000FFFF";
            assert dm_byte_en   = b"0000";

            -- write word --

            dmls_dtype   <= LSU_WORD;
            mode        <= '1';
            en          <= '1';

            wait for period;
            
            assert dmrd_en        = '0';
            assert dmwr_en        = '1';
            assert dmrw_addr   = x"00000001";
            assert dmwr_data      = x"FFFF0000";
            assert dmld_data          = x"00000000";
            assert dm_byte_en   = b"1111";

            wait;

    end process;
    
end architecture lsu_tb_arch;