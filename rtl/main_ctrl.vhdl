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
        imrd_malgn_i   : in  std_logic;
        imrd_fault_i   : in  std_logic;
        dmld_malgn_i   : in  std_logic;
        dmld_fault_i   : in  std_logic;
        dmst_malgn_i   : in  std_logic;
        dmst_fault_i   : in  std_logic;
        instr_i        : in  std_logic_vector(XLEN-1 downto 0);
        valid_i        : in  std_logic;
        branch_i       : in  std_logic;
        dmls_ready_i   : in  std_logic;
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
        mret_o         : out std_logic;
        wfi_o          : out std_logic;
        csrwr_en_o     : out std_logic;
        regwr_en_o     : out std_logic;
        regwr_sel_o    : out std_logic_vector(1  downto 0);
        dmls_mode_o    : out std_logic;
        dmls_en_o      : out std_logic;
        jmp_o          : out std_logic;
        br_en_o        : out std_logic;
        opd0_src_sel_o : out std_logic;
        opd1_src_sel_o : out std_logic;
        opd0_pass_o    : out std_logic;
        opd1_pass_o    : out std_logic;
        alu_op_o       : out std_logic_vector(5  downto 0);
        imm_o          : out std_logic_vector(XLEN-1 downto 0);
        func3_o        : out std_logic_vector(2  downto 0);
        regwr_addr_o   : out std_logic_vector(4  downto 0);
        regrd_addr0_o  : out std_logic_vector(4  downto 0);
        regrd_addr1_o  : out std_logic_vector(4  downto 0);
        csrs_addr_o    : out std_logic_vector(11 downto 0);
        exc_taken_o   : out std_logic;
        int_taken_o   : out std_logic;
        exi_taken_o   : out std_logic;
        tmi_taken_o   : out std_logic;
        swi_taken_o   : out std_logic;
        trap_taken_o   : out std_logic;
        trap_target_o  : out std_logic_vector(XLEN-1 downto 0);
        ready_o        : out std_logic
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

    function resize_signed(value: in std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(resize(signed(value), XLEN));
    end function resize_signed;

    type stage_state is (DECODE, FLUSH, LOAD, STORE, WAIT_FOR_INTERRUPT);
    signal state     : stage_state;
    signal ready_reg  : std_logic;

begin

    -- FSM --

    fsm: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                state     <= DECODE;
                ready_reg <= '1';
            else
                case state is
                    when DECODE =>
                        if valid_i = '1' then
                            if opcode = JAL_OPCODE or opcode = JALR_OPCODE or (opcode = BRANCH_OPCODE and branch_i = '1') then
                                state <= FLUSH;
                                ready_reg <= '1';
                            elsif opcode = LOAD_OPCODE then
                                if dmld_malgn_i = '1' then
                                    state <= FLUSH;
                                    ready_reg <= '1';
                                else
                                    state <= LOAD;
                                    ready_reg <= '0';
                                end if;
                            elsif opcode = STORE_OPCODE then
                                if dmst_malgn_i = '1' then
                                    state <= FLUSH;
                                    ready_reg <= '1';
                                else
                                    state <= STORE;
                                    ready_reg <= '0';
                                end if;
                            elsif ecall = '1' or ebreak = '1' or mret = '1' then
                                state <= FLUSH;
                                ready_reg <= '1';
                            elsif wfi = '1' then
                                state <= WAIT_FOR_INTERRUPT;
                                ready_reg <= '0';
                            end if;
                        end if;
                    when FLUSH =>
                        if valid_i = '1' then
                            state <= DECODE;
                            ready_reg <= '1';
                        end if;
                    when LOAD | STORE =>
                        if dmls_ready_i = '1' then
                            state <= DECODE;
                            ready_reg <= '1';
                        end if;
                    when WAIT_FOR_INTERRUPT =>
                        if exi_taken = '1' or tmi_taken = '1' or swi_taken = '1' then
                            state <= DECODE;
                            ready_reg <= '1';
                        end if;
                end case;
            end if;
        end if;
    end process fsm;

    opcode  <= instr_i(6  downto  0);
    payload <= instr_i(31 downto  7);

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

    -- system instruction decode

    ecall  <= '1' when opcode = SYSTEM_OPCODE and instr_i(14 downto 12) = b"000" and instr_i(31 downto 20) = x"000" else '0';
    ebreak <= '1' when opcode = SYSTEM_OPCODE and instr_i(14 downto 12) = b"000" and instr_i(31 downto 20) = x"001" else '0';
    mret   <= '1' when opcode = SYSTEM_OPCODE and instr_i(14 downto 12) = b"000" and instr_i(31 downto 20) = x"302" else '0';
    wfi    <= '1' when opcode = SYSTEM_OPCODE and instr_i(14 downto 12) = b"000" and instr_i(31 downto 20) = x"105" else '0';

    main_ctrl_proc: process(opcode, instr_i, state, valid_i, dmls_ready_i)
    begin
        case state is
            when FLUSH | WAIT_FOR_INTERRUPT =>
                dmls_mode_o    <= '0';
                dmls_en_o      <= '0';
                instr_err      <= '0';
                imm_type       <= (others => '-');
                jmp_o          <= '0';
                br_en_o        <= '0';
                opd0_src_sel_o <= '0';
                opd1_src_sel_o <= '0';
                opd0_pass_o    <= '0';
                opd1_pass_o    <= '0';
                ftype        <= '0';
                op_en        <= '0';
                regwr_sel_o    <= b"00";
                csrwr_en_o     <= '0';
                regwr_en   <= '0';

            when DECODE =>
                if valid_i = '0' then
                    dmls_mode_o    <= '0';
                    dmls_en_o      <= '0';
                    instr_err      <= '0';
                    imm_type       <= (others => '-');
                    jmp_o          <= '0';
                    br_en_o        <= '0';
                    opd0_src_sel_o <= '0';
                    opd1_src_sel_o <= '0';
                    opd0_pass_o    <= '0';
                    opd1_pass_o    <= '0';
                    ftype        <= '0';
                    op_en        <= '0';
                    regwr_sel_o    <= b"00";
                    csrwr_en_o     <= '0';
                    regwr_en   <= '0';
                else
                    case opcode is
                        when RR_OPCODE =>
                            dmls_mode_o    <= '0';
                            dmls_en_o      <= '0';
                            instr_err      <= '0';
                            imm_type       <= (others => '-');
                            jmp_o          <= '0';
                            br_en_o        <= '0';
                            opd0_src_sel_o <= '0';
                            opd1_src_sel_o <= '0';
                            opd0_pass_o    <= '1';
                            opd1_pass_o    <= '1';
                            ftype        <= '0';
                            op_en        <= '1';
                            regwr_sel_o    <= b"00";
                            csrwr_en_o     <= '0';
                            regwr_en   <= '1';
                        when IMM_OPCODE =>
                            dmls_mode_o    <= '0';
                            dmls_en_o      <= '0';
                            instr_err      <= '0';
                            imm_type       <= IMM_I_TYPE;
                            jmp_o          <= '0';
                            br_en_o        <= '0';
                            opd0_src_sel_o <= '0';
                            opd1_src_sel_o <= '1';
                            opd0_pass_o    <= '1';
                            opd1_pass_o    <= '1';
                            ftype        <= '1';
                            op_en        <= '1';
                            regwr_sel_o    <= b"00";
                            csrwr_en_o     <= '0';
                            regwr_en   <= '1';
                        when JALR_OPCODE =>
                            dmls_mode_o    <= '0';
                            dmls_en_o      <= '0';
                            instr_err      <= '0';
                            imm_type       <= IMM_I_TYPE;
                            jmp_o          <= '1';
                            br_en_o        <= '0';
                            opd0_src_sel_o <= '0';
                            opd1_src_sel_o <= '1';
                            opd0_pass_o    <= '1';
                            opd1_pass_o    <= '1';
                            ftype        <= '0';
                            op_en        <= '0';
                            regwr_sel_o    <= b"10";
                            csrwr_en_o     <= '0';
                            regwr_en   <= '1';
                        when LOAD_OPCODE =>
                            dmls_mode_o    <= '0';
                            dmls_en_o      <= '1';
                            instr_err      <= '0';
                            imm_type       <= IMM_I_TYPE;
                            jmp_o          <= '0';
                            br_en_o        <= '0';
                            opd0_src_sel_o <= '0';
                            opd1_src_sel_o <= '1';
                            opd0_pass_o    <= '1';
                            opd1_pass_o    <= '1';
                            ftype        <= '0';
                            op_en        <= '0';
                            regwr_sel_o    <= b"01";
                            csrwr_en_o     <= '0';
                            regwr_en   <= '0';
                        when STORE_OPCODE =>
                            dmls_mode_o    <= '1';
                            dmls_en_o      <= '1';
                            instr_err      <= '0';
                            imm_type       <= IMM_S_TYPE;
                            jmp_o          <= '0';
                            br_en_o        <= '0';
                            opd0_src_sel_o <= '0';
                            opd1_src_sel_o <= '1';
                            opd0_pass_o    <= '1';
                            opd1_pass_o    <= '1';
                            ftype        <= '0';
                            op_en        <= '0';
                            regwr_sel_o    <= b"00";
                            csrwr_en_o     <= '0';
                            regwr_en   <= '0';
                        when BRANCH_OPCODE =>
                            dmls_mode_o    <= '0';
                            dmls_en_o      <= '0';
                            instr_err      <= '0';
                            imm_type       <= IMM_B_TYPE;
                            jmp_o          <= '0';
                            br_en_o        <= '1';
                            opd0_src_sel_o <= '1';
                            opd1_src_sel_o <= '1';
                            opd0_pass_o    <= '1';
                            opd1_pass_o    <= '1';
                            ftype        <= '0';
                            op_en        <= '0';
                            regwr_sel_o    <= b"00";
                            csrwr_en_o     <= '0';
                            regwr_en   <= '0';
                        when LUI_OPCODE =>
                            dmls_mode_o    <= '0';
                            dmls_en_o      <= '0';
                            instr_err      <= '0';
                            imm_type       <= IMM_U_TYPE;
                            jmp_o          <= '0';
                            br_en_o        <= '0';
                            opd0_src_sel_o <= '0';
                            opd1_src_sel_o <= '1';
                            opd0_pass_o    <= '0';
                            opd1_pass_o    <= '1';
                            ftype        <= '0';
                            op_en        <= '0';
                            regwr_sel_o    <= b"00";
                            csrwr_en_o     <= '0';
                            regwr_en   <= '1';
                        when AUIPC_OPCODE =>
                            dmls_mode_o    <= '0';
                            dmls_en_o      <= '0';
                            instr_err      <= '0';
                            imm_type       <= IMM_U_TYPE;
                            jmp_o          <= '0';
                            br_en_o        <= '0';
                            opd0_src_sel_o <= '1';
                            opd1_src_sel_o <= '1';
                            opd0_pass_o    <= '1';
                            opd1_pass_o    <= '1';
                            ftype        <= '0';
                            op_en        <= '0';
                            regwr_sel_o    <= b"00";
                            csrwr_en_o     <= '0';
                            regwr_en   <= '1';
                        when JAL_OPCODE =>
                            dmls_mode_o    <= '0';
                            dmls_en_o      <= '0';
                            instr_err      <= '0';
                            imm_type       <= IMM_J_TYPE;
                            jmp_o          <= '1';
                            br_en_o        <= '0';
                            opd0_src_sel_o <= '1';
                            opd1_src_sel_o <= '1';
                            opd0_pass_o    <= '1';
                            opd1_pass_o    <= '1';
                            ftype        <= '0';
                            op_en        <= '0';
                            regwr_sel_o    <= b"10";
                            csrwr_en_o     <= '0';
                            regwr_en   <= '1';
                        when SYSTEM_OPCODE =>
                            dmls_mode_o    <= '0';
                            dmls_en_o      <= '0';
                            instr_err      <= '0';
                            imm_type       <= IMM_Z_TYPE;
                            jmp_o          <= '0';
                            br_en_o        <= '0';
                            opd0_src_sel_o <= '0';
                            opd1_src_sel_o <= '0';
                            opd0_pass_o    <= '0';
                            opd1_pass_o    <= '0';
                            ftype        <= '0';
                            op_en        <= '0';
                            if instr_i(14 downto 12) = b"000" then
                                regwr_sel_o <= b"00";
                                csrwr_en_o  <= '0';
                                regwr_en    <= '0';
                            else
                                regwr_sel_o <= b"11";
                                csrwr_en_o  <= '1';
                                regwr_en    <= '1';
                            end if;
                        when FENCE_OPCODE =>
                            dmls_mode_o    <= '0';
                            dmls_en_o      <= '0';
                            instr_err      <= '0';
                            imm_type       <= (others => '-');
                            jmp_o          <= '0';
                            br_en_o        <= '0';
                            opd0_src_sel_o <= '0';
                            opd1_src_sel_o <= '0';
                            opd0_pass_o    <= '0';
                            opd1_pass_o    <= '0';
                            ftype        <= '0';
                            op_en        <= '0';
                            regwr_sel_o    <= b"00";
                            csrwr_en_o     <= '0';
                            regwr_en   <= '0';
                        when others =>
                            dmls_mode_o    <= '0';
                            dmls_en_o      <= '0';
                            instr_err      <= '1';
                            imm_type       <= (others => '-');
                            jmp_o          <= '0';
                            br_en_o        <= '0';
                            opd0_src_sel_o <= '0';
                            opd1_src_sel_o <= '0';
                            opd0_pass_o    <= '0';
                            opd1_pass_o    <= '0';
                            ftype        <= '0';
                            op_en        <= '0';
                            regwr_sel_o    <= b"00";
                            csrwr_en_o     <= '0';
                            regwr_en   <= '0';
                    end case;
                end if;

            when LOAD =>
                dmls_mode_o    <= '0';
                dmls_en_o      <= '1';
                instr_err      <= '0';
                imm_type       <= (others => '-');
                jmp_o          <= '0';
                br_en_o        <= '0';
                opd0_src_sel_o <= '0';
                opd1_src_sel_o <= '0';
                opd0_pass_o    <= '0';
                opd1_pass_o    <= '0';
                ftype        <= '0';
                op_en        <= '0';
                regwr_sel_o    <= b"01";
                csrwr_en_o     <= '0';
                regwr_en   <= dmls_ready_i;
            when STORE =>
                dmls_mode_o    <= '1';
                dmls_en_o      <= '1';
                instr_err      <= '0';
                imm_type       <= (others => '-');
                jmp_o          <= '0';
                br_en_o        <= '0';
                opd0_src_sel_o <= '0';
                opd1_src_sel_o <= '0';
                opd0_pass_o    <= '0';
                opd1_pass_o    <= '0';
                ftype        <= '0';
                op_en        <= '0';
                regwr_sel_o    <= b"00";
                csrwr_en_o     <= '0';
                regwr_en   <= '0';
        end case;
    end process main_ctrl_proc;

    alu_op_ctrl: process(op_en, ftype, instr_i)
    begin
        if op_en = '0' then
            alu_op_o <= ALU_ADD;
        else
            case instr_i(14 downto 12) is
                when b"000" =>
                    if instr_i(31 downto 25) = b"0100000" and ftype = '0' then
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

    -- Outputs --
    func3_o       <= instr_i(14 downto 12);
    regwr_en_o    <= regwr_en and not (imrd_malgn_i or dmld_malgn_i or dmld_fault_i);
    regwr_addr_o  <= instr_i(11 downto  7);
    regrd_addr0_o <= instr_i(19 downto 15);
    regrd_addr1_o <= instr_i(24 downto 20);
    csrs_addr_o   <= instr_i(31 downto 20);

    -- Trap logic --
    exi_taken     <= mie_meie_i and mip_meip_i;
    tmi_taken     <= mie_mtie_i and mip_mtip_i;
    swi_taken     <= mie_msie_i and mip_msip_i;
    int_taken     <= (exi_taken or tmi_taken or swi_taken) and mstatus_mie_i;
    exc_taken     <= imrd_malgn_i or imrd_fault_i or instr_err or ebreak or
                     dmld_malgn_i or dmld_fault_i or dmst_malgn_i or dmst_fault_i or
                     ecall or int_taken;
    exc_taken_o   <= exc_taken;
    exi_taken_o   <= exi_taken;
    tmi_taken_o   <= tmi_taken;
    swi_taken_o   <= swi_taken;
    int_taken_o   <= int_taken;
    trap_taken_o  <= exc_taken or mret;
    trap_target_o <= mepc_i & b"00" when mret = '1' else mtvec_base_i & b"00";

    -- Output port assignments from internal signals --
    instr_err_o   <= instr_err;
    ecall_o       <= ecall;
    ebreak_o      <= ebreak;
    mret_o        <= mret;
    wfi_o         <= wfi;
    ready_o       <= ready_reg;

end architecture rtl;