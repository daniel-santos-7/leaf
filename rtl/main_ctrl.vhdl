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
        mip_meip_i     : in  std_logic;
        mip_msip_i     : in  std_logic;
        mip_mtip_i     : in  std_logic;
        mie_meie_i     : in  std_logic;
        mie_mtie_i     : in  std_logic;
        mie_msie_i     : in  std_logic;
        mstatus_mie_i  : in  std_logic;
        mepc_i         : in  std_logic_vector(XLEN-1 downto 2);
        mtvec_base_i   : in  std_logic_vector(XLEN-1 downto 2);
        instr_err_o    : out std_logic;
        ecall_o        : out std_logic;
        ebreak_o       : out std_logic;
        id_mret_o      : out std_logic;
        wfi_o          : out std_logic;
        regrd_addr0_o  : out std_logic_vector(4  downto 0);
        regrd_addr1_o  : out std_logic_vector(4  downto 0);
        id_csrs_addr_o : out std_logic_vector(11 downto 0);
        ready_i        : in  std_logic;
        flush_i        : in  std_logic;
        ready_o        : out std_logic;
        id_exc_taken_o : out std_logic;
        int_taken_o    : out std_logic;
        exi_taken_o    : out std_logic;
        tmi_taken_o    : out std_logic;
        swi_taken_o    : out std_logic;
        -- registered (pipeline) outputs. id_csrs_addr_o/id_exc_taken_o/
        -- id_mret_o above are the same-cycle combinational twins of
        -- csrs_addr_o/exc_taken_o/mret_o below -- both genuinely needed
        -- (csrs read address + same-cycle CSR side effect vs. the delayed
        -- write address / redirect signal at commit); everything else here
        -- has no such twin, so it's named plainly.
        func3_o       : out std_logic_vector(2  downto 0);
        branch_op_o   : out std_logic_vector(1  downto 0);
        alu_op_o      : out std_logic_vector(5  downto 0);
        dmls_ctrl_o   : out std_logic_vector(1  downto 0);
        imm_o         : out std_logic_vector(XLEN-1 downto 0);
        opd0_src_sel_o : out std_logic;
        opd1_src_sel_o : out std_logic;
        opd0_pass_o   : out std_logic;
        opd1_pass_o   : out std_logic;
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

    signal exi_taken : std_logic;
    signal tmi_taken : std_logic;
    signal swi_taken : std_logic;
    signal int_taken : std_logic;
    signal exc_taken : std_logic;

    signal instr_err : std_logic;
    signal ecall     : std_logic;
    signal ebreak    : std_logic;
    signal mret      : std_logic;
    signal wfi       : std_logic;
    signal trap_inhibit : std_logic;

    -- Empty slot or wrong-path instruction: nothing here may reach EX or stall
    -- the pipeline. Must not include trap_inhibit or mret -- trap_inhibit
    -- depends on ecall/ebreak, which are themselves qualified by kill, and
    -- including it would close a combinational loop.
    signal kill      : std_logic;
    signal wfi_eff   : std_logic;   -- wfi that is actually going to execute

    -- Combinational decode values, read by the pipeline register below.
    -- csrs_addr_int/ready_int/mret_out_int (further down) additionally
    -- shadow a same-cycle out port (csrs_addr_o/ready_o/mret_o) -- needed
    -- because VHDL-93 out ports cannot be read back inside the architecture;
    -- everything else here has no such port, it's just the ID-stage value.
    signal func3         : std_logic_vector(2  downto 0);
    signal branch_op     : std_logic_vector(1  downto 0);
    signal alu_op        : std_logic_vector(5  downto 0);
    signal dmls_ctrl     : std_logic_vector(1  downto 0);
    signal imm           : std_logic_vector(XLEN-1 downto 0);
    signal opd0_src_sel  : std_logic;
    signal opd1_src_sel  : std_logic;
    signal opd0_pass     : std_logic;
    signal opd1_pass     : std_logic;
    signal regwr_sel     : std_logic_vector(1  downto 0);
    signal csrwr_en      : std_logic;
    signal regwr_addr    : std_logic_vector(4  downto 0);
    signal csrs_addr_int : std_logic_vector(11 downto 0);
    signal ready_int     : std_logic;
    signal retire        : std_logic;
    signal mret_out_int  : std_logic;

    -- Pipeline register signals
    signal func3_reg        : std_logic_vector(2  downto 0);
    signal branch_op_reg    : std_logic_vector(1  downto 0);
    signal alu_op_reg       : std_logic_vector(5  downto 0);
    signal dmls_ctrl_reg    : std_logic_vector(1  downto 0);
    signal imm_reg          : std_logic_vector(XLEN-1 downto 0);
    signal opd0_src_sel_reg : std_logic;
    signal opd1_src_sel_reg : std_logic;
    signal opd0_pass_reg    : std_logic;
    signal opd1_pass_reg    : std_logic;
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

    main_ctrl_proc: process(opcode, instr_i, kill, mret, trap_inhibit)
    begin
        if kill = '1' or trap_inhibit = '1' or mret = '1' then
            dmls_ctrl    <= DMLS_IDLE;
            instr_err    <= '0';
            imm_type     <= (others => '-');
            branch_op    <= BR_NONE;
            opd0_src_sel <= '0';
            opd1_src_sel <= '0';
            opd0_pass    <= '0';
            opd1_pass    <= '0';
            ftype        <= '0';
            op_en        <= '0';
            regwr_sel    <= b"00";
            csrwr_en     <= '0';
            regwr_en     <= '0';
        else
            case opcode is
                when RR_OPCODE =>
                    dmls_ctrl    <= DMLS_IDLE;
                    instr_err    <= '0';
                    imm_type     <= (others => '-');
                    branch_op    <= BR_NONE;
                    opd0_src_sel <= '0';
                    opd1_src_sel <= '0';
                    opd0_pass    <= '1';
                    opd1_pass    <= '1';
                    ftype        <= '0';
                    op_en        <= '1';
                    regwr_sel    <= b"00";
                    csrwr_en     <= '0';
                    regwr_en     <= '1';
                when IMM_OPCODE =>
                    dmls_ctrl    <= DMLS_IDLE;
                    instr_err    <= '0';
                    imm_type     <= IMM_I_TYPE;
                    branch_op    <= BR_NONE;
                    opd0_src_sel <= '0';
                    opd1_src_sel <= '1';
                    opd0_pass    <= '1';
                    opd1_pass    <= '1';
                    ftype        <= '1';
                    op_en        <= '1';
                    regwr_sel    <= b"00";
                    csrwr_en     <= '0';
                    regwr_en     <= '1';
                when JALR_OPCODE =>
                    dmls_ctrl    <= DMLS_IDLE;
                    instr_err    <= '0';
                    imm_type     <= IMM_I_TYPE;
                    branch_op    <= BR_JUMP;
                    opd0_src_sel <= '0';
                    opd1_src_sel <= '1';
                    opd0_pass    <= '1';
                    opd1_pass    <= '1';
                    ftype        <= '0';
                    op_en        <= '0';
                    regwr_sel    <= b"10";
                    csrwr_en     <= '0';
                    regwr_en     <= '1';
                when LOAD_OPCODE =>
                    dmls_ctrl    <= DMLS_LOAD;
                    instr_err    <= '0';
                    imm_type     <= IMM_I_TYPE;
                    branch_op    <= BR_NONE;
                    opd0_src_sel <= '0';
                    opd1_src_sel <= '1';
                    opd0_pass    <= '1';
                    opd1_pass    <= '1';
                    ftype        <= '0';
                    op_en        <= '0';
                    regwr_sel    <= b"01";
                    csrwr_en     <= '0';
                    regwr_en     <= '1';
                when STORE_OPCODE =>
                    dmls_ctrl    <= DMLS_STORE;
                    instr_err    <= '0';
                    imm_type     <= IMM_S_TYPE;
                    branch_op    <= BR_NONE;
                    opd0_src_sel <= '0';
                    opd1_src_sel <= '1';
                    opd0_pass    <= '1';
                    opd1_pass    <= '1';
                    ftype        <= '0';
                    op_en        <= '0';
                    regwr_sel    <= b"00";
                    csrwr_en     <= '0';
                    regwr_en     <= '0';
                when BRANCH_OPCODE =>
                    dmls_ctrl    <= DMLS_IDLE;
                    instr_err    <= '0';
                    imm_type     <= IMM_B_TYPE;
                    branch_op    <= BR_BRANCH;
                    opd0_src_sel <= '1';
                    opd1_src_sel <= '1';
                    opd0_pass    <= '1';
                    opd1_pass    <= '1';
                    ftype        <= '0';
                    op_en        <= '0';
                    regwr_sel    <= b"00";
                    csrwr_en     <= '0';
                    regwr_en     <= '0';
                when LUI_OPCODE =>
                    dmls_ctrl    <= DMLS_IDLE;
                    instr_err    <= '0';
                    imm_type     <= IMM_U_TYPE;
                    branch_op    <= BR_NONE;
                    opd0_src_sel <= '0';
                    opd1_src_sel <= '1';
                    opd0_pass    <= '0';
                    opd1_pass    <= '1';
                    ftype        <= '0';
                    op_en        <= '0';
                    regwr_sel    <= b"00";
                    csrwr_en     <= '0';
                    regwr_en     <= '1';
                when AUIPC_OPCODE =>
                    dmls_ctrl    <= DMLS_IDLE;
                    instr_err    <= '0';
                    imm_type     <= IMM_U_TYPE;
                    branch_op    <= BR_NONE;
                    opd0_src_sel <= '1';
                    opd1_src_sel <= '1';
                    opd0_pass    <= '1';
                    opd1_pass    <= '1';
                    ftype        <= '0';
                    op_en        <= '0';
                    regwr_sel    <= b"00";
                    csrwr_en     <= '0';
                    regwr_en     <= '1';
                when JAL_OPCODE =>
                    dmls_ctrl    <= DMLS_IDLE;
                    instr_err    <= '0';
                    imm_type     <= IMM_J_TYPE;
                    branch_op    <= BR_JUMP;
                    opd0_src_sel <= '1';
                    opd1_src_sel <= '1';
                    opd0_pass    <= '1';
                    opd1_pass    <= '1';
                    ftype        <= '0';
                    op_en        <= '0';
                    regwr_sel    <= b"10";
                    csrwr_en     <= '0';
                    regwr_en     <= '1';
                when SYSTEM_OPCODE =>
                    dmls_ctrl    <= DMLS_IDLE;
                    instr_err    <= '0';
                    imm_type     <= IMM_Z_TYPE;
                    branch_op    <= BR_NONE;
                    opd0_src_sel <= '0';
                    opd1_src_sel <= '0';
                    opd0_pass    <= '0';
                    opd1_pass    <= '0';
                    ftype        <= '0';
                    op_en        <= '0';
                    if instr_i(14 downto 12) = b"000" then
                        regwr_sel <= b"00";
                        csrwr_en  <= '0';
                        regwr_en  <= '0';
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
                    opd0_src_sel <= '0';
                    opd1_src_sel <= '0';
                    opd0_pass    <= '0';
                    opd1_pass    <= '0';
                    ftype        <= '0';
                    op_en        <= '0';
                    regwr_sel    <= b"00";
                    csrwr_en     <= '0';
                    regwr_en     <= '0';
                when others =>
                    dmls_ctrl    <= DMLS_IDLE;
                    instr_err    <= '1';
                    imm_type     <= (others => '-');
                    branch_op    <= BR_NONE;
                    opd0_src_sel <= '0';
                    opd1_src_sel <= '0';
                    opd0_pass    <= '0';
                    opd1_pass    <= '0';
                    ftype        <= '0';
                    op_en        <= '0';
                    regwr_sel    <= b"00";
                    csrwr_en     <= '0';
                    regwr_en     <= '0';
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

    -- system instruction decode (feeds the trap logic below, has no
    -- dependency on the pipeline register, so it's fine ahead of it)
    ecall  <= '1' when opcode = SYSTEM_OPCODE and instr_i(14 downto 12) = b"000" and instr_i(31 downto 20) = x"000" else '0';
    ebreak <= '1' when opcode = SYSTEM_OPCODE and instr_i(14 downto 12) = b"000" and instr_i(31 downto 20) = x"001" else '0';
    mret   <= '1' when opcode = SYSTEM_OPCODE and instr_i(14 downto 12) = b"000" and instr_i(31 downto 20) = x"302" else '0';
    wfi    <= '1' when opcode = SYSTEM_OPCODE and instr_i(14 downto 12) = b"000" and instr_i(31 downto 20) = x"105" else '0';

    -- A speculatively fetched system instruction must not stall the pipeline or
    -- take a trap. valid_i='0' covers an empty instruction buffer (instr_i is
    -- then stale FIFO output), flush_i the cycle a taken branch resolves in EX,
    -- and stale_i the wrong-path entries still buffered after flush drops.
    kill <= (not valid_i) or stale_i or flush_i;

    wfi_eff <= wfi and not kill;

    -- Trap inhibit: gates control outputs when trap is taken (no instr_err to break loop)
    -- int_taken is deliberately not gated by kill: a real interrupt is independent
    -- of whichever instruction happens to occupy the slot.
    trap_inhibit <= (imrd_fault_i and not kill)
                 or ((ecall or ebreak) and valid_i and not kill)
                 or int_taken;
    exc_taken     <= trap_inhibit or instr_err;
    exi_taken     <= mie_meie_i and mip_meip_i;
    tmi_taken     <= mie_mtie_i and mip_mtip_i;
    swi_taken     <= mie_msie_i and mip_msip_i;
    int_taken     <= (exi_taken or tmi_taken or swi_taken) and mstatus_mie_i;

    mret_out_int <= mret and not kill;
    ready_int    <= int_taken when wfi_eff = '1' else ready_i;
    retire       <= (not kill) and ((not exc_taken) or wfi_eff);

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
                opd0_src_sel_reg <= '0';
                opd1_src_sel_reg <= '0';
                opd0_pass_reg    <= '0';
                opd1_pass_reg    <= '0';
                regwr_en_reg     <= '0';
                regwr_sel_reg    <= (others => '0');
                regwr_addr_reg   <= (others => '0');
                csrwr_en_reg     <= '0';
                csrs_addr_reg    <= (others => '0');
                retire_reg       <= '0';
                exc_taken_reg    <= '0';
                mret_reg         <= '0';
            elsif ready_int = '1' then
                func3_reg        <= func3;
                branch_op_reg    <= branch_op;
                alu_op_reg       <= alu_op;
                dmls_ctrl_reg    <= dmls_ctrl;
                imm_reg          <= imm;
                opd0_src_sel_reg <= opd0_src_sel;
                opd1_src_sel_reg <= opd1_src_sel;
                opd0_pass_reg    <= opd0_pass;
                opd1_pass_reg    <= opd1_pass;
                regwr_en_reg     <= regwr_en;
                regwr_sel_reg    <= regwr_sel;
                regwr_addr_reg   <= regwr_addr;
                csrwr_en_reg     <= csrwr_en;
                csrs_addr_reg    <= csrs_addr_int;
                retire_reg       <= retire;
                exc_taken_reg    <= exc_taken;
                mret_reg         <= mret_out_int;
            end if;
        end if;
    end process pipeline_reg;

    -- Output assignments --
    func3          <= instr_i(14 downto 12);
    regwr_addr     <= instr_i(11 downto  7);
    regrd_addr0_o  <= instr_i(19 downto 15);
    regrd_addr1_o  <= instr_i(24 downto 20);
    csrs_addr_int  <= instr_i(31 downto 20);
    id_csrs_addr_o <= csrs_addr_int;

    id_exc_taken_o <= exc_taken;
    exi_taken_o    <= exi_taken;
    tmi_taken_o    <= tmi_taken;
    swi_taken_o    <= swi_taken;
    int_taken_o    <= int_taken;

    instr_err_o   <= instr_err;
    ecall_o       <= ecall  and not kill;
    ebreak_o      <= ebreak and not kill;
    id_mret_o     <= mret_out_int;
    wfi_o         <= wfi_eff;
    ready_o       <= ready_int;

    -- Registered output port assignments
    func3_o       <= func3_reg;
    branch_op_o   <= branch_op_reg;
    alu_op_o      <= alu_op_reg;
    dmls_ctrl_o   <= dmls_ctrl_reg;
    imm_o         <= imm_reg;
    opd0_src_sel_o <= opd0_src_sel_reg;
    opd1_src_sel_o <= opd1_src_sel_reg;
    opd0_pass_o   <= opd0_pass_reg;
    opd1_pass_o   <= opd1_pass_reg;
    regwr_en_o    <= regwr_en_reg;
    regwr_sel_o   <= regwr_sel_reg;
    regwr_addr_o  <= regwr_addr_reg;
    csrwr_en_o    <= csrwr_en_reg;
    retire_o      <= retire_reg;
    csrs_addr_o   <= csrs_addr_reg;
    exc_taken_o   <= exc_taken_reg;
    mret_o        <= mret_reg;

end architecture rtl;