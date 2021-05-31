library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity main_ctrl is
    
    port (
        opcode: in std_logic_vector(6 downto 0);
        no_op: in std_logic;

        rf_write_src: out std_logic_vector(1 downto 0);
        rf_write_en: out std_logic;
        
        ig_imm_type: out std_logic_vector(2 downto 0);
        
        alu_src0, alu_src1, alu_src0_pass: out std_logic;
        alu_std_op, alu_imm_op: out std_logic;
        
        lsu_mode, lsu_en: out std_logic;
        
        br_detector_en: out std_logic;
        if_jmp, if_target_shift: out std_logic
    );

end entity main_ctrl;

architecture main_ctrl_arch of main_ctrl is
    
    signal rf_write_src_i: std_logic_vector(1 downto 0);
    signal rf_write_en_i: std_logic;
        
    signal ig_imm_type_i: std_logic_vector(2 downto 0);
    
    signal alu_src0_i, alu_src1_i, alu_src0_pass_i: std_logic;
    signal alu_std_op_i, alu_imm_op_i: std_logic;
    
    signal lsu_mode_i, lsu_en_i: std_logic;
    
    signal br_detector_en_i: std_logic;
    signal if_jmp_i, if_target_shift_i: std_logic;

begin

    rf_ctrl: process(opcode)
    
    begin

        case opcode is

            when LOGIC_ARITH_OPCODE | LOGIC_ARITH_IMM_OPCODE | LOAD_UPPER_IMM_OPCODE | ADD_UPPER_IMM_PC_OPCODE =>
                
                rf_write_src_i <= b"00";
                rf_write_en_i <= '1';

            when JALR_OPCODE | JAL_OPCODE =>
                    
                rf_write_src_i <= b"10";
                rf_write_en_i <= '1';

            when LOAD_OPCODE =>
                
                rf_write_src_i <= b"01";
                rf_write_en_i <= '1';

            when others =>
                
                rf_write_src_i <= "--";
                rf_write_en_i <= '0';
                
        end case;

    end process rf_ctrl;

    ig_ctrl: process(opcode)

    begin
        
        case opcode is

            when LOGIC_ARITH_IMM_OPCODE | JALR_OPCODE | LOAD_OPCODE => ig_imm_type_i <= IMM_I_TYPE;

            when LOAD_UPPER_IMM_OPCODE | ADD_UPPER_IMM_PC_OPCODE => ig_imm_type_i <=    IMM_U_TYPE;

            when STORE_OPCODE => ig_imm_type_i  <= IMM_S_TYPE;

            when BRANCH_OPCODE => ig_imm_type_i <= IMM_B_TYPE;

            when JAL_OPCODE => ig_imm_type_i    <= IMM_J_TYPE;

            when others => ig_imm_type_i        <= "---";
        
        end case;

    end process ig_ctrl;

    alu_ctrl: process(opcode)
    
    begin
    
        case opcode is

            when LOGIC_ARITH_OPCODE =>
                    
                alu_src0_i <= '0';
                alu_src1_i <= '0';
                alu_src0_pass_i <= '1';
                alu_std_op_i <= '0';
                alu_imm_op_i <= '0';

            when LOGIC_ARITH_IMM_OPCODE =>
                
                alu_src0_i <= '0';
                alu_src1_i <= '1';
                alu_src0_pass_i <= '1';
                alu_std_op_i <= '0';
                alu_imm_op_i <= '1';

            when JALR_OPCODE => 

                alu_src0_i <= '0';
                alu_src1_i <= '1';
                alu_src0_pass_i <= '1';
                alu_std_op_i <= '1';
                alu_imm_op_i <= '0';

            when BRANCH_OPCODE | ADD_UPPER_IMM_PC_OPCODE | JAL_OPCODE =>
                    
                alu_src0_i <= '1';
                alu_src1_i <= '1';
                alu_src0_pass_i <= '1';
                alu_std_op_i <= '1';
                alu_imm_op_i <= '0';

            when LOAD_OPCODE | STORE_OPCODE =>
                    
                alu_src0_i <= '0';
                alu_src1_i <= '1';
                alu_src0_pass_i <= '1';
                alu_std_op_i <= '1';
                alu_imm_op_i <= '0';

            when LOAD_UPPER_IMM_OPCODE =>
                    
                alu_src0_i <= '-';
                alu_src1_i <= '1';
                alu_src0_pass_i <= '0';
                alu_std_op_i <= '1';
                alu_imm_op_i <= '0';

            when others =>

                alu_src0_i <= '0';
                alu_src1_i <= '0';
                alu_src0_pass_i <= '-';
                alu_std_op_i <= '1';
                alu_imm_op_i <= '0';
        
        end case;

    end process alu_ctrl;

    lsu_ctrl: process(opcode)

    begin
        
        case opcode is

            when LOAD_OPCODE =>
                    
                lsu_mode_i <= '0';
                lsu_en_i <= '1';

            when STORE_OPCODE =>
                    
                lsu_mode_i <= '1';
                lsu_en_i <= '1';

            when others =>

                lsu_mode_i <= '-';
                lsu_en_i <= '0';
        
        end case;

    end process lsu_ctrl;

    br_detector_ctrl: process(opcode)
    
    begin

        if opcode = BRANCH_OPCODE then
            
            br_detector_en_i <= '1';
        
        else

            br_detector_en_i <= '0';

        end if;

    end process br_detector_ctrl;

    if_ctrl: process(opcode)
    
    begin
    
        case opcode is

            when JALR_OPCODE =>
                
                if_jmp_i <= '1';
                if_target_shift_i <= '1';

            when JAL_OPCODE =>
                
                if_jmp_i <= '1';
                if_target_shift_i <= '0';

            when others =>
                
                if_jmp_i <= '0';
                if_target_shift_i <= '0';
        
        end case;

    end process if_ctrl;
            
    rf_write_src    <= "--"     when no_op = '1' else rf_write_src_i;
    rf_write_en     <= '0'      when no_op = '1' else rf_write_en_i;
    ig_imm_type     <= "---"    when no_op = '1' else ig_imm_type_i;
    alu_src0        <= '0'      when no_op = '1' else alu_src0_i;
    alu_src1        <= '0'      when no_op = '1' else alu_src1_i;
    alu_src0_pass   <= '-'      when no_op = '1' else alu_src0_pass_i;
    alu_std_op      <= '1'      when no_op = '1' else alu_std_op_i;
    alu_imm_op      <= '0'      when no_op = '1' else alu_imm_op_i;
    lsu_mode        <= '-'      when no_op = '1' else lsu_mode_i;
    lsu_en          <= '0'      when no_op = '1' else lsu_en_i;
    br_detector_en  <= '0'      when no_op = '1' else br_detector_en_i;
    if_jmp          <= '0'      when no_op = '1' else if_jmp_i;
    if_target_shift <= '0'      when no_op = '1' else if_target_shift_i;
    
end architecture main_ctrl_arch;