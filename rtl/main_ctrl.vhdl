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
        -- The ID slot holds a real instruction: not empty, not wrong-path, not
        -- flushed. Built in id_stage, which owns all three terms.
        id_valid_i     : in  std_logic;
        -- The three interrupt causes, already masked by mstatus.MIE in csrs.
        -- Only the OR of them is an ID-time decision; trap_ctrl ranks the three
        -- apart in ex_block to name the cause.
        exi_taken_i    : in  std_logic;
        tmi_taken_i    : in  std_logic;
        swi_taken_i    : in  std_logic;
        -- The one EX signal read here: pipe_en_o below is the ID/EX advance,
        -- and an advance waits on EX.
        ready_i        : in  std_logic;

        pipe_en_o      : out std_logic;
        int_taken_o    : out std_logic;

        -- The cause set, registered here and EX-aligned from here on. trap_ctrl
        -- ranks it in ex_block against the faults raised there.
        instr_err_o    : out std_logic;
        fetch_fault_o  : out std_logic;
        ebreak_o       : out std_logic;
        mret_o         : out std_logic;
        wfi_o          : out std_logic;
        exc_cause_o    : out std_logic;
        retire_o       : out std_logic;

        -- Registered (pipeline) outputs.
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
        csrs_addr_o   : out std_logic_vector(11 downto 0)
    );
end entity main_ctrl;

architecture rtl of main_ctrl is

    signal imm_type : std_logic_vector(2  downto 0);
    signal opcode   : std_logic_vector(6  downto 0);
    signal payload  : std_logic_vector(24 downto 0);

    signal ftype     : std_logic;
    signal op_en     : std_logic;
    signal regwr_en  : std_logic;
    signal sys_ctrl  : std_logic;

    signal instr_err   : std_logic;
    signal fetch_fault : std_logic;

    -- The processor is in wait. sys_ctrl falls to the same squash as the rest
    -- of the decode, and a pending interrupt is part of that squash -- but the
    -- interrupt is also what releases a wfi, so in the release cycle the decode
    -- is already gone. This register carries the wait across that cycle: EX
    -- still has to learn it was a wfi, to stack pc+4 and to count the retire.
    signal parked_reg : std_logic;

    -- ecall has no registered twin: it is the else of the cause chain in
    -- trap_ctrl, so nothing over there reads it. It crosses the boundary
    -- inside exc_cause.
    signal ecall  : std_logic;
    signal ebreak : std_logic;
    signal mret   : std_logic;
    signal wfi    : std_logic;

    signal int_taken : std_logic;
    signal exc_cause : std_logic;
    signal pipe_en   : std_logic;
    signal retire    : std_logic;

    signal branch_op     : std_logic_vector(1  downto 0);
    signal alu_op        : std_logic_vector(5  downto 0);
    signal dmls_ctrl     : std_logic_vector(1  downto 0);
    signal imm           : std_logic_vector(XLEN-1 downto 0);
    -- One bit per operand: bit 0 drives opd0, bit 1 opd1 (see alu.vhdl).
    signal opd_src_sel   : std_logic_vector(1  downto 0);
    signal opd_pass      : std_logic_vector(1  downto 0);
    signal regwr_sel     : std_logic_vector(1  downto 0);
    signal csrwr_en      : std_logic;

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

    signal exc_cause_reg   : std_logic;
    signal retire_reg      : std_logic;
    signal instr_err_reg   : std_logic;
    signal fetch_fault_reg : std_logic;
    signal ebreak_reg      : std_logic;
    signal mret_reg        : std_logic;
    signal wfi_reg         : std_logic;

    function resize_signed(value: in std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(resize(signed(value), XLEN));
    end function resize_signed;

begin

    opcode   <= instr_i(6  downto  0);
    payload  <= instr_i(31 downto  7);

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

    -- The decode falls to an invalid slot, to a faulted fetch, which delivers a
    -- garbage instr_i, and to a pending interrupt, which outranks the
    -- instruction occupying the slot. sys_ctrl falls with it: the wfi it also
    -- covers must outlive a pending interrupt, and the park register below is
    -- what carries it across.
    main_ctrl_proc: process(opcode, instr_i, id_valid_i, imrd_fault_i, int_taken)
    begin
        if id_valid_i = '0' or imrd_fault_i = '1' or int_taken = '1' then
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
            sys_ctrl     <= '0';
        else
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
                    sys_ctrl     <= '0';
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
                    sys_ctrl     <= '0';
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
                    sys_ctrl     <= '0';
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
                    sys_ctrl     <= '0';
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
                    sys_ctrl     <= '0';
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
                    sys_ctrl     <= '0';
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
                    sys_ctrl     <= '0';
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
                    sys_ctrl     <= '0';
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
                    sys_ctrl     <= '0';
                when SYSTEM_OPCODE =>
                    dmls_ctrl    <= DMLS_IDLE;
                    instr_err    <= '0';
                    imm_type     <= IMM_Z_TYPE;
                    branch_op    <= BR_NONE;
                    opd_src_sel  <= b"00";
                    opd_pass     <= b"00";
                    ftype        <= '0';
                    op_en        <= '0';
                    -- funct3 = 000 is ecall/ebreak/mret/wfi: here it only means the
                    -- instruction writes nothing back, trap_ctrl is what acts on
                    -- them.
                    if instr_i(14 downto 12) = b"000" then
                        regwr_sel <= b"00";
                        csrwr_en  <= '0';
                        regwr_en  <= '0';
                        sys_ctrl  <= '1';
                    else
                        regwr_sel <= b"11";
                        csrwr_en  <= '1';
                        regwr_en  <= '1';
                        sys_ctrl  <= '0';
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
                    sys_ctrl     <= '0';
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
                    sys_ctrl     <= '0';
            end case;
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

    -- Only id_valid_i annuls the fetch error bit: a pending interrupt must not,
    -- or every fetch fault taken in its shadow would be silently dropped.
    fetch_fault  <= imrd_fault_i and id_valid_i;

    -- Each input arrives masked by mstatus.MIE in csrs, so nothing is left of
    -- the decision here but the OR.
    int_taken    <= exi_taken_i or tmi_taken_i or swi_taken_i;

    -- Equality comparators rather than a case over funct12: the four encodings
    -- are sparse and a case costs far more area here.
    wfi    <= '1' when sys_ctrl = '1' and instr_i(31 downto 20) = x"105" else '0';
    ecall  <= '1' when sys_ctrl = '1' and instr_i(31 downto 20) = x"000" else '0';
    ebreak <= '1' when sys_ctrl = '1' and instr_i(31 downto 20) = x"001" else '0';
    mret   <= '1' when sys_ctrl = '1' and instr_i(31 downto 20) = x"302" else '0';

    -- `and not exc_cause_reg` is a one-shot. int_taken is still high through the
    -- cycle csrs commits from exc_cause_reg; without it the trap commits twice,
    -- the second time with pc_reg advanced and int_taken already dropped,
    -- leaving a wrong mepc and an mcause without the interrupt bit. Covered by
    -- verif/tests/wfi_timer.
    exc_cause <= instr_err or fetch_fault or ecall or ebreak
                 or (int_taken and not exc_cause_reg);

    -- A parked wfi must still wait on EX. The earlier form,
    -- `int_taken when wfi = '1' else ready_i`, dropped ready_i while parked, so
    -- an interrupt landing in the few cycles a load still occupies EX would
    -- advance the ID/EX register over it.
    --
    -- NOT COVERED: hitting that window needs the interrupt to fire inside those
    -- few cycles, and wfi_timer's park is thousands of cycles long. This form
    -- can only delay an advance, never allow one the old form refused, so it is
    -- safe to carry unverified.
    pipe_en   <= ready_i and not parked_reg;

    retire    <= id_valid_i and ((not exc_cause) or parked_reg);

    -- Its own process: pipeline_reg below only clocks under pipe_en, which a
    -- park holds at '0', so the wait would never be recorded there. The set
    -- condition is the decoded wfi, not wfi_reg: wfi_reg is written under
    -- pipe_en, and pipe_en is '0' for every cycle wfi is '1'.
    park_reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                parked_reg <= '0';
            elsif parked_reg = '1' then
                if int_taken = '1' then
                    parked_reg <= '0';
                end if;
            elsif wfi_reg = '1' then
                parked_reg <= '1';
            end if;
        end if;
    end process park_reg;

    pipeline_reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                exc_cause_reg    <= '0';
                retire_reg       <= '0';
                instr_err_reg    <= '0';
                fetch_fault_reg  <= '0';
                ebreak_reg       <= '0';
                mret_reg         <= '0';
                wfi_reg          <= '0';
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
            elsif pipe_en = '1' then
                exc_cause_reg    <= exc_cause;
                retire_reg       <= retire;
                instr_err_reg    <= instr_err;
                fetch_fault_reg  <= fetch_fault;
                ebreak_reg       <= ebreak;
                mret_reg         <= mret;
                wfi_reg          <= wfi;
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
            end if;
        end if;
    end process pipeline_reg;

    pipe_en_o     <= pipe_en;
    int_taken_o   <= int_taken;

    instr_err_o   <= instr_err_reg;
    fetch_fault_o <= fetch_fault_reg;
    ebreak_o      <= ebreak_reg;
    mret_o        <= mret_reg;
    wfi_o         <= wfi_reg;
    exc_cause_o   <= exc_cause_reg;
    retire_o      <= retire_reg;

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
    csrs_addr_o   <= csrs_addr_reg;

end architecture rtl;