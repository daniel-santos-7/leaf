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
        clk_i          : in  std_logic;
        reset_i        : in  std_logic;
        imrd_fault_i   : in  std_logic;
        instr_i        : in  std_logic_vector(XLEN-1 downto 0);
        valid_i        : in  std_logic;
        stale_i        : in  std_logic;
        -- Evaluated in csrs, from mie/mip/mstatus and their write bypass.
        int_taken_i    : in  std_logic;
        instr_err_o    : out std_logic;
        ecall_o        : out std_logic;
        ebreak_o       : out std_logic;
        id_mret_o      : out std_logic;
        wfi_o          : out std_logic;
        ready_i        : in  std_logic;
        flush_i        : in  std_logic;
        ready_o        : out std_logic;
        id_exc_taken_o : out std_logic;
        -- registered (pipeline) outputs. id_exc_taken_o/id_mret_o above are the
        -- same-cycle combinational twins of exc_taken_o/mret_o below -- both
        -- genuinely needed (same-cycle CSR side effect vs. the redirect signal
        -- at commit); everything else here has no such twin, so it's named
        -- plainly.
        func3_o       : out std_logic_vector(2  downto 0);
        branch_op_o   : out std_logic_vector(1  downto 0);
        alu_op_o      : out std_logic_vector(5  downto 0);
        dmls_ctrl_o   : out std_logic_vector(1  downto 0);
        imm_o         : out std_logic_vector(XLEN-1 downto 0);
        opd_src_sel_o : out std_logic_vector(1  downto 0);
        opd_pass_o    : out std_logic_vector(1  downto 0);
        regwr_en_o    : out std_logic;
        regwr_sel_o   : out std_logic_vector(1 downto 0);
        regwr_addr_o  : out std_logic_vector(4 downto 0);
        csrwr_en_o    : out std_logic;
        retire_o      : out std_logic;
        csrs_addr_o   : out std_logic_vector(11 downto 0);
        exc_taken_o   : out std_logic;
        mret_o        : out std_logic
    );
end entity main_ctrl;

architecture rtl of main_ctrl is

    signal imm_type : std_logic_vector(2  downto 0);
    signal opcode   : std_logic_vector(6  downto 0);
    signal payload  : std_logic_vector(24 downto 0);

    signal ftype     : std_logic;
    signal op_en     : std_logic;
    signal regwr_en  : std_logic;

    signal exc_taken : std_logic;

    signal instr_err : std_logic;
    signal ecall     : std_logic;
    signal ebreak    : std_logic;
    signal mret      : std_logic;
    signal wfi       : std_logic;

    -- imrd_fault_i qualified by the decode process, so that every term of
    -- exc_taken below arrives pre-qualified except the interrupt.
    signal fetch_fault : std_logic;

    -- Combinational decode values, read by the pipeline register below.
    -- ready_int additionally shadows a same-cycle out port (ready_o) -- needed
    -- because VHDL-93 out ports cannot be read back inside the architecture;
    -- everything else here has no such port, it's just the ID-stage value.
    signal branch_op     : std_logic_vector(1  downto 0);
    signal alu_op        : std_logic_vector(5  downto 0);
    signal dmls_ctrl     : std_logic_vector(1  downto 0);
    signal imm           : std_logic_vector(XLEN-1 downto 0);
    -- One bit per operand: bit 0 drives opd0, bit 1 opd1 (see alu.vhdl).
    signal opd_src_sel   : std_logic_vector(1  downto 0);
    signal opd_pass      : std_logic_vector(1  downto 0);
    signal regwr_sel     : std_logic_vector(1  downto 0);
    signal csrwr_en      : std_logic;
    signal ready_int     : std_logic;
    signal retire        : std_logic;

    -- Pipeline register signals
    signal func3_reg        : std_logic_vector(2  downto 0);
    signal branch_op_reg    : std_logic_vector(1  downto 0);
    signal alu_op_reg       : std_logic_vector(5  downto 0);
    signal dmls_ctrl_reg    : std_logic_vector(1  downto 0);
    signal imm_reg          : std_logic_vector(XLEN-1 downto 0);
    signal opd_src_sel_reg  : std_logic_vector(1 downto 0);
    signal opd_pass_reg     : std_logic_vector(1 downto 0);
    signal regwr_en_reg     : std_logic;
    signal regwr_sel_reg    : std_logic_vector(1 downto 0);
    signal regwr_addr_reg   : std_logic_vector(4 downto 0);
    signal csrwr_en_reg     : std_logic;
    signal csrs_addr_reg    : std_logic_vector(11 downto 0);
    signal retire_reg       : std_logic;
    signal exc_taken_reg    : std_logic;
    signal mret_reg         : std_logic;

    function resize_signed(value: in std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(resize(signed(value), XLEN));
    end function resize_signed;

begin

    opcode  <= instr_i(6  downto  0);
    payload <= instr_i(31 downto  7);

    gen: process(imm_type, payload)
    begin
        case imm_type is
            when IMM_I_TYPE => imm <= resize_signed(payload(24 downto 13));
            when IMM_S_TYPE => imm <= resize_signed(payload(24 downto 18) & payload(4 downto 0));
            when IMM_B_TYPE => imm <= resize_signed(payload(24) & payload(0) & payload(23 downto 18) & payload(4 downto 1) & '0');
            when IMM_U_TYPE => imm <= payload(24 downto 5) & (XLEN-21 downto 0 => '0');
            when IMM_J_TYPE => imm <= resize_signed(payload(24) & payload(12 downto 5) & payload(13) & payload(23 downto 14) & '0');
            when IMM_Z_TYPE => imm <= std_logic_vector(resize(unsigned(payload(12 downto 8)), XLEN));
            when others     => imm <= (XLEN-1 downto 0 => '-');
        end case;
    end process gen;

    -- Decode process (opcode-based) --

    -- Decode runs unconditionally and the two overrides at the end squash it.
    -- Both conditions are built only from inputs, so this process never reads a
    -- signal it drives -- notably not instr_err, which is produced here and
    -- would close a loop. They differ on purpose: the wide one carries what a
    -- fetch fault or a pending interrupt also invalidates, the narrow one what
    -- only wrong-path speculation does.
    main_ctrl_proc: process(opcode, instr_i, valid_i, stale_i, flush_i, imrd_fault_i, int_taken_i)
    begin
        fetch_fault <= imrd_fault_i;

        case opcode is
            when RR_OPCODE =>
                dmls_ctrl    <= DMLS_IDLE;
                instr_err    <= '0';
                imm_type     <= (others => '-');
                branch_op    <= BR_NONE;
                opd_src_sel  <= b"00";
                opd_pass     <= b"11";
                ftype        <= '0';
                op_en        <= '1';
                regwr_sel    <= b"00";
                csrwr_en     <= '0';
                regwr_en     <= '1';
                ecall        <= '0';
                ebreak       <= '0';
                mret         <= '0';
                wfi          <= '0';
            when IMM_OPCODE =>
                dmls_ctrl    <= DMLS_IDLE;
                instr_err    <= '0';
                imm_type     <= IMM_I_TYPE;
                branch_op    <= BR_NONE;
                opd_src_sel  <= b"10";
                opd_pass     <= b"11";
                ftype        <= '1';
                op_en        <= '1';
                regwr_sel    <= b"00";
                csrwr_en     <= '0';
                regwr_en     <= '1';
                ecall        <= '0';
                ebreak       <= '0';
                mret         <= '0';
                wfi          <= '0';
            when JALR_OPCODE =>
                dmls_ctrl    <= DMLS_IDLE;
                instr_err    <= '0';
                imm_type     <= IMM_I_TYPE;
                branch_op    <= BR_JUMP;
                opd_src_sel  <= b"10";
                opd_pass     <= b"11";
                ftype        <= '0';
                op_en        <= '0';
                regwr_sel    <= b"10";
                csrwr_en     <= '0';
                regwr_en     <= '1';
                ecall        <= '0';
                ebreak       <= '0';
                mret         <= '0';
                wfi          <= '0';
            when LOAD_OPCODE =>
                dmls_ctrl    <= DMLS_LOAD;
                instr_err    <= '0';
                imm_type     <= IMM_I_TYPE;
                branch_op    <= BR_NONE;
                opd_src_sel  <= b"10";
                opd_pass     <= b"11";
                ftype        <= '0';
                op_en        <= '0';
                regwr_sel    <= b"01";
                csrwr_en     <= '0';
                regwr_en     <= '1';
                ecall        <= '0';
                ebreak       <= '0';
                mret         <= '0';
                wfi          <= '0';
            when STORE_OPCODE =>
                dmls_ctrl    <= DMLS_STORE;
                instr_err    <= '0';
                imm_type     <= IMM_S_TYPE;
                branch_op    <= BR_NONE;
                opd_src_sel  <= b"10";
                opd_pass     <= b"11";
                ftype        <= '0';
                op_en        <= '0';
                regwr_sel    <= b"00";
                csrwr_en     <= '0';
                regwr_en     <= '0';
                ecall        <= '0';
                ebreak       <= '0';
                mret         <= '0';
                wfi          <= '0';
            when BRANCH_OPCODE =>
                dmls_ctrl    <= DMLS_IDLE;
                instr_err    <= '0';
                imm_type     <= IMM_B_TYPE;
                branch_op    <= BR_BRANCH;
                opd_src_sel  <= b"11";
                opd_pass     <= b"11";
                ftype        <= '0';
                op_en        <= '0';
                regwr_sel    <= b"00";
                csrwr_en     <= '0';
                regwr_en     <= '0';
                ecall        <= '0';
                ebreak       <= '0';
                mret         <= '0';
                wfi          <= '0';
            when LUI_OPCODE =>
                dmls_ctrl    <= DMLS_IDLE;
                instr_err    <= '0';
                imm_type     <= IMM_U_TYPE;
                branch_op    <= BR_NONE;
                opd_src_sel  <= b"10";
                opd_pass     <= b"10";
                ftype        <= '0';
                op_en        <= '0';
                regwr_sel    <= b"00";
                csrwr_en     <= '0';
                regwr_en     <= '1';
                ecall        <= '0';
                ebreak       <= '0';
                mret         <= '0';
                wfi          <= '0';
            when AUIPC_OPCODE =>
                dmls_ctrl    <= DMLS_IDLE;
                instr_err    <= '0';
                imm_type     <= IMM_U_TYPE;
                branch_op    <= BR_NONE;
                opd_src_sel  <= b"11";
                opd_pass     <= b"11";
                ftype        <= '0';
                op_en        <= '0';
                regwr_sel    <= b"00";
                csrwr_en     <= '0';
                regwr_en     <= '1';
                ecall        <= '0';
                ebreak       <= '0';
                mret         <= '0';
                wfi          <= '0';
            when JAL_OPCODE =>
                dmls_ctrl    <= DMLS_IDLE;
                instr_err    <= '0';
                imm_type     <= IMM_J_TYPE;
                branch_op    <= BR_JUMP;
                opd_src_sel  <= b"11";
                opd_pass     <= b"11";
                ftype        <= '0';
                op_en        <= '0';
                regwr_sel    <= b"10";
                csrwr_en     <= '0';
                regwr_en     <= '1';
                ecall        <= '0';
                ebreak       <= '0';
                mret         <= '0';
                wfi          <= '0';
            when SYSTEM_OPCODE =>
                dmls_ctrl    <= DMLS_IDLE;
                instr_err    <= '0';
                imm_type     <= IMM_Z_TYPE;
                branch_op    <= BR_NONE;
                opd_src_sel  <= b"00";
                opd_pass     <= b"00";
                ftype        <= '0';
                op_en        <= '0';
                ecall        <= '0';
                ebreak       <= '0';
                mret         <= '0';
                wfi          <= '0';
                if instr_i(14 downto 12) = b"000" then
                    regwr_sel <= b"00";
                    csrwr_en  <= '0';
                    regwr_en  <= '0';
                    if instr_i(31 downto 20) = x"000" then ecall  <= '1'; end if;
                    if instr_i(31 downto 20) = x"001" then ebreak <= '1'; end if;
                    if instr_i(31 downto 20) = x"302" then mret   <= '1'; end if;
                    if instr_i(31 downto 20) = x"105" then wfi    <= '1'; end if;
                else
                    regwr_sel <= b"11";
                    csrwr_en  <= '1';
                    regwr_en  <= '1';
                end if;
            when FENCE_OPCODE =>
                dmls_ctrl    <= DMLS_IDLE;
                instr_err    <= '0';
                imm_type     <= (others => '-');
                branch_op    <= BR_NONE;
                opd_src_sel  <= b"00";
                opd_pass     <= b"00";
                ftype        <= '0';
                op_en        <= '0';
                regwr_sel    <= b"00";
                csrwr_en     <= '0';
                regwr_en     <= '0';
                ecall        <= '0';
                ebreak       <= '0';
                mret         <= '0';
                wfi          <= '0';
            when others =>
                dmls_ctrl    <= DMLS_IDLE;
                instr_err    <= '1';
                imm_type     <= (others => '-');
                branch_op    <= BR_NONE;
                opd_src_sel  <= b"00";
                opd_pass     <= b"00";
                ftype        <= '0';
                op_en        <= '0';
                regwr_sel    <= b"00";
                csrwr_en     <= '0';
                regwr_en     <= '0';
                ecall        <= '0';
                ebreak       <= '0';
                mret         <= '0';
                wfi          <= '0';
        end case;

        -- Only speculation anulls these two. wfi parks the pipeline and is
        -- released by int_taken_i, so it must survive a pending interrupt;
        -- fetch_fault is imrd_fault_i itself, so folding it into the wider
        -- condition below would pin it to '0' and silently drop every
        -- instruction fetch fault.
        if valid_i = '0' or stale_i = '1' or flush_i = '1' then
            wfi         <= '0';
            fetch_fault <= '0';
        end if;

        -- Squash: an empty slot (valid_i), a wrong-path instruction (stale_i,
        -- flush_i), a fetch fault or a pending interrupt must not let this
        -- instruction reach EX. ecall/ebreak/mret sit here rather than above
        -- because a faulted fetch delivers a garbage instr_i -- the same reason
        -- instr_err is suppressed -- and because a pending interrupt outranks
        -- both a synchronous trap and an mret redirect.
        if valid_i = '0' or stale_i = '1' or flush_i = '1'
           or imrd_fault_i = '1' or int_taken_i = '1' then
            dmls_ctrl    <= DMLS_IDLE;
            instr_err    <= '0';
            imm_type     <= (others => '-');
            branch_op    <= BR_NONE;
            opd_src_sel  <= b"00";
            opd_pass     <= b"00";
            ftype        <= '0';
            op_en        <= '0';
            regwr_sel    <= b"00";
            csrwr_en     <= '0';
            regwr_en     <= '0';
            ecall        <= '0';
            ebreak       <= '0';
            mret         <= '0';
        end if;
    end process main_ctrl_proc;

    alu_op_ctrl: process(op_en, ftype, instr_i)
    begin
        if op_en = '0' then
            alu_op <= ALU_ADD;
        else
            case instr_i(14 downto 12) is
                when b"000" =>
                    if instr_i(31 downto 25) = b"0100000" and ftype = '0' then
                        alu_op <= ALU_SUB;
                    else
                        alu_op <= ALU_ADD;
                    end if;
                when b"001" => alu_op <= ALU_SLL;
                when b"010" => alu_op <= ALU_SLT;
                when b"011" => alu_op <= ALU_SLTU;
                when b"100" => alu_op <= ALU_XOR;
                when b"101" =>
                    if instr_i(31 downto 25) = b"0100000" then
                        alu_op <= ALU_SRA;
                    else
                        alu_op <= ALU_SRL;
                    end if;
                when b"110" => alu_op <= ALU_OR;
                when b"111" => alu_op <= ALU_AND;
                when others => alu_op <= ALU_ADD;
            end case;
        end if;
    end process alu_op_ctrl;

    -- Every term here is already qualified by the decode process. int_taken_i is
    -- the exception, deliberately: a real interrupt is independent of whichever
    -- instruction happens to occupy the slot.
    exc_taken     <= fetch_fault or ecall or ebreak or int_taken_i or instr_err;

    ready_int    <= int_taken_i when wfi = '1' else ready_i;
    -- valid_i='0' covers an empty instruction buffer (instr_i is then stale
    -- FIFO output), flush_i the cycle a taken branch resolves in EX, and
    -- stale_i the wrong-path entries still buffered after flush drops.
    retire       <= valid_i and not stale_i and not flush_i
                    and ((not exc_taken) or wfi);

    -- Pipeline register (ID -> EX) --
    pipeline_reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                func3_reg        <= (others => '0');
                branch_op_reg    <= BR_NONE;
                alu_op_reg       <= (others => '0');
                dmls_ctrl_reg    <= DMLS_IDLE;
                imm_reg          <= (others => '0');
                opd_src_sel_reg  <= (others => '0');
                opd_pass_reg     <= (others => '0');
                regwr_en_reg     <= '0';
                regwr_sel_reg    <= (others => '0');
                regwr_addr_reg   <= (others => '0');
                csrwr_en_reg     <= '0';
                csrs_addr_reg    <= (others => '0');
                retire_reg       <= '0';
                exc_taken_reg    <= '0';
                mret_reg         <= '0';
            elsif ready_int = '1' then
                func3_reg        <= instr_i(14 downto 12);
                branch_op_reg    <= branch_op;
                alu_op_reg       <= alu_op;
                dmls_ctrl_reg    <= dmls_ctrl;
                imm_reg          <= imm;
                opd_src_sel_reg  <= opd_src_sel;
                opd_pass_reg     <= opd_pass;
                regwr_en_reg     <= regwr_en;
                regwr_sel_reg    <= regwr_sel;
                regwr_addr_reg   <= instr_i(11 downto  7);
                csrwr_en_reg     <= csrwr_en;
                csrs_addr_reg    <= instr_i(31 downto 20);
                retire_reg       <= retire;
                exc_taken_reg    <= exc_taken;
                mret_reg         <= mret;
            end if;
        end if;
    end process pipeline_reg;

    -- Output assignments --
    id_exc_taken_o <= exc_taken;

    instr_err_o   <= instr_err;
    ecall_o       <= ecall;
    ebreak_o      <= ebreak;
    id_mret_o     <= mret;
    wfi_o         <= wfi;
    ready_o       <= ready_int;

    -- Registered output port assignments
    func3_o       <= func3_reg;
    branch_op_o   <= branch_op_reg;
    alu_op_o      <= alu_op_reg;
    dmls_ctrl_o   <= dmls_ctrl_reg;
    imm_o         <= imm_reg;
    opd_src_sel_o <= opd_src_sel_reg;
    opd_pass_o    <= opd_pass_reg;
    regwr_en_o    <= regwr_en_reg;
    regwr_sel_o   <= regwr_sel_reg;
    regwr_addr_o  <= regwr_addr_reg;
    csrwr_en_o    <= csrwr_en_reg;
    retire_o      <= retire_reg;
    csrs_addr_o   <= csrs_addr_reg;
    exc_taken_o   <= exc_taken_reg;
    mret_o        <= mret_reg;

end architecture rtl;