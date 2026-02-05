----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: main control
-- 2022
----------------------------------------------------------------------

library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.core_pkg.all;

entity main_ctrl is
    port (
        flush     : in  std_logic;
        opcode    : in  std_logic_vector(6 downto 0);
        payload   : in  std_logic_vector(24 downto 0);
        instr_err : out std_logic;
        imm       : out std_logic_vector(31 downto 0);
        istg_ctrl : out std_logic_vector(3 downto 0);
        exec_ctrl : out std_logic_vector(7 downto 0);
        dmls_ctrl : out std_logic_vector(1 downto 0)
    );
end entity main_ctrl;

architecture main_ctrl_arch of main_ctrl is

    signal imm_type : std_logic_vector(2  downto 0);

    function resize_signed(value: in std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(resize(signed(value), 32));
    end function resize_signed;

begin

    imm_gen_ctrl: process(opcode, flush)
    begin
        if flush = '1' then
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
            when IMM_I_TYPE => imm <= resize_signed(payload(24 downto 13));
            when IMM_S_TYPE => imm <= resize_signed(payload(24 downto 18) & payload(4 downto 0));
            when IMM_B_TYPE => imm <= resize_signed(payload(24) & payload(0) & payload(23 downto 18) & payload(4 downto 1) & '0');
            when IMM_U_TYPE => imm <= payload(24 downto 5) & (11 downto 0 => '0');
            when IMM_J_TYPE => imm <= resize_signed(payload(24) & payload(12 downto 5) & payload(13) & payload(23 downto 14) & '0');
            when IMM_Z_TYPE => imm <= std_logic_vector(resize(unsigned(payload(19 downto 15)), 32));
            when others     => imm <= (31 downto 0 => '-');
        end case;
    end process gen;

    istg_block_ctrl: process(opcode, flush)
    begin
        if flush = '1' then
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

    exec_block_ctrl: process(opcode, flush)
    begin
        if flush = '1' then
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

    dmls_block_ctrl: process(opcode, flush)
    begin
        if flush = '1' then
            dmls_ctrl <= b"00";
        else
            case opcode is
                when LOAD_OPCODE  => dmls_ctrl <= b"01";
                when STORE_OPCODE => dmls_ctrl <= b"11";
                when others       => dmls_ctrl <= b"00";
            end case;
        end if;
    end process dmls_block_ctrl;

    exception_ctrl: process(opcode, flush)
    begin
        if flush = '1' then
            instr_err <= '0';
        else
            case opcode is
                when RR_OPCODE     => instr_err <= '0';
                when IMM_OPCODE    => instr_err <= '0';
                when JALR_OPCODE   => instr_err <= '0';
                when LOAD_OPCODE   => instr_err <= '0';
                when STORE_OPCODE  => instr_err <= '0';
                when BRANCH_OPCODE => instr_err <= '0';
                when LUI_OPCODE    => instr_err <= '0';
                when AUIPC_OPCODE  => instr_err <= '0';
                when JAL_OPCODE    => instr_err <= '0';
                when SYSTEM_OPCODE => instr_err <= '0';
                when FENCE_OPCODE  => instr_err <= '0';
                when others        => instr_err <= '1';
            end case;
        end if;
    end process exception_ctrl;
            
end architecture main_ctrl_arch;