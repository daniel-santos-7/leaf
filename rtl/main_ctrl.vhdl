library IEEE;
library work;
use IEEE.std_logic_1164.all;
use work.core_pkg.all;

entity main_ctrl is
    port (
        opcode        : in  std_logic_vector(6 downto 0);
        flush         : in  std_logic;
        int_strg_ctrl : out std_logic_vector(2 downto 0);
        ig_itype      : out std_logic_vector(2 downto 0);
        ex_ctrl       : out ex_ctrl_type;
        dmls_ctrl     : out dmls_ctrl_type;
        brd_en        : out std_logic;
        csrs_wr_en    : out std_logic;
        if_jmp        : out std_logic
    );
end entity main_ctrl;

architecture main_ctrl_arch of main_ctrl is
begin

    rf_ctrl: process(opcode, flush)
    begin

        if flush = '1' then
            int_strg_ctrl <= (others => '0');
        else

            case opcode is
                when RR_OPCODE | IMM_OPCODE | LUI_OPCODE | AUIPC_OPCODE => int_strg_ctrl <= b"001";
                when JALR_OPCODE | JAL_OPCODE => int_strg_ctrl <= b"101";
                when LOAD_OPCODE              => int_strg_ctrl <= b"011";
                when SYSTEM_OPCODE            => int_strg_ctrl <= b"111";
                when others                   => int_strg_ctrl <= (others => '0');
            end case;

        end if;

    end process rf_ctrl;

    ig_ctrl: process(opcode, flush)
    begin
        
        if flush = '1' then
            
            ig_itype <= (others => '-');

        else

            case opcode is
                when IMM_OPCODE | JALR_OPCODE | LOAD_OPCODE => ig_itype <= IMM_I_TYPE;
                when LUI_OPCODE | AUIPC_OPCODE              => ig_itype <= IMM_U_TYPE;
                when STORE_OPCODE                           => ig_itype <= IMM_S_TYPE;
                when BRANCH_OPCODE                          => ig_itype <= IMM_B_TYPE;
                when JAL_OPCODE                             => ig_itype <= IMM_J_TYPE;
                when SYSTEM_OPCODE                          => ig_itype <= IMM_Z_TYPE;
                when others                                 => ig_itype <= (others => '-');
            end case;

        end if;

    end process ig_ctrl;

    ex_ctrl_logic: process(opcode, flush)
    begin

        if flush = '1' then
            
            ex_ctrl <= (
                opd0_src_sel => '0',
                opd1_src_sel => '0',
                opd0_pass    => '0',
                opd1_pass    => '0',
                ftype        => '0',
                op_en        => '0'
            );

        else

            case opcode is
                when RR_OPCODE =>
                    ex_ctrl <= (
                        opd0_src_sel => '0',
                        opd1_src_sel => '0',
                        opd0_pass    => '1',
                        opd1_pass    => '1',
                        ftype        => '0',
                        op_en        => '1'
                    );
                when IMM_OPCODE =>
                    ex_ctrl <= (
                        opd0_src_sel => '0',
                        opd1_src_sel => '1',
                        opd0_pass    => '1',
                        opd1_pass    => '1',
                        ftype        => '1',
                        op_en        => '1'
                    );
                when JALR_OPCODE => 
                    ex_ctrl <= (
                        opd0_src_sel => '0',
                        opd1_src_sel => '1',
                        opd0_pass    => '1',
                        opd1_pass    => '1',
                        ftype        => '0',
                        op_en        => '0'
                    );
                when BRANCH_OPCODE | AUIPC_OPCODE | JAL_OPCODE =>
                    ex_ctrl <= (
                        opd0_src_sel => '1',
                        opd1_src_sel => '1',
                        opd0_pass    => '1',
                        opd1_pass    => '1',
                        ftype        => '0',
                        op_en        => '0'
                    );
                when LOAD_OPCODE | STORE_OPCODE =>
                    ex_ctrl <= (
                        opd0_src_sel => '0',
                        opd1_src_sel => '1',
                        opd0_pass    => '1',
                        opd1_pass    => '1',
                        ftype        => '0',
                        op_en        => '0'
                    );
                when LUI_OPCODE =>
                    ex_ctrl <= (
                        opd0_src_sel => '-',
                        opd1_src_sel => '1',
                        opd0_pass    => '0',
                        opd1_pass    => '1',
                        ftype        => '0',
                        op_en        => '0'
                    );
                when others =>
                    ex_ctrl <= (
                        opd0_src_sel => '0',
                        opd1_src_sel => '0',
                        opd0_pass    => '0',
                        opd1_pass    => '0',
                        ftype        => '0',
                        op_en        => '0'
                    );
            end case;
            
        end if;

    end process ex_ctrl_logic;

    dmls_ctrl_logic: process(opcode, flush)
    begin
        
        if flush = '1' then
            
            dmls_ctrl <= ('-', '0');

        else

            case opcode is
                when LOAD_OPCODE  => dmls_ctrl <= ('0','1');
                when STORE_OPCODE => dmls_ctrl <= ('1','1');
                when others       => dmls_ctrl <= ('-','0');
            end case;

        end if;

    end process dmls_ctrl_logic;

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

    if_ctrl: process(opcode, flush)
    begin
    
        if flush = '1' then
            if_jmp <= '0';
        else

            case opcode is
                when JALR_OPCODE | JAL_OPCODE => if_jmp <= '1';
                when others =>                   if_jmp <= '0';
            end case;

        end if;

    end process if_ctrl;

    csrs: process(opcode)
    begin
    
        if opcode = SYSTEM_OPCODE then
            csrs_wr_en <= '1';
        else
            csrs_wr_en <= '0';
        end if;

    end process csrs;
            
end architecture main_ctrl_arch;