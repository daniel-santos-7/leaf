library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity main_ctrl_tb is 
end main_ctrl_tb;

architecture main_ctrl_tb_arch of main_ctrl_tb is

    signal opcode: std_logic_vector(6 downto 0);
    signal no_op: std_logic;
    signal rf_write_src: std_logic_vector(1 downto 0);
    signal rf_write_en: std_logic;
    signal ig_imm_type: std_logic_vector(2 downto 0);
    signal alu_src0, alu_src1, alu_src0_pass: std_logic;
    signal alu_std_op, alu_imm_op: std_logic;
    signal lsu_mode, lsu_en: std_logic;
    signal br_detector_en: std_logic;
    signal if_jmp, if_target_shift: std_logic;

begin
    
    uut: main_ctrl port map (
        opcode,
        no_op,
        rf_write_src,
        rf_write_en,
        ig_imm_type,
        alu_src0, 
        alu_src1, 
        alu_src0_pass,
        alu_std_op, 
        alu_imm_op,
        lsu_mode, 
        lsu_en,
        br_detector_en,
        if_jmp, 
        if_target_shift
    );

    process
    
        constant period: time := 10 ns;

    begin
        
        opcode <= LOGIC_ARITH_OPCODE;
            
        wait for period;

        assert rf_write_src = b"00";
        assert rf_write_en = '1';
        assert ig_imm_type = "---";
        assert alu_src0 = '0';
        assert alu_src1 = '0';
        assert alu_src0_pass = '1';
        assert alu_std_op = '0';
        assert alu_imm_op = '0';
        assert lsu_mode = '-';
        assert lsu_en = '0';
        assert br_detector_en = '0';
        assert if_jmp = '0';
        assert if_target_shift = '0';

        opcode <= LOGIC_ARITH_IMM_OPCODE;
            
        wait for period;

        assert rf_write_src = b"00";
        assert rf_write_en = '1';
        assert ig_imm_type = IMM_I_TYPE;
        assert alu_src0 = '0';
        assert alu_src1 = '1';
        assert alu_src0_pass = '1';
        assert alu_std_op = '0';
        assert alu_imm_op = '1';
        assert lsu_mode = '-';
        assert lsu_en = '0';
        assert br_detector_en = '0';
        assert if_jmp = '0';
        assert if_target_shift = '0';

        opcode <= JALR_OPCODE;
            
        wait for period;

        assert rf_write_src = b"10";
        assert rf_write_en = '1';
        assert ig_imm_type = IMM_I_TYPE;
        assert alu_src0 = '0';
        assert alu_src1 = '1';
        assert alu_src0_pass = '1';
        assert alu_std_op = '1';
        assert alu_imm_op = '0';
        assert lsu_mode = '-';
        assert lsu_en = '0';
        assert br_detector_en = '0';
        assert if_jmp = '1';
        assert if_target_shift = '1';

        opcode <= LOAD_OPCODE;
            
        wait for period;

        assert rf_write_src = b"01";
        assert rf_write_en = '1';
        assert ig_imm_type = IMM_I_TYPE;
        assert alu_src0 = '0';
        assert alu_src1 = '1';
        assert alu_src0_pass = '1';
        assert alu_std_op = '1';
        assert alu_imm_op = '0';
        assert lsu_mode = '0';
        assert lsu_en = '1';
        assert br_detector_en = '0';
        assert if_jmp = '0';
        assert if_target_shift = '0';

        opcode <= STORE_OPCODE;
            
        wait for period;

        assert rf_write_src = "--";
        assert rf_write_en = '0';
        assert ig_imm_type = IMM_S_TYPE;
        assert alu_src0 = '0';
        assert alu_src1 = '1';
        assert alu_src0_pass = '1';
        assert alu_std_op = '1';
        assert alu_imm_op = '0';
        assert lsu_mode = '1';
        assert lsu_en = '1';
        assert br_detector_en = '0';
        assert if_jmp = '0';
        assert if_target_shift = '0';

        opcode <= BRANCH_OPCODE;
            
        wait for period;

        assert rf_write_src = "--";
        assert rf_write_en = '0';
        assert ig_imm_type = IMM_B_TYPE;
        assert alu_src0 = '1';
        assert alu_src1 = '1';
        assert alu_src0_pass = '1';
        assert alu_std_op = '1';
        assert alu_imm_op = '0';
        assert lsu_mode = '-';
        assert lsu_en = '0';
        assert br_detector_en = '1';
        assert if_jmp = '0';
        assert if_target_shift = '0';

        opcode <= LOAD_UPPER_IMM_OPCODE;
            
        wait for period;

        assert rf_write_src = b"00";
        assert rf_write_en = '1';
        assert ig_imm_type = IMM_U_TYPE;
        assert alu_src0 = '-';
        assert alu_src1 = '1';
        assert alu_src0_pass = '0';
        assert alu_std_op = '1';
        assert alu_imm_op = '0';
        assert lsu_mode = '-';
        assert lsu_en = '0';
        assert br_detector_en = '0';
        assert if_jmp = '0';
        assert if_target_shift = '0';

        opcode <= ADD_UPPER_IMM_PC_OPCODE;
            
        wait for period;

        assert rf_write_src = b"00";
        assert rf_write_en = '1';
        assert ig_imm_type = IMM_U_TYPE;
        assert alu_src0 = '1';
        assert alu_src1 = '1';
        assert alu_src0_pass = '1';
        assert alu_std_op = '1';
        assert alu_imm_op = '0';
        assert lsu_mode = '-';
        assert lsu_en = '0';
        assert br_detector_en = '0';
        assert if_jmp = '0';
        assert if_target_shift = '0';

        opcode <= JAL_OPCODE;
            
        wait for period;

        assert rf_write_src = b"10";
        assert rf_write_en = '1';
        assert ig_imm_type = IMM_J_TYPE;
        assert alu_src0 = '1';
        assert alu_src1 = '1';
        assert alu_src0_pass = '1';
        assert alu_std_op = '1';
        assert alu_imm_op = '0';
        assert lsu_mode = '-';
        assert lsu_en = '0';
        assert br_detector_en = '0';
        assert if_jmp = '1';
        assert if_target_shift = '0';

        no_op <= '1';

        wait for period;

        assert rf_write_src = "--";
        assert rf_write_en = '0';
        assert ig_imm_type = "---";
        assert alu_src0 = '0';
        assert alu_src1 = '0';
        assert alu_src0_pass = '-';
        assert alu_std_op = '1';
        assert alu_imm_op = '0';
        assert lsu_mode = '-';
        assert lsu_en = '0';
        assert br_detector_en = '0';
        assert if_jmp = '0';
        assert if_target_shift = '0';

        wait;
        
    end process;
    
end architecture main_ctrl_tb_arch;