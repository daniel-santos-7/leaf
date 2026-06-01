----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: main control
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.leaf_pkg.all;

entity main_ctrl is
    port (
        imrd_malgn_i  : in  std_logic;
        dmld_malgn_i  : in  std_logic;
        dmld_fault_i  : in  std_logic;
        flush_i       : in  std_logic;
        instr_i       : in  std_logic_vector(XLEN-1 downto 0);
        instr_err_o   : out std_logic;
        csrwr_en_o    : out std_logic;
        regwr_en_o    : out std_logic;
        regwr_sel_o   : out std_logic_vector(1  downto 0);
        dmls_mode_o   : out std_logic;
        dmls_en_o     : out std_logic;
        jmp_o         : out std_logic;
        br_en_o       : out std_logic;
        opd0_src_sel_o: out std_logic;
        opd1_src_sel_o: out std_logic;
        opd0_pass_o   : out std_logic;
        opd1_pass_o   : out std_logic;
        alu_op_o      : out std_logic_vector(5  downto 0);
        imm_o         : out std_logic_vector(XLEN-1 downto 0);
        func3_o       : out std_logic_vector(2  downto 0);
        regwr_addr_o  : out std_logic_vector(4  downto 0);
        regrd_addr0_o : out std_logic_vector(4  downto 0);
        regrd_addr1_o : out std_logic_vector(4  downto 0);
        csrs_addr_o   : out std_logic_vector(11 downto 0)
    );
end entity main_ctrl;

architecture main_ctrl_arch of main_ctrl is

    signal imm_type : std_logic_vector(2  downto 0);
    signal opcode   : std_logic_vector(6  downto 0);
    signal payload  : std_logic_vector(24 downto 0);

    signal istg_ctrl : std_logic_vector(3  downto 0);
    signal exec_ctrl : std_logic_vector(7  downto 0);
    signal ftype_s   : std_logic;
    signal op_en_s   : std_logic;

    function resize_signed(value: in std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(resize(signed(value), XLEN));
    end function resize_signed;

begin

    opcode  <= instr_i(6  downto  0);
    payload <= instr_i(31 downto  7);

    imm_gen_ctrl: process(opcode, flush_i)
    begin
        if flush_i = '1' then
            imm_type <= (others => '-');
        else
            case opcode is
                when IMM_OPCODE    => imm_type <= IMM_I_TYPE;
                when JALR_OPCODE   => imm_type <= IMM_I_TYPE;
                when LOAD_OPCODE   => imm_type <= IMM_I_TYPE;
                when LUI_OPCODE    => imm_type <= IMM_U_TYPE;
                when AUIPC_OPCODE  => imm_type <= IMM_U_TYPE;
                when STORE_OPCODE  => imm_type <= IMM_S_TYPE;
                when BRANCH_OPCODE => imm_type <= IMM_B_TYPE;
                when JAL_OPCODE    => imm_type <= IMM_J_TYPE;
                when SYSTEM_OPCODE => imm_type <= IMM_Z_TYPE;
                when others        => imm_type <= (others => '-');
            end case;
        end if;
    end process imm_gen_ctrl;

    gen: process(imm_type, payload)
    begin
        case imm_type is
            when IMM_I_TYPE => imm_o <= resize_signed(payload(24 downto 13));
            when IMM_S_TYPE => imm_o <= resize_signed(payload(24 downto 18) & payload(4 downto 0));
            when IMM_B_TYPE => imm_o <= resize_signed(payload(24) & payload(0) & payload(23 downto 18) & payload(4 downto 1) & '0');
            when IMM_U_TYPE => imm_o <= payload(24 downto 5) & (XLEN-21 downto 0 => '0');
            when IMM_J_TYPE => imm_o <= resize_signed(payload(24) & payload(12 downto 5) & payload(13) & payload(23 downto 14) & '0');
            when IMM_Z_TYPE => imm_o <= std_logic_vector(resize(unsigned(payload(12 downto 8)), XLEN));
            when others     => imm_o <= (XLEN-1 downto 0 => '-');
        end case;
    end process gen;

    istg_block_ctrl: process(opcode, flush_i)
    begin
        if flush_i = '1' then
            istg_ctrl <= (others => '0');
        else
            case opcode is
                when RR_OPCODE     => istg_ctrl <= b"0001";
                when IMM_OPCODE    => istg_ctrl <= b"0001";
                when LUI_OPCODE    => istg_ctrl <= b"0001";
                when AUIPC_OPCODE  => istg_ctrl <= b"0001";
                when JALR_OPCODE   => istg_ctrl <= b"0101";
                when JAL_OPCODE    => istg_ctrl <= b"0101";
                when LOAD_OPCODE   => istg_ctrl <= b"0011";
                when SYSTEM_OPCODE => istg_ctrl <= b"1111";
                when others        => istg_ctrl <= (others => '0');
            end case;
        end if;
    end process istg_block_ctrl;

    exec_block_ctrl: process(opcode, flush_i)
    begin
        if flush_i = '1' then
            exec_ctrl <= (others => '0');
        else
            case opcode is
                when RR_OPCODE     => exec_ctrl <= b"00001101";
                when IMM_OPCODE    => exec_ctrl <= b"00011111";
                when JALR_OPCODE   => exec_ctrl <= b"10011100";
                when BRANCH_OPCODE => exec_ctrl <= b"01111100";
                when AUIPC_OPCODE  => exec_ctrl <= b"00111100";
                when JAL_OPCODE    => exec_ctrl <= b"10111100";
                when LOAD_OPCODE   => exec_ctrl <= b"00011100";
                when STORE_OPCODE  => exec_ctrl <= b"00011100";
                when LUI_OPCODE    => exec_ctrl <= b"00010100";
                when others        => exec_ctrl <= (others => '0');
            end case;
        end if;
    end process exec_block_ctrl;

    dmls_block_ctrl: process(opcode, flush_i)
    begin
        if flush_i = '1' then
            dmls_mode_o <= '0';
            dmls_en_o   <= '0';
        else
            case opcode is
                when LOAD_OPCODE  => dmls_mode_o <= '0'; dmls_en_o <= '1';
                when STORE_OPCODE => dmls_mode_o <= '1'; dmls_en_o <= '1';
                when others       => dmls_mode_o <= '0'; dmls_en_o <= '0';
            end case;
        end if;
    end process dmls_block_ctrl;

    exception_ctrl: process(opcode, flush_i)
    begin
        if flush_i = '1' then
            instr_err_o <= '0';
        else
            case opcode is
                when RR_OPCODE     => instr_err_o <= '0';
                when IMM_OPCODE    => instr_err_o <= '0';
                when JALR_OPCODE   => instr_err_o <= '0';
                when LOAD_OPCODE   => instr_err_o <= '0';
                when STORE_OPCODE  => instr_err_o <= '0';
                when BRANCH_OPCODE => instr_err_o <= '0';
                when LUI_OPCODE    => instr_err_o <= '0';
                when AUIPC_OPCODE  => instr_err_o <= '0';
                when JAL_OPCODE    => instr_err_o <= '0';
                when SYSTEM_OPCODE => instr_err_o <= '0';
                when FENCE_OPCODE  => instr_err_o <= '0';
                when others        => instr_err_o <= '1';
            end case;
        end if;
    end process exception_ctrl;

    regwr_en_o  <= istg_ctrl(0) and not (imrd_malgn_i or dmld_malgn_i or dmld_fault_i);
    regwr_sel_o <= istg_ctrl(2 downto 1);
    csrwr_en_o  <= istg_ctrl(3);

    (jmp_o, br_en_o, opd0_src_sel_o, opd1_src_sel_o, opd0_pass_o, opd1_pass_o, ftype_s, op_en_s) <= exec_ctrl;

    func3_o       <= instr_i(14 downto 12);
    regwr_addr_o  <= instr_i(11 downto  7);
    regrd_addr0_o <= instr_i(19 downto 15);
    regrd_addr1_o <= instr_i(24 downto 20);
    csrs_addr_o   <= instr_i(31 downto 20);

    alu_op_ctrl: process(op_en_s, ftype_s, instr_i)
    begin
        if op_en_s = '0' then
            alu_op_o <= ALU_ADD;
        else
            case instr_i(14 downto 12) is
                when b"000" =>
                    if instr_i(31 downto 25) = b"0100000" and ftype_s = '0' then
                        alu_op_o <= ALU_SUB;
                    else
                        alu_op_o <= ALU_ADD;
                    end if;
                when b"001" => alu_op_o <= ALU_SLL;
                when b"010" => alu_op_o <= ALU_SLT;
                when b"011" => alu_op_o <= ALU_SLTU;
                when b"100" => alu_op_o <= ALU_XOR;
                when b"101" =>
                    if instr_i(31 downto 25) = b"0100000" then
                        alu_op_o <= ALU_SRA;
                    else
                        alu_op_o <= ALU_SRL;
                    end if;
                when b"110" => alu_op_o <= ALU_OR;
                when b"111" => alu_op_o <= ALU_AND;
                when others => alu_op_o <= ALU_ADD;
            end case;
        end if;
    end process alu_op_ctrl;

end architecture main_ctrl_arch;
