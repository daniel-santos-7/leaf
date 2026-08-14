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

        -- ID time, from main_ctrl: the OR of the synchronous causes (fetch
        -- fault, ecall, ebreak, illegal instruction), each already qualified
        -- by the decode squash, and the wfi that parks the pipeline.
        id_exc_cause_i : in  std_logic;
        id_wfi_i       : in  std_logic;
        -- Evaluated in csrs, from mie/mip/mstatus and their write bypass.
        int_taken_i    : in  std_logic;
        valid_i        : in  std_logic;
        stale_i        : in  std_logic;
        flush_i        : in  std_logic;
        ready_i        : in  std_logic;

        -- ex_block hands the five EX faults over individually because csrs
        -- discriminates between them for mcause and mtval; everything built on
        -- top of them is consumed here, in one copy.
        imrd_malgn_i   : in  std_logic;
        dmld_malgn_i   : in  std_logic;
        dmld_fault_i   : in  std_logic;
        dmst_malgn_i   : in  std_logic;
        dmst_fault_i   : in  std_logic;

        mret_i         : in  std_logic;
        mepc_i         : in  std_logic_vector(XLEN-1 downto 2);
        mtvec_base_i   : in  std_logic_vector(XLEN-1 downto 2);

        regwr_en_i     : in  std_logic;
        csrwr_en_i     : in  std_logic;

        pipe_en_o      : out std_logic;
        exc_taken_o    : out std_logic;
        taken_o        : out std_logic;
        target_o       : out std_logic_vector(XLEN-1 downto 0);
        regwr_en_o     : out std_logic;
        csrwr_en_o     : out std_logic;
        retire_o       : out std_logic
    );
end entity trap_ctrl;

architecture rtl of trap_ctrl is

    signal exc_cause : std_logic;
    signal pipe_en   : std_logic;
    signal retire    : std_logic;

    signal exc_fault : std_logic;
    signal exc_taken : std_logic;

    -- The cause set is registered because csrs commits at EX time: a
    -- combinational twin would pair a cause with the following instruction.
    -- Both share main_ctrl's enable and reset, so they stay in step with the
    -- ID/EX register over there.
    signal exc_cause_reg : std_logic;
    signal retire_reg    : std_logic;

begin

    -- int_taken_i is the one cause the decode process does not qualify -- a
    -- real interrupt is independent of whichever instruction occupies the slot
    -- -- and so the one that needs the one-shot. csrs commits from
    -- exc_cause_reg a cycle after this line asserts, clearing mstatus.MIE with
    -- it, but int_taken_i is still high through that extra cycle: without `and
    -- not exc_cause_reg` the trap commits twice, the second time with pc_reg
    -- advanced and int_taken already dropped, leaving a wrong mepc and an
    -- mcause without the interrupt bit. Covered by verif/tests/wfi_timer.
    exc_cause <= id_exc_cause_i or (int_taken_i and not exc_cause_reg);

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
    pipe_en   <= ready_i and (int_taken_i or not id_wfi_i);

    -- valid_i='0' covers an empty instruction buffer (instr_i is then stale
    -- FIFO output), flush_i the cycle a taken branch resolves in EX, and
    -- stale_i the wrong-path entries still buffered after flush drops.
    retire    <= valid_i and not stale_i and not flush_i
                 and ((not exc_cause) or id_wfi_i);

    pipeline_reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                exc_cause_reg <= '0';
                retire_reg    <= '0';
            elsif pipe_en = '1' then
                exc_cause_reg <= exc_cause;
                retire_reg    <= retire;
            end if;
        end if;
    end process pipeline_reg;

    exc_fault <= imrd_malgn_i or dmld_malgn_i or dmld_fault_i or
                 dmst_malgn_i or dmst_fault_i;

    -- Both terms are EX-aligned: exc_cause_reg is the registered cause set,
    -- exc_fault the live EX fault. They commit in the same cycle.
    exc_taken <= exc_cause_reg or exc_fault;

    pipe_en_o   <= pipe_en;
    exc_taken_o <= exc_taken;

    -- An mret redirects the fetch too, but commits nothing in csrs beyond the
    -- mstatus unstacking, so it joins only here and not in exc_taken.
    taken_o     <= exc_taken or mret_i;
    -- Fully resolved trap redirect. csrs owns mepc and mtvec, so the 2:1 mux
    -- between them stays in ID instead of 60 bits of CSR content crossing
    -- into EX.
    target_o    <= mepc_i & b"00" when mret_i = '1' else
                   mtvec_base_i & b"00";

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
