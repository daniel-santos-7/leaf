library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity main_ctrl is
    
    port (
        opcode: in std_logic_vector(6 downto 0);
        flush: in std_logic;

        rf_wr_reg_src: out std_logic_vector(1 downto 0);
        rf_wr_reg_en:  out std_logic;
        
        ig_imm_type: out std_logic_vector(2 downto 0);
        
        alu_src0:      out std_logic; 
        alu_src1:      out std_logic; 
        alu_opd0_pass: out std_logic;
        alu_opd1_pass: out std_logic;
        
        alu_op_en:     out std_logic;
        alu_func_type: out std_logic;

        lsu_mode: out std_logic;
        lsu_en:   out std_logic;
        
        brd_en:     out std_logic;

        csrs_wr_en: out std_logic;

        if_jmp:     out std_logic
    );

end entity main_ctrl;

architecture main_ctrl_arch of main_ctrl is
    
begin

    rf_ctrl: process(opcode, flush)
    
    begin

        if flush = '1' then
            
            rf_wr_reg_src <= (others => '-');
            rf_wr_reg_en  <= '0';

        else

            case opcode is

                when RR_OPCODE | IMM_OPCODE | LUI_OPCODE | AUIPC_OPCODE =>
                    
                    rf_wr_reg_src <= b"00";
                    rf_wr_reg_en  <= '1';
    
                when JALR_OPCODE | JAL_OPCODE =>
                        
                    rf_wr_reg_src <= b"10";
                    rf_wr_reg_en  <= '1';
    
                when LOAD_OPCODE =>
                    
                    rf_wr_reg_src <= b"01";
                    rf_wr_reg_en  <= '1';

                when SYSTEM_OPCODE =>

                    rf_wr_reg_src <= b"11";
                    rf_wr_reg_en  <= '1';
    
                when others =>
                    
                    rf_wr_reg_src <= (others => '0');
                    rf_wr_reg_en  <= '0';
                    
            end case;

        end if;

    end process rf_ctrl;

    ig_ctrl: process(opcode, flush)

    begin
        
        if flush = '1' then
            
            ig_imm_type <= (others => '-');

        else

            case opcode is

                when IMM_OPCODE | JALR_OPCODE | LOAD_OPCODE => 
                
                    ig_imm_type <= IMM_I_TYPE;
    
                when LUI_OPCODE | AUIPC_OPCODE => 
                
                    ig_imm_type <= IMM_U_TYPE;
    
                when STORE_OPCODE => 
                
                    ig_imm_type <= IMM_S_TYPE;
    
                when BRANCH_OPCODE => 
                    
                    ig_imm_type <= IMM_B_TYPE;
    
                when JAL_OPCODE => 
                
                    ig_imm_type <= IMM_J_TYPE;

                when SYSTEM_OPCODE =>

                    ig_imm_type <= IMM_Z_TYPE;
    
                when others => 
                    
                    ig_imm_type <= (others => '-');
            
            end case;

        end if;

    end process ig_ctrl;

    alu_ctrl: process(opcode, flush)
    
    begin
    
        if flush = '1' then
            
            alu_src0      <= '0';
            alu_src1      <= '0';
            alu_opd0_pass <= '0';
            alu_opd1_pass <= '0';
            alu_op_en     <= '0';
            alu_func_type <= '0';

        else

            case opcode is

                when RR_OPCODE =>
                        
                    alu_src0      <= '0';
                    alu_src1      <= '0';
                    alu_opd0_pass <= '1';
                    alu_opd1_pass <= '1';
                    alu_op_en     <= '1';
                    alu_func_type <= '0';
    
                when IMM_OPCODE =>
                    
                    alu_src0      <= '0';
                    alu_src1      <= '1';
                    alu_opd0_pass <= '1';
                    alu_opd1_pass <= '1';
                    alu_op_en     <= '1';
                    alu_func_type <= '1';
    
                when JALR_OPCODE => 
    
                    alu_src0      <= '0';
                    alu_src1      <= '1';
                    alu_opd0_pass <= '1';
                    alu_opd1_pass <= '1';
                    alu_op_en     <= '0';
                    alu_func_type <= '0';
    
                when BRANCH_OPCODE | AUIPC_OPCODE | JAL_OPCODE =>
                        
                    alu_src0      <= '1';
                    alu_src1      <= '1';
                    alu_opd0_pass <= '1';
                    alu_opd1_pass <= '1';
                    alu_op_en     <= '0';
                    alu_func_type <= '0';
    
                when LOAD_OPCODE | STORE_OPCODE =>
                        
                    alu_src0      <= '0';
                    alu_src1      <= '1';
                    alu_opd0_pass <= '1';
                    alu_opd1_pass <= '1';
                    alu_op_en     <= '0';
                    alu_func_type <= '0';
    
                when LUI_OPCODE =>
                        
                    alu_src0      <= '-';
                    alu_src1      <= '1';
                    alu_opd0_pass <= '0';
                    alu_opd1_pass <= '1';
                    alu_op_en     <= '0';
                    alu_func_type <= '0';
    
                when others =>
    
                    alu_src0      <= '0';
                    alu_src1      <= '0';
                    alu_opd0_pass <= '0';
                    alu_opd1_pass <= '0';
                    alu_op_en     <= '0';
                    alu_func_type <= '0';
            
            end case;

        end if;

    end process alu_ctrl;

    lsu_ctrl: process(opcode, flush)

    begin
        
        if flush = '1' then
            
            lsu_mode <= '-';
            lsu_en   <= '0';

        else

            case opcode is

                when LOAD_OPCODE =>
                        
                    lsu_mode <= '0';
                    lsu_en   <= '1';
    
                when STORE_OPCODE =>
                        
                    lsu_mode <= '1';
                    lsu_en   <= '1';
    
                when others =>
    
                    lsu_mode <= '-';
                    lsu_en   <= '0';
            
            end case;

        end if;

    end process lsu_ctrl;

    br_detector_ctrl: process(opcode)
    
    begin

        if flush = '1' then
            
            brd_en <= '0';
            
        elsif opcode = BRANCH_OPCODE then
            
            brd_en <= '1';
        
        else

            brd_en <= '0';

        end if;

    end process br_detector_ctrl;

    csrs: process(opcode)
    
    begin
    
        if opcode = SYSTEM_OPCODE then
            
            csrs_wr_en <= '1';

        else

            csrs_wr_en <= '0';

        end if;

    end process csrs;

    if_ctrl: process(opcode, flush)
    
    begin
    
        if flush = '1' then
            
            if_jmp <= '0';

        else

            case opcode is

                when JALR_OPCODE | JAL_OPCODE =>
                    
                    if_jmp <= '1';
    
                when others =>
                    
                    if_jmp <= '0';
            
            end case;

        end if;

    end process if_ctrl;
            
end architecture main_ctrl_arch;