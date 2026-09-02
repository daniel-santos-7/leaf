----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: trap and interrupt control (EX time)
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

-- The EX-time half of the trap unit: it ranks the causes, names the one that
-- wins and hands csrs what the trap stacks. Everything read here is EX-aligned
-- -- the cause set arrives already registered from trap_decode, the faults come
-- live off br_detector and dmls_block next door -- so this entity holds no
-- register of its own and is purely combinational, which is why it sits in
-- ex_block with the rest of the post-pipeline-register logic.
entity trap_ctrl is
    port (
        -- The cause set decoded and registered in trap_decode, EX-aligned.
        instr_err_i    : in  std_logic;
        fetch_fault_i  : in  std_logic;
        ebreak_i       : in  std_logic;
        mret_i         : in  std_logic;
        wfi_i          : in  std_logic;
        exc_cause_i    : in  std_logic;
        retire_i       : in  std_logic;
        -- The ID/EX advance, also from trap_decode: retire_o below is qualified
        -- by it rather than by ready_i, see the comment there.
        pipe_en_i      : in  std_logic;

        -- The interrupts, out of csrs and already masked there by mstatus.MIE.
        -- Live rather than EX-aligned: an interrupt belongs to no instruction.
        -- encode_trap below ranks them individually, at the top of the same
        -- priority list as the exceptions, so no OR of the three is built here.
        exi_taken_i    : in  std_logic;
        tmi_taken_i    : in  std_logic;
        swi_taken_i    : in  std_logic;

        -- The five EX faults arrive individually because the mcause encoding
        -- below discriminates between them; exc_fault ORs them back together
        -- for everything built on top of them. They no longer leave ex_block:
        -- nothing outside reads them apart.
        imrd_malgn_i   : in  std_logic;
        dmld_malgn_i   : in  std_logic;
        dmld_fault_i   : in  std_logic;
        dmst_malgn_i   : in  std_logic;
        dmst_fault_i   : in  std_logic;

        -- What the trap stacks is picked out of these, per cause below.
        -- exec_res_i is the address that faulted, straight off the alu; pc_i is
        -- the EX-aligned PC out of csrs's pipeline register.
        exec_res_i     : in  std_logic_vector(XLEN-1 downto 0);
        pc_i           : in  std_logic_vector(XLEN-1 downto 0);
        -- pc_i + 4, out of the alu's incrementer: the two are aligned, so this
        -- is the word past the instruction in EX. Only a wfi stacks it.
        pc_next_i      : in  std_logic_vector(XLEN-1 downto 2);

        -- main_ctrl's write enables, already registered over there.
        regwr_en_i     : in  std_logic;
        csrwr_en_i     : in  std_logic;

        exc_taken_o    : out std_logic;
        taken_o        : out std_logic;
        -- What the trap stacks, all three fields. Picking one cause out of the
        -- set is the same priority decision exc_taken already makes, over the
        -- same signals, and the spec pairs an mtval and a PC with each cause --
        -- so all three are resolved here, by encode_trap and the mepc pick
        -- below, and csrs only registers the results.
        mcause_exc_o   : out std_logic_vector(4 downto 0);
        mtval_o        : out std_logic_vector(XLEN-1 downto 0);
        -- The PC this trap stacks. csrs registers it into mepc; the value it
        -- reads back out of that register is the mret target, resolved there.
        mepc_o         : out std_logic_vector(XLEN-1 downto 2);
        regwr_en_o     : out std_logic;
        csrwr_en_o     : out std_logic;
        retire_o       : out std_logic
    );
end entity trap_ctrl;

architecture rtl of trap_ctrl is

    signal exc_fault  : std_logic;
    signal exc_taken  : std_logic;
    signal mcause_exc : std_logic_vector(4 downto 0);
    signal mtval      : std_logic_vector(XLEN-1 downto 0);
    signal mepc       : std_logic_vector(XLEN-1 downto 2);

begin

    exc_fault <= imrd_malgn_i or dmld_malgn_i or dmld_fault_i or
                 dmst_malgn_i or dmst_fault_i;

    -- The spec's trap priority, in one chain: the three interrupts outrank
    -- every exception, then the eight faults rank among themselves. The
    -- registered ID causes and the live EX faults are both EX-aligned, so they
    -- compare directly. An ecall is the only case left once the eleven above it
    -- are ruled out, so it is the else and the chain stays a mux instead of an
    -- encoder -- which is why trap_decode registers no ecall. Reached only
    -- under exc_taken; csrs ignores it otherwise.
    --
    -- The spec pairs an mtval with each cause, so the two are named in the same
    -- branch: no cause can be added or reordered without its mtval coming
    -- along. The address that faulted, the PC, or nothing -- none of the three
    -- interrupts is attached to an address.
    encode_trap: process(swi_taken_i, tmi_taken_i, exi_taken_i, imrd_malgn_i,
                         fetch_fault_i, instr_err_i, ebreak_i, dmld_malgn_i,
                         dmld_fault_i, dmst_malgn_i, dmst_fault_i,
                         exec_res_i, pc_i)
    begin
        if swi_taken_i = '1' then       -- machine software interrupt
            mcause_exc <= b"00011";
            mtval      <= (others => '0');
        elsif tmi_taken_i = '1' then    -- machine timer interrupt
            mcause_exc <= b"00111";
            mtval      <= (others => '0');
        elsif exi_taken_i = '1' then    -- machine external interrupt
            mcause_exc <= b"01011";
            mtval      <= (others => '0');
        elsif imrd_malgn_i = '1' then   -- instruction address misaligned
            mcause_exc <= b"00000";
            mtval      <= exec_res_i;   -- the misaligned jump target
        elsif fetch_fault_i = '1' then  -- instruction access fault
            mcause_exc <= b"00001";
            mtval      <= pc_i;         -- the fetch that faulted
        elsif instr_err_i = '1' then    -- illegal instruction
            mcause_exc <= b"00010";
            mtval      <= (others => '0');
        elsif ebreak_i = '1' then       -- breakpoint
            mcause_exc <= b"00011";
            mtval      <= pc_i;         -- the breakpoint itself
        elsif dmld_malgn_i = '1' then   -- load address misaligned
            mcause_exc <= b"00100";
            mtval      <= exec_res_i;   -- the effective address, for all four
        elsif dmld_fault_i = '1' then   -- load access fault
            mcause_exc <= b"00101";
            mtval      <= exec_res_i;
        elsif dmst_malgn_i = '1' then   -- store address misaligned
            mcause_exc <= b"00110";
            mtval      <= exec_res_i;
        elsif dmst_fault_i = '1' then   -- store access fault
            mcause_exc <= b"00111";
            mtval      <= exec_res_i;
        else                            -- environment call
            mcause_exc <= b"01011";
            mtval      <= (others => '0');
        end if;
    end process encode_trap;

    -- The PC the trap stacks. All but one cause take pc_i, the PC of the
    -- instruction sitting in EX, which is the one they belong to. The exception
    -- is a wfi released by an interrupt: mepc has to point past it, so the
    -- handler's mret does not fall back in and sleep again. wfi_i is the
    -- registered copy out of trap_decode, EX-aligned like pc_i.
    mepc <= pc_next_i when wfi_i = '1' else
            pc_i(XLEN-1 downto 2);

    -- Both terms are EX-aligned: exc_cause_i is the registered cause set,
    -- exc_fault the live EX fault. They commit in the same cycle.
    exc_taken <= exc_cause_i or exc_fault;

    exc_taken_o <= exc_taken;

    -- An mret redirects the fetch too, but commits nothing in csrs beyond the
    -- mstatus unstacking, so it joins only here and not in exc_taken. The
    -- registered copy is the one that redirects: it is EX-aligned, like
    -- exc_taken. The target it pairs with is resolved in csrs, which owns both
    -- mepc and mtvec, and reaches br_detector as ex_block's trap_target_i.
    taken_o     <= exc_taken or mret_i;

    mcause_exc_o  <= mcause_exc;
    mtval_o       <= mtval;
    mepc_o        <= mepc;

    -- EX-time faults only. A fetch fault is inhibited one stage earlier --
    -- main_ctrl's squash clears both enables on imrd_fault_i and the zero rides
    -- the ID/EX register -- so repeating that term live here would instead
    -- block the older instruction sitting in EX.
    regwr_en_o  <= regwr_en_i and not exc_fault;
    csrwr_en_o  <= csrwr_en_i and not exc_fault;

    -- The qualifier is pipe_en, not ready_i: the two are the same signal except
    -- while a wfi is parked, and there ready_i still reads '1' (EX is idle)
    -- while retire_i keeps holding the bit of the instruction ahead of the
    -- wfi -- which would then be counted once per parked cycle. Covered by
    -- verif/tests/wfi_timer.
    retire_o    <= retire_i and pipe_en_i and not exc_fault;

end architecture rtl;
