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
        flush_i        : in  std_logic;
        -- The interrupt state, read out of csrs: one enable and one pending
        -- bit per cause, plus the global enable. The interrupt is the last of
        -- the ID-time causes, so it is named and armed here beside the others.
        mie_meie_i     : in  std_logic;
        mie_mtie_i     : in  std_logic;
        mie_msie_i     : in  std_logic;
        mip_meip_i     : in  std_logic;
        mip_mtip_i     : in  std_logic;
        mip_msip_i     : in  std_logic;
        mstatus_mie_i  : in  std_logic;
        exc_taken_i    : in  std_logic;
        ready_i        : in  std_logic;

        pipe_en_o      : out std_logic;

        -- The cause set, registered here onto ID/EX. Nothing is pre-ORed:
        -- trap_ctrl ranks these three and ORs them for mcause's interrupt bit.
        instr_err_o    : out std_logic;
        fetch_fault_o  : out std_logic;
        ecall_o        : out std_logic;
        ebreak_o       : out std_logic;
        mret_o         : out std_logic;
        wfi_o          : out std_logic;
        exi_trap_o     : out std_logic;
        tmi_trap_o     : out std_logic;
        swi_trap_o     : out std_logic;
        retire_o       : out std_logic;

        -- Registered (pipeline) outputs.
        func3_o        : out std_logic_vector(2  downto 0);
        branch_op_o    : out std_logic_vector(1  downto 0);
        alu_op_o       : out std_logic_vector(5  downto 0);
        dmls_ctrl_o    : out std_logic_vector(1  downto 0);
        imm_o          : out std_logic_vector(XLEN-1 downto 0);
        opd_src_sel_o  : out std_logic_vector(1  downto 0);
        opd_pass_o     : out std_logic_vector(1  downto 0);
        regwr_en_o     : out std_logic;
        regwr_sel_o    : out std_logic_vector(1 downto 0);
        regwr_addr_o   : out std_logic_vector(4 downto 0);
        csrwr_en_o     : out std_logic;
        csrs_addr_o    : out std_logic_vector(11 downto 0)
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

    signal id_valid    : std_logic;
    signal instr_err   : std_logic;
    signal fetch_fault : std_logic;

    signal exi_pend    : std_logic;
    signal tmi_pend    : std_logic;
    signal swi_pend    : std_logic;
    signal int_pend    : std_logic;
    signal int_taken   : std_logic;
    signal exi_trap    : std_logic;
    signal tmi_trap    : std_logic;
    signal swi_trap    : std_logic;

    -- The interrupt that releases a wfi also squashes its decode, so the wfi is
    -- gone by then. This carries it to EX, which stacks pc+4 and counts it.
    signal parked_reg : std_logic;

    signal ecall  : std_logic;
    signal ebreak : std_logic;
    signal mret   : std_logic;
    signal wfi    : std_logic;

    signal pipe_en   : std_logic;

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

    signal retire_reg      : std_logic;
    signal instr_err_reg   : std_logic;
    signal fetch_fault_reg : std_logic;
    signal ecall_reg       : std_logic;
    signal ebreak_reg      : std_logic;
    signal mret_reg        : std_logic;
    signal wfi_reg         : std_logic;
    signal exi_trap_reg    : std_logic;
    signal tmi_trap_reg    : std_logic;
    signal swi_trap_reg    : std_logic;

    function resize_signed(value: in std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(resize(signed(value), XLEN));
    end function resize_signed;

begin

    opcode   <= instr_i(6  downto  0);
    payload  <= instr_i(31 downto  7);

    id_valid <= valid_i and not stale_i and not flush_i;

    -- One pending line per cause, carrying its own mie bit and nothing else:
    -- mstatus.MIE is added to int_taken and to the arms below, and never to
    -- int_pend -- the wfi wake reads that one and must ignore the global
    -- enable, per the spec. Covered by verif/tests/wfi_mie0.
    exi_pend  <= mie_meie_i and mip_meip_i;
    tmi_pend  <= mie_mtie_i and mip_mtip_i;
    swi_pend  <= mie_msie_i and mip_msip_i;
    int_pend  <= exi_pend or tmi_pend or swi_pend;

    int_taken <= int_pend and mstatus_mie_i;

    -- The armed trap, one cause per line, guarded three times: the global
    -- enable the pending lines leave out, plus the two below.
    --
    -- The one-shot: mstatus.MIE only clears at the edge exc_taken_i commits the
    -- trap, so the causes above are still up through that cycle and the trap
    -- would commit twice. id_valid covers this on its own today -- flush_i is
    -- already subtracted from it -- so exc_taken_i here is redundant, kept as
    -- the local guard rather than a dependency on how far flush_i happens to
    -- reach. Covered by verif/tests/wfi_timer.
    --
    -- id_valid pins the trap to a real instruction. The pc registered beside
    -- these tracks the ID slot whether or not it decoded, so arming on a stale
    -- or flushed slot stacks a wrong-path pc: an interrupt landing in an mret's
    -- shadow took the handler's own address as its mepc and the mret then
    -- returned into itself. Covered by verif/tests/int_mret_shadow.
    exi_trap  <= exi_pend and mstatus_mie_i and not exc_taken_i and id_valid;
    tmi_trap  <= tmi_pend and mstatus_mie_i and not exc_taken_i and id_valid;
    swi_trap  <= swi_pend and mstatus_mie_i and not exc_taken_i and id_valid;

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

    -- The decode falls to an invalid slot, a faulted fetch (garbage instr_i) or
    -- a pending interrupt; parked_reg carries a wfi across the last of those.
    main_ctrl_proc: process(opcode, instr_i, id_valid, imrd_fault_i, int_taken)
    begin
        if id_valid = '0' or imrd_fault_i = '1' or int_taken = '1' then
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
                    -- funct3 = 000 is ecall/ebreak/mret/wfi: writes nothing back.
                    if instr_i(14 downto 12) = b"000" then
                        regwr_sel <= b"00";
                        csrwr_en  <= '0';
                        regwr_en  <= '0';
                        sys_ctrl  <= '1';
                    else
                        regwr_sel <= b"11";
                        -- csrrs/csrrc, and their immediate forms, must not
                        -- write when rs1/uimm is zero. The write would be a
                        -- no-op on the value, but it hits the read bypass in
                        -- csrs and freezes the next read of a live counter.
                        -- funct3(1 downto 0) = "01" is the csrrw pair, which
                        -- always writes.
                        if instr_i(13 downto 12) = b"01" or
                           instr_i(19 downto 15) /= b"00000" then
                            csrwr_en <= '1';
                        else
                            csrwr_en <= '0';
                        end if;
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

    -- Only id_valid annuls the fetch error bit: a pending interrupt must not,
    -- or every fetch fault taken in its shadow would be silently dropped.
    fetch_fault  <= imrd_fault_i and id_valid;

    -- Equality comparators, not a case over funct12: four sparse encodings.
    wfi    <= '1' when sys_ctrl = '1' and instr_i(31 downto 20) = x"105" else '0';
    ecall  <= '1' when sys_ctrl = '1' and instr_i(31 downto 20) = x"000" else '0';
    ebreak <= '1' when sys_ctrl = '1' and instr_i(31 downto 20) = x"001" else '0';
    mret   <= '1' when sys_ctrl = '1' and instr_i(31 downto 20) = x"302" else '0';

    -- ready_i must survive the park: dropping it there would advance the ID/EX
    -- register over an instruction still occupying EX.
    --
    -- NOT COVERED: the interrupt has to fire inside those few cycles, and
    -- wfi_timer's park is thousands of cycles long.
    pipe_en   <= ready_i and not parked_reg;

    -- Its own process: pipeline_reg clocks under pipe_en, which a park holds at
    -- '0'. Same reason the set condition is the decoded wfi, not wfi_reg.
    --
    -- The wake is int_pend, not int_taken: with the global enable in the way
    -- the hart parked forever.
    park_reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                parked_reg <= '0';
            elsif parked_reg = '1' then
                if int_pend = '1' then
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
                retire_reg       <= '0';
                instr_err_reg    <= '0';
                fetch_fault_reg  <= '0';
                ecall_reg        <= '0';
                ebreak_reg       <= '0';
                mret_reg         <= '0';
                wfi_reg          <= '0';
                exi_trap_reg     <= '0';
                tmi_trap_reg     <= '0';
                swi_trap_reg     <= '0';
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
                retire_reg       <= id_valid;
                instr_err_reg    <= instr_err;
                fetch_fault_reg  <= fetch_fault;
                ecall_reg        <= ecall;
                ebreak_reg       <= ebreak;
                mret_reg         <= mret;
                wfi_reg          <= wfi;
                exi_trap_reg     <= exi_trap;
                tmi_trap_reg     <= tmi_trap;
                swi_trap_reg     <= swi_trap;
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

    instr_err_o   <= instr_err_reg;
    fetch_fault_o <= fetch_fault_reg;
    ecall_o       <= ecall_reg;
    ebreak_o      <= ebreak_reg;
    mret_o        <= mret_reg;
    wfi_o         <= wfi_reg;
    exi_trap_o    <= exi_trap_reg;
    tmi_trap_o    <= tmi_trap_reg;
    swi_trap_o    <= swi_trap_reg;
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