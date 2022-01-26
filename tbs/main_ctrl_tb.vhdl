library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity main_ctrl_tb is 
end main_ctrl_tb;

architecture main_ctrl_tb_arch of main_ctrl_tb is

    signal opcode: std_logic_vector(6 downto 0);
    signal flush:  std_logic;

    signal int_strg_ctrl: std_logic_vector(2 downto 0);
    signal rf_wr_reg_src: std_logic_vector(1 downto 0);
    signal rf_wr_reg_en:  std_logic;
    
    signal ig_imm_type: std_logic_vector(2 downto 0);
    
    signal alu_src0:      std_logic; 
    signal alu_src1:      std_logic;
    signal alu_opd0_pass: std_logic;
    signal alu_opd1_pass: std_logic;
    signal alu_op_en:     std_logic;
    signal alu_func_type: std_logic;
    
    signal lsu_mode: std_logic;
    signal lsu_en:   std_logic;
    
    signal brd_en: std_logic;

    signal csrs_wr_en: std_logic;

    signal if_jmp:     std_logic; 

begin
    
    uut: main_ctrl port map (
        opcode          => opcode,
        flush           => flush,
        -- rf_wr_reg_src   => rf_wr_reg_src,
        -- rf_wr_reg_en    => rf_wr_reg_en,
        int_strg_ctrl   => int_strg_ctrl,
        ig_imm_type     => ig_imm_type,
        alu_src0        => alu_src0, 
        alu_src1        => alu_src1,
        alu_opd0_pass   => alu_opd0_pass,
        alu_opd1_pass   => alu_opd1_pass, 
        alu_op_en       => alu_op_en,
        alu_func_type   => alu_func_type,
        lsu_mode        => lsu_mode, 
        lsu_en          => lsu_en,
        brd_en          => brd_en,
        csrs_wr_en      => csrs_wr_en,
        if_jmp          => if_jmp
    );

    rf_wr_reg_en <= int_strg_ctrl(0);
    rf_wr_reg_src <= int_strg_ctrl(2 downto 1);

    process
    
        constant period: time := 10 ns;

    begin
        
        -- RR instructions --

        opcode <= RR_OPCODE;
            
        wait for period;

        assert rf_wr_reg_src = b"00";
        assert rf_wr_reg_en  = '1';
        assert alu_src0      = '0';
        assert alu_src1      = '0';
        assert alu_opd0_pass = '1';
        assert alu_opd1_pass = '1';
        assert alu_func_type = '0';
        assert alu_op_en     = '1';
        assert lsu_en        = '0';
        assert brd_en        = '0';
        assert if_jmp        = '0';

        -- IMM instructions --

        opcode <= IMM_OPCODE;
            
        wait for period;

        assert rf_wr_reg_src = b"00";
        assert rf_wr_reg_en  = '1';
        assert ig_imm_type   = IMM_I_TYPE;
        assert alu_src0      = '0';
        assert alu_src1      = '1';
        assert alu_opd0_pass = '1';
        assert alu_opd1_pass = '1';
        assert alu_func_type = '1';
        assert alu_op_en     = '1';
        assert lsu_en        = '0';
        assert brd_en        = '0';
        assert if_jmp        = '0';

        -- JALR instruction --

        opcode <= JALR_OPCODE;
            
        wait for period;

        assert rf_wr_reg_src = b"10";
        assert rf_wr_reg_en  = '1';
        assert ig_imm_type   = IMM_I_TYPE;
        assert alu_src0      = '0';
        assert alu_src1      = '1';
        assert alu_opd0_pass = '1';
        assert alu_opd0_pass = '1';
        assert alu_op_en     = '0';
        assert lsu_en        = '0';
        assert brd_en        = '0';
        assert if_jmp        = '1';

        -- LOAD instruction --

        opcode <= LOAD_OPCODE;
            
        wait for period;

        assert rf_wr_reg_src = b"01";
        assert rf_wr_reg_en  = '1';
        assert ig_imm_type   = IMM_I_TYPE;
        assert alu_src0      = '0';
        assert alu_src1      = '1';
        assert alu_opd0_pass = '1';
        assert alu_opd1_pass = '1';
        assert alu_op_en     = '0';
        assert lsu_mode      = '0';
        assert lsu_en        = '1';
        assert brd_en        = '0';
        assert if_jmp        = '0';

        -- STORE instruction --

        opcode <= STORE_OPCODE;
            
        wait for period;

        assert rf_wr_reg_en  = '0';
        assert ig_imm_type   = IMM_S_TYPE;
        assert alu_src0      = '0';
        assert alu_src1      = '1';
        assert alu_opd0_pass = '1';
        assert alu_opd1_pass = '1';
        assert alu_op_en     = '0';
        assert lsu_mode      = '1';
        assert lsu_en        = '1';
        assert brd_en        = '0';
        assert if_jmp        = '0';

        -- opcode <= BRANCH_OPCODE;
            
        -- wait for period;

        -- assert rf_write_src = "--";
        -- assert rf_write_en = '0';
        -- assert ig_imm_type = IMM_B_TYPE;
        -- assert alu_src0 = '1';
        -- assert alu_src1 = '1';
        -- assert alu_src0_pass = '1';
        -- assert alu_std_op = '1';
        -- assert alu_imm_op = '0';
        -- assert lsu_mode = '-';
        -- assert lsu_en = '0';
        -- assert br_detector_en = '1';
        -- assert if_jmp = '0';
        -- assert if_target_shift = '0';

        -- opcode <= LOAD_UPPER_IMM_OPCODE;
            
        -- wait for period;

        -- assert rf_write_src = b"00";
        -- assert rf_write_en = '1';
        -- assert ig_imm_type = IMM_U_TYPE;
        -- assert alu_src0 = '-';
        -- assert alu_src1 = '1';
        -- assert alu_src0_pass = '0';
        -- assert alu_std_op = '1';
        -- assert alu_imm_op = '0';
        -- assert lsu_mode = '-';
        -- assert lsu_en = '0';
        -- assert br_detector_en = '0';
        -- assert if_jmp = '0';
        -- assert if_target_shift = '0';

        -- opcode <= ADD_UPPER_IMM_PC_OPCODE;
            
        -- wait for period;

        -- assert rf_write_src = b"00";
        -- assert rf_write_en = '1';
        -- assert ig_imm_type = IMM_U_TYPE;
        -- assert alu_src0 = '1';
        -- assert alu_src1 = '1';
        -- assert alu_src0_pass = '1';
        -- assert alu_std_op = '1';
        -- assert alu_imm_op = '0';
        -- assert lsu_mode = '-';
        -- assert lsu_en = '0';
        -- assert br_detector_en = '0';
        -- assert if_jmp = '0';
        -- assert if_target_shift = '0';

        -- opcode <= JAL_OPCODE;
            
        -- wait for period;

        -- assert rf_write_src = b"10";
        -- assert rf_write_en = '1';
        -- assert ig_imm_type = IMM_J_TYPE;
        -- assert alu_src0 = '1';
        -- assert alu_src1 = '1';
        -- assert alu_src0_pass = '1';
        -- assert alu_std_op = '1';
        -- assert alu_imm_op = '0';
        -- assert lsu_mode = '-';
        -- assert lsu_en = '0';
        -- assert br_detector_en = '0';
        -- assert if_jmp = '1';
        -- assert if_target_shift = '0';

        -- no_op <= '1';

        -- wait for period;

        -- assert rf_write_src = "--";
        -- assert rf_write_en = '0';
        -- assert ig_imm_type = "---";
        -- assert alu_src0 = '0';
        -- assert alu_src1 = '0';
        -- assert alu_src0_pass = '-';
        -- assert alu_std_op = '1';
        -- assert alu_imm_op = '0';
        -- assert lsu_mode = '-';
        -- assert lsu_en = '0';
        -- assert br_detector_en = '0';
        -- assert if_jmp = '0';
        -- assert if_target_shift = '0';

        wait;
        
    end process;
    
end architecture main_ctrl_tb_arch;