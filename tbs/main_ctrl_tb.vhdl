library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity main_ctrl_tb is 
end main_ctrl_tb;

architecture main_ctrl_tb_arch of main_ctrl_tb is

    signal opcode: std_logic_vector(6 downto 0);
    signal rf_write_en, rf_write_src: std_logic;
    signal lsu_mode, lsu_en: std_logic;
    signal branch, jal, jalr: std_logic;

begin
    
    uut: main_ctrl port map (
        opcode, 
        rf_write_en, 
        rf_write_src, 
        lsu_mode, 
        lsu_en, 
        branch, 
        jal, 
        jalr
    );

    process
    
        constant period: time := 50 ns;

    begin
        
        opcode <= LOGIC_ARITH_OPCODE;
            
        wait for period;

        assert (rf_write_en ='1');
        assert (rf_write_src = '0');
        assert (lsu_mode = '0');
        assert (lsu_en = '0');
        assert (branch = '0');
        assert (jal = '0');
        assert (jalr = '0');
    
        opcode <= LOGIC_ARITH_IMM_OPCODE;

        wait for period;
            
        assert (rf_write_en ='1');
        assert (rf_write_src = '0');
        assert (lsu_mode = '0');
        assert (lsu_en = '0');
        assert (branch = '0');
        assert (jal = '0');
        assert (jalr = '0');

        opcode <= JALR_OPCODE;
        
        wait for period;
            
        assert (rf_write_en = '1');
        assert (rf_write_src = '0');
        assert (lsu_mode = '0');
        assert (lsu_en = '0');
        assert (branch = '0');
        assert (jal = '0');
        assert (jalr = '1');

        opcode <= LOAD_OPCODE;

        wait for period;
            
        assert (rf_write_en ='1');
        assert (rf_write_src = '1');
        assert (lsu_mode = '0');
        assert (lsu_en = '1');
        assert (branch = '0');
        assert (jal = '0');
        assert (jalr = '0');

        opcode <= STORE_OPCODE;

        wait for period;

        assert (rf_write_en = '0');
        assert (rf_write_src = '0');
        assert (lsu_mode = '1');
        assert (lsu_en = '1');
        assert (branch = '0');
        assert (jal = '0');
        assert (jalr = '0');

        opcode <= BRANCH_OPCODE;

        wait for period;

        assert (rf_write_en = '0');
        assert (rf_write_src = '0');
        assert (lsu_mode = '0');
        assert (lsu_en = '0');
        assert (branch = '1');
        assert (jal = '0');
        assert (jalr = '0');

        opcode <= JAL_OPCODE;

        wait for period;

        assert (rf_write_en <='1');
        assert (rf_write_src <= '0');
        assert (lsu_mode <= '0');
        assert (lsu_en <= '0');
        assert (branch <= '0');
        assert (jal <= '1');
        assert (jalr <= '0');

        wait;
        
    end process;
    
end architecture main_ctrl_tb_arch;