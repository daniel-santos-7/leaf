----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: trap cause decode (ID time)
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

-- The ID-time half of the trap unit: it names the control instruction in the
-- slot, qualifies it, and registers the resulting cause set for EX. trap_ctrl
-- ranks and commits those causes a stage later, over the EX faults. The split
-- is the pipeline boundary itself -- everything here is ID-aligned, everything
-- there EX-aligned -- so the register below is the entity boundary too.
entity trap_decode is
    port (
        clk_i         : in  std_logic;
        reset_i       : in  std_logic;

        -- main_ctrl decodes the opcode: sys_ctrl_i is SYSTEM with funct3 = 000,
        -- unqualified, and funct12_i says which of ecall/ebreak/mret/wfi it is.
        -- Only the qualification differs between them, and that belongs here.
        sys_ctrl_i    : in  std_logic;
        funct12_i     : in  std_logic_vector(11 downto 0);
        -- main_ctrl's decode qualifier: the ID slot holds a real instruction,
        -- i.e. it is not empty, wrong-path or flushed.
        id_valid_i    : in  std_logic;
        -- ID time, from main_ctrl: the cause it decodes, already qualified by
        -- the decode squash. Registered here with the rest of the cause set.
        instr_err_i   : in  std_logic;
        imrd_fault_i  : in  std_logic;

        -- The three armed interrupts, out of csrs: mie & mip per cause, masked
        -- there by mstatus.MIE and write-bypassed, since all three registers
        -- are owned over there. Reading them is a CSR job; what is left --
        -- ranking them and naming the cause -- is a trap one, and happens in
        -- trap_ctrl. Only the OR of the three is an ID-time decision, because a
        -- pending interrupt outranks whatever occupies the slot.
        exi_taken_i   : in  std_logic;
        tmi_taken_i   : in  std_logic;
        swi_taken_i   : in  std_logic;

        -- The one EX signal that reaches this side, and it has to: pipe_en_o
        -- below is the ID/EX advance, and an advance waits on EX.
        ready_i       : in  std_logic;

        pipe_en_o     : out std_logic;
        -- To main_ctrl, whose decode a pending interrupt squashes, to csrs for
        -- the interrupt bit of mcause, and to trap_ctrl, which ranks the three.
        int_taken_o   : out std_logic;

        -- The cause set, registered here and EX-aligned from here on: the trap
        -- commits at EX time, so a combinational twin would pair a cause with
        -- the following instruction. pipe_en_o, driven here, is also
        -- main_ctrl's enable, so these stay in step with the ID/EX register
        -- over there. instr_err_o is the registered copy of instr_err_i.
        instr_err_o   : out std_logic;
        fetch_fault_o : out std_logic;
        ebreak_o      : out std_logic;
        mret_o        : out std_logic;
        wfi_o         : out std_logic;
        exc_cause_o   : out std_logic;
        retire_o      : out std_logic
    );
end entity trap_decode;

architecture rtl of trap_decode is

    -- sys_ctrl_i gated: gtd_sys_ctrl is a live control instruction, gtd_sys_trap
    -- one that also outranks whatever else wants the trap slot.
    signal gtd_sys_ctrl : std_logic;
    signal gtd_sys_trap : std_logic;

    -- imrd_fault_i qualified: with no live instruction in the ID slot the error
    -- bit out of the fetch FIFO belongs to a wrong-path fetch. Only id_valid_i
    -- annuls it -- a pending interrupt must not, or every fetch fault taken in
    -- its shadow would be silently dropped.
    signal fetch_fault : std_logic;

    -- ecall has no registered twin: it is the else of both cause chains in
    -- trap_ctrl, reached once the eight above it are ruled out, so nothing over
    -- there reads it. It survives the boundary inside exc_cause.
    signal ecall  : std_logic;
    signal ebreak : std_logic;
    signal mret   : std_logic;
    signal wfi    : std_logic;

    signal int_taken : std_logic;
    signal exc_cause : std_logic;
    signal pipe_en   : std_logic;
    signal retire    : std_logic;

    signal exc_cause_reg   : std_logic;
    signal retire_reg      : std_logic;
    signal instr_err_reg   : std_logic;
    signal fetch_fault_reg : std_logic;
    signal ebreak_reg      : std_logic;
    signal mret_reg        : std_logic;
    signal wfi_reg         : std_logic;

begin

    fetch_fault  <= imrd_fault_i and id_valid_i;

    -- Each input arrives masked, so nothing is left of the decision but the OR.
    -- encode_mcause in trap_ctrl needs the three apart to name the cause;
    -- everything else needs only this.
    int_taken    <= exi_taken_i or tmi_taken_i or swi_taken_i;

    -- Only speculation annuls a wfi: it parks the pipeline and is released by
    -- int_taken, so it must survive a pending interrupt. ecall/ebreak/mret
    -- take the extra term because a faulted fetch delivers a garbage instruction
    -- -- the same reason main_ctrl suppresses instr_err -- and because a pending
    -- interrupt outranks both a synchronous trap and an mret redirect.
    gtd_sys_ctrl <= sys_ctrl_i and id_valid_i;
    gtd_sys_trap <= gtd_sys_ctrl and not (imrd_fault_i or int_taken);

    -- Equality comparators rather than a case over funct12: the four encodings
    -- are sparse and a case costs far more area here.
    wfi    <= '1' when gtd_sys_ctrl = '1' and funct12_i = x"105" else '0';
    ecall  <= '1' when gtd_sys_trap = '1' and funct12_i = x"000" else '0';
    ebreak <= '1' when gtd_sys_trap = '1' and funct12_i = x"001" else '0';
    mret   <= '1' when gtd_sys_trap = '1' and funct12_i = x"302" else '0';

    -- int_taken is the one cause the decode does not qualify -- a real
    -- interrupt is independent of whichever instruction occupies the slot --
    -- and so the one that needs the one-shot. csrs commits from exc_cause_reg a
    -- cycle after this line asserts, clearing mstatus.MIE with it, but
    -- int_taken is still high through that extra cycle: without `and not
    -- exc_cause_reg` the trap commits twice, the second time with pc_reg
    -- advanced and int_taken already dropped, leaving a wrong mepc and an
    -- mcause without the interrupt bit. Covered by verif/tests/wfi_timer.
    exc_cause <= instr_err_i or fetch_fault or ecall or ebreak
                 or (int_taken and not exc_cause_reg);

    -- A parked wfi must still wait on EX. The earlier form,
    -- `int_taken when wfi = '1' else ready_i`, dropped ready_i while parked,
    -- so an interrupt landing in the few cycles a load still occupies EX would
    -- advance the ID/EX register over it.
    --
    -- NOT COVERED: hitting that window needs the interrupt to fire inside those
    -- few cycles, and wfi_timer's park is thousands of cycles long -- tuning
    -- the delay to land there would pass for a reason no later change
    -- preserves. This form can only delay an advance, never allow one the old
    -- form refused, so it is safe to carry unverified.
    pipe_en   <= ready_i and (int_taken or not wfi);

    -- id_valid_i excludes an empty instruction buffer (the decode inputs are
    -- then stale FIFO output), the cycle a taken branch resolves in EX, and the
    -- wrong-path entries still buffered after flush drops.
    retire    <= id_valid_i and ((not exc_cause) or wfi);

    pipeline_reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                exc_cause_reg   <= '0';
                retire_reg      <= '0';
                ebreak_reg      <= '0';
                mret_reg        <= '0';
                wfi_reg         <= '0';
                instr_err_reg   <= '0';
                fetch_fault_reg <= '0';
            elsif pipe_en = '1' then
                exc_cause_reg   <= exc_cause;
                retire_reg      <= retire;
                ebreak_reg      <= ebreak;
                mret_reg        <= mret;
                wfi_reg         <= wfi;
                instr_err_reg   <= instr_err_i;
                fetch_fault_reg <= fetch_fault;
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

end architecture rtl;
