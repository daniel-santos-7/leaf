library IEEE;
use IEEE.std_logic_1164.all;
library work;
use work.core_pkg.all;

entity main_ctrl is
    
    port (
        opcode: in std_logic_vector(6 downto 0);
        no_op: in std_logic;
        rf_write_src: out std_logic_vector(1 downto 0);
        rf_write_en: out std_logic;
        ig_imm_type: out std_logic_vector(2 downto 0);
        alu_src0, alu_src1, alu_src0_pass: out std_logic;
        alu_la_op, alu_imm_op: out std_logic;
        lsu_mode, lsu_en: out std_logic;
        br_detector_en: out std_logic;
        if_jmp, if_target_shift: out std_logic
    );

end entity main_ctrl;

architecture main_ctrl_arch of main_ctrl is
    
begin

    process(opcode, no_op)
    
    begin
        
        if no_op = '1' then
            
            rf_write_src <= "--";
            rf_write_en <= '0';
            ig_imm_type <= "---";
            alu_src0 <= '0';
            alu_src1 <= '0';
            alu_src0_pass <= '-';
            alu_la_op <= '0';
            alu_imm_op <= '0';
            lsu_mode <= '-';
            lsu_en <= '0';
            br_detector_en <= '0';
            if_jmp <= '0';
            if_target_shift <= '0';

        else

            case opcode is
                
                when LOGIC_ARITH_OPCODE =>
                    
                    rf_write_src <= b"00";
                    rf_write_en <= '1';
                    ig_imm_type <= "---";
                    alu_src0 <= '0';
                    alu_src1 <= '0';
                    alu_src0_pass <= '1';
                    alu_la_op <= '1';
                    alu_imm_op <= '0';
                    lsu_mode <= '-';
                    lsu_en <= '0';
                    br_detector_en <= '0';
                    if_jmp <= '0';
                    if_target_shift <= '0';
            
                when LOGIC_ARITH_IMM_OPCODE =>
                    
                    rf_write_src <= b"00";
                    rf_write_en <= '1';
                    ig_imm_type <= IMM_I_TYPE;
                    alu_src0 <= '0';
                    alu_src1 <= '1';
                    alu_src0_pass <= '1';
                    alu_la_op <= '1';
                    alu_imm_op <= '1';
                    lsu_mode <= '-';
                    lsu_en <= '0';
                    br_detector_en <= '0';
                    if_jmp <= '0';
                    if_target_shift <= '0';

                when JALR_OPCODE =>
                    
                    rf_write_src <= b"10";
                    rf_write_en <= '1';
                    ig_imm_type <= IMM_I_TYPE;
                    alu_src0 <= '1';
                    alu_src1 <= '1';
                    alu_src0_pass <= '1';
                    alu_la_op <= '0';
                    alu_imm_op <= '0';
                    lsu_mode <= '-';
                    lsu_en <= '0';
                    br_detector_en <= '0';
                    if_jmp <= '1';
                    if_target_shift <= '1';

                when LOAD_OPCODE =>
                    
                    rf_write_src <= b"01";
                    rf_write_en <= '1';
                    ig_imm_type <= IMM_I_TYPE;
                    alu_src0 <= '0';
                    alu_src1 <= '1';
                    alu_src0_pass <= '1';
                    alu_la_op <= '0';
                    alu_imm_op <= '0';
                    lsu_mode <= '0';
                    lsu_en <= '1';
                    br_detector_en <= '0';
                    if_jmp <= '0';
                    if_target_shift <= '0';

                when STORE_OPCODE =>
                    
                    rf_write_src <= "--";
                    rf_write_en <= '0';
                    ig_imm_type <= IMM_S_TYPE;
                    alu_src0 <= '0';
                    alu_src1 <= '1';
                    alu_src0_pass <= '1';
                    alu_la_op <= '0';
                    alu_imm_op <= '0';
                    lsu_mode <= '1';
                    lsu_en <= '1';
                    br_detector_en <= '0';
                    if_jmp <= '0';
                    if_target_shift <= '0';

                when BRANCH_OPCODE =>
                    
                    rf_write_src <= "--";
                    rf_write_en <= '0';
                    ig_imm_type <= IMM_B_TYPE;
                    alu_src0 <= '1';
                    alu_src1 <= '1';
                    alu_src0_pass <= '1';
                    alu_la_op <= '0';
                    alu_imm_op <= '0';
                    lsu_mode <= '-';
                    lsu_en <= '0';
                    br_detector_en <= '1';
                    if_jmp <= '0';
                    if_target_shift <= '0';

                when LOAD_UPPER_IMM_OPCODE =>
                    
                    rf_write_src <= b"00";
                    rf_write_en <= '1';
                    ig_imm_type <= IMM_U_TYPE;
                    alu_src0 <= '-';
                    alu_src1 <= '1';
                    alu_src0_pass <= '0';
                    alu_la_op <= '0';
                    alu_imm_op <= '0';
                    lsu_mode <= '-';
                    lsu_en <= '0';
                    br_detector_en <= '0';
                    if_jmp <= '0';
                    if_target_shift <= '0';

                when ADD_UPPER_IMM_PC_OPCODE =>
                    
                    rf_write_src <= b"00";
                    rf_write_en <= '1';
                    ig_imm_type <= IMM_U_TYPE;
                    alu_src0 <= '1';
                    alu_src1 <= '1';
                    alu_src0_pass <= '1';
                    alu_la_op <= '0';
                    alu_imm_op <= '0';
                    lsu_mode <= '-';
                    lsu_en <= '0';
                    br_detector_en <= '0';
                    if_jmp <= '0';
                    if_target_shift <= '0';

                when JAL_OPCODE =>
                    
                    rf_write_src <= b"10";
                    rf_write_en <= '1';
                    ig_imm_type <= IMM_J_TYPE;
                    alu_src0 <= '1';
                    alu_src1 <= '1';
                    alu_src0_pass <= '1';
                    alu_la_op <= '0';
                    alu_imm_op <= '0';
                    lsu_mode <= '-';
                    lsu_en <= '0';
                    br_detector_en <= '0';
                    if_jmp <= '1';
                    if_target_shift <= '0';

                when others =>
                    
                    rf_write_src <= "--";
                    rf_write_en <= '0';
                    ig_imm_type <= "---";
                    alu_src0 <= '0';
                    alu_src1 <= '0';
                    alu_src0_pass <= '-';
                    alu_la_op <= '0';
                    alu_imm_op <= '0';
                    lsu_mode <= '-';
                    lsu_en <= '0';
                    br_detector_en <= '0';
                    if_jmp <= '0';
                    if_target_shift <= '0';
            
            end case;

        end if;

    end process;
    
end architecture main_ctrl_arch;