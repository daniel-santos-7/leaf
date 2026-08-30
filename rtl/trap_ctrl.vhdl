----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: trap and interrupt control
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

entity trap_ctrl is
    port (
        clk_i          : in  std_logic;
        reset_i        : in  std_logic;

        -- main_ctrl decodes the opcode: sys_ctrl_i is SYSTEM with funct3 = 000,
        -- unqualified, and funct12_i says which of ecall/ebreak/mret/wfi it is.
        -- Only the qualification differs between them, and that belongs here.
        sys_ctrl_i     : in  std_logic;
        funct12_i      : in  std_logic_vector(11 downto 0);
        -- main_ctrl's decode qualifier: the ID slot holds a real instruction,
        -- i.e. it is not empty, wrong-path or flushed.
        id_valid_i     : in  std_logic;
        -- ID time, from main_ctrl: the cause it decodes, already qualified by
        -- the decode squash. Registered here with the rest of the cause set.
        instr_err_i    : in  std_logic;
        -- Evaluated in csrs, from mie/mip/mstatus and their write bypass.
        int_taken_i    : in  std_logic;
        imrd_fault_i   : in  std_logic;
        ready_i        : in  std_logic;

        -- ex_block hands the five EX faults over individually because the
        -- mcause encoding below discriminates between them; exc_fault ORs them
        -- back together for everything built on top of them.
        imrd_malgn_i   : in  std_logic;
        dmld_malgn_i   : in  std_logic;
        dmld_fault_i   : in  std_logic;
        dmst_malgn_i   : in  std_logic;
        dmst_fault_i   : in  std_logic;

        mepc_i         : in  std_logic_vector(XLEN-1 downto 2);
        mtvec_base_i   : in  std_logic_vector(XLEN-1 downto 2);

        regwr_en_i     : in  std_logic;
        csrwr_en_i     : in  std_logic;

        pipe_en_o      : out std_logic;
        exc_taken_o    : out std_logic;
        taken_o        : out std_logic;
        target_o       : out std_logic_vector(XLEN-1 downto 0);
        -- The exception code for mcause. Picking one cause out of the set is
        -- the same priority decision exc_taken already makes, over the same
        -- signals, so it is resolved here and csrs only registers the result.
        mcause_exc_o   : out std_logic_vector(4 downto 0);
        -- Registered, for csrs: it commits at EX time, so a combinational twin
        -- of either would pair a cause with the following instruction.
        mret_o         : out std_logic;
        wfi_o          : out std_logic;
        regwr_en_o     : out std_logic;
        csrwr_en_o     : out std_logic;
        retire_o       : out std_logic
    );
end entity trap_ctrl;

architecture rtl of trap_ctrl is

    -- sys_ctrl_i gated: gtd_sys_ctrl is a live control instruction, gtd_sys_trap
    -- one that also outranks whatever else wants the trap slot.
    signal gtd_sys_ctrl : std_logic;
    signal gtd_sys_trap : std_logic;

    -- imrd_fault_i qualified: with no live instruction in the ID slot the error
    -- bit out of the fetch FIFO belongs to a wrong-path fetch. Only id_valid_i
    -- annuls it -- a pending interrupt must not, or every fetch fault taken in
    -- its shadow would be silently dropped.
    signal fetch_fault : std_logic;

    signal ecall  : std_logic;
    signal ebreak : std_logic;
    signal mret   : std_logic;
    signal wfi    : std_logic;

    signal exc_cause : std_logic;
    signal pipe_en   : std_logic;
    signal retire    : std_logic;

    signal exc_fault  : std_logic;
    signal exc_taken  : std_logic;
    signal mcause_exc : std_logic_vector(4 downto 0);

    -- The cause set is registered because the trap commits at EX time: a
    -- combinational twin would pair a cause with the following instruction.
    -- pipe_en, driven here, is also main_ctrl's enable, so these stay in step
    -- with the ID/EX register over there.
    signal exc_cause_reg   : std_logic;
    signal retire_reg      : std_logic;
    signal instr_err_reg   : std_logic;
    signal fetch_fault_reg : std_logic;
    signal ecall_reg       : std_logic;
    signal ebreak_reg      : std_logic;
    signal mret_reg        : std_logic;
    signal wfi_reg         : std_logic;

begin

    fetch_fault  <= imrd_fault_i and id_valid_i;

    -- Only speculation annuls a wfi: it parks the pipeline and is released by
    -- int_taken_i, so it must survive a pending interrupt. ecall/ebreak/mret
    -- take the extra term because a faulted fetch delivers a garbage instruction
    -- -- the same reason main_ctrl suppresses instr_err -- and because a pending
    -- interrupt outranks both a synchronous trap and an mret redirect.
    gtd_sys_ctrl <= sys_ctrl_i and id_valid_i;
    gtd_sys_trap <= gtd_sys_ctrl and not (imrd_fault_i or int_taken_i);

    -- Equality comparators rather than a case over funct12: the four encodings
    -- are sparse and a case costs far more area here.
    wfi    <= '1' when gtd_sys_ctrl = '1' and funct12_i = x"105" else '0';
    ecall  <= '1' when gtd_sys_trap = '1' and funct12_i = x"000" else '0';
    ebreak <= '1' when gtd_sys_trap = '1' and funct12_i = x"001" else '0';
    mret   <= '1' when gtd_sys_trap = '1' and funct12_i = x"302" else '0';

    -- int_taken_i is the one cause the decode does not qualify -- a real
    -- interrupt is independent of whichever instruction occupies the slot --
    -- and so the one that needs the one-shot. csrs commits from exc_cause_reg a
    -- cycle after this line asserts, clearing mstatus.MIE with it, but
    -- int_taken_i is still high through that extra cycle: without `and not
    -- exc_cause_reg` the trap commits twice, the second time with pc_reg
    -- advanced and int_taken already dropped, leaving a wrong mepc and an
    -- mcause without the interrupt bit. Covered by verif/tests/wfi_timer.
    exc_cause <= instr_err_i or fetch_fault or ecall or ebreak
                 or (int_taken_i and not exc_cause_reg);

    -- A parked wfi must still wait on EX. The earlier form,
    -- `int_taken_i when wfi = '1' else ready_i`, dropped ready_i while parked,
    -- so an interrupt landing in the few cycles a load still occupies EX would
    -- advance the ID/EX register over it.
    --
    -- NOT COVERED: hitting that window needs the interrupt to fire inside those
    -- few cycles, and wfi_timer's park is thousands of cycles long -- tuning
    -- the delay to land there would pass for a reason no later change
    -- preserves. This form can only delay an advance, never allow one the old
    -- form refused, so it is safe to carry unverified.
    pipe_en   <= ready_i and (int_taken_i or not wfi);

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
                ecall_reg       <= '0';
                ebreak_reg      <= '0';
                mret_reg        <= '0';
                wfi_reg         <= '0';
                instr_err_reg   <= '0';
                fetch_fault_reg <= '0';
            elsif pipe_en = '1' then
                exc_cause_reg   <= exc_cause;
                retire_reg      <= retire;
                ecall_reg       <= ecall;
                ebreak_reg      <= ebreak;
                mret_reg        <= mret;
                wfi_reg         <= wfi;
                instr_err_reg   <= instr_err_i;
                fetch_fault_reg <= fetch_fault;
            end if;
        end if;
    end process pipeline_reg;

    exc_fault <= imrd_malgn_i or dmld_malgn_i or dmld_fault_i or
                 dmst_malgn_i or dmst_fault_i;

    -- The spec's exception priority, in order. Both halves are EX-aligned, so
    -- the registered ID causes and the live EX faults rank against each other
    -- directly. ecall_reg is the only case left once the eight above are ruled
    -- out, so it needs no guard and the chain stays a mux instead of an
    -- encoder. Reached only under exc_taken; csrs ignores it otherwise.
    mcause_exc <= b"00000" when imrd_malgn_i    = '1' else  -- instr addr misaligned
                  b"00001" when fetch_fault_reg = '1' else  -- instr access fault
                  b"00010" when instr_err_reg   = '1' else  -- illegal instruction
                  b"00011" when ebreak_reg      = '1' else  -- breakpoint
                  b"00100" when dmld_malgn_i    = '1' else  -- load addr misaligned
                  b"00101" when dmld_fault_i    = '1' else  -- load access fault
                  b"00110" when dmst_malgn_i    = '1' else  -- store addr misaligned
                  b"00111" when dmst_fault_i    = '1' else  -- store access fault
                  b"01011";                                 -- ecall

    -- Both terms are EX-aligned: exc_cause_reg is the registered cause set,
    -- exc_fault the live EX fault. They commit in the same cycle.
    exc_taken <= exc_cause_reg or exc_fault;

    pipe_en_o   <= pipe_en;
    exc_taken_o <= exc_taken;

    -- An mret redirects the fetch too, but commits nothing in csrs beyond the
    -- mstatus unstacking, so it joins only here and not in exc_taken. The
    -- registered copy is the one that redirects: it is EX-aligned, like
    -- exc_taken.
    taken_o     <= exc_taken or mret_reg;
    -- Fully resolved trap redirect. csrs owns mepc and mtvec, so the 2:1 mux
    -- between them stays in ID instead of 60 bits of CSR content crossing
    -- into EX.
    target_o    <= mepc_i & b"00" when mret_reg = '1' else
                   mtvec_base_i & b"00";

    mcause_exc_o  <= mcause_exc;
    mret_o        <= mret_reg;
    wfi_o         <= wfi_reg;

    -- EX-time faults only. A fetch fault is inhibited one stage earlier --
    -- main_ctrl's squash clears both enables on imrd_fault_i and the zero rides
    -- the ID/EX register -- so repeating that term live here would instead
    -- block the older instruction sitting in EX.
    regwr_en_o  <= regwr_en_i and not exc_fault;
    csrwr_en_o  <= csrwr_en_i and not exc_fault;

    -- The qualifier is pipe_en, not ready_i: the two are the same signal except
    -- while a wfi is parked, and there ready_i still reads '1' (EX is idle)
    -- while retire_reg keeps holding the bit of the instruction ahead of the
    -- wfi -- which would then be counted once per parked cycle. Covered by
    -- verif/tests/wfi_timer.
    retire_o    <= retire_reg and pipe_en and not exc_fault;

end architecture rtl;
