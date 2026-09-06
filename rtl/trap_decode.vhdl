----------------------------------------------------------------------
-- Leaf project
-- developed by: Daniel Santos
-- module: trap cause decode (ID time)
-- 2026
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.leaf_pkg.all;

entity trap_decode is
    port (
        clk_i         : in  std_logic;
        reset_i       : in  std_logic;

        sys_ctrl_i    : in  std_logic;
        funct12_i     : in  std_logic_vector(11 downto 0);
        id_valid_i    : in  std_logic;
        instr_err_i   : in  std_logic;
        imrd_fault_i  : in  std_logic;

        exi_taken_i   : in  std_logic;
        tmi_taken_i   : in  std_logic;
        swi_taken_i   : in  std_logic;

        ready_i       : in  std_logic;

        pipe_en_o     : out std_logic;
        int_taken_o   : out std_logic;

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

    signal fetch_fault : std_logic;

    -- The processor is in wait. sys_ctrl_i falls to the same squash as the rest
    -- of the decode, and a pending interrupt is part of that squash -- but the
    -- interrupt is also what releases a wfi, so in the release cycle the decode
    -- is already gone. This register carries the wait across that cycle: EX
    -- still has to learn it was a wfi, to stack pc+4 and to count the retire.
    signal parked     : std_logic;
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

    signal exc_cause_reg   : std_logic;
    signal retire_reg      : std_logic;
    signal instr_err_reg   : std_logic;
    signal fetch_fault_reg : std_logic;
    signal ebreak_reg      : std_logic;
    signal mret_reg        : std_logic;
    signal wfi_reg         : std_logic;

begin

    -- Only id_valid_i annuls the fetch error bit: a pending interrupt must not,
    -- or every fetch fault taken in its shadow would be silently dropped.
    fetch_fault  <= imrd_fault_i and id_valid_i;

    -- Each input arrives masked by mstatus.MIE in csrs, so nothing is left of
    -- the decision here but the OR.
    int_taken    <= exi_taken_i or tmi_taken_i or swi_taken_i;

    -- Equality comparators rather than a case over funct12: the four encodings
    -- are sparse and a case costs far more area here.
    wfi    <= '1' when sys_ctrl_i = '1' and funct12_i = x"105" else '0';
    ecall  <= '1' when sys_ctrl_i = '1' and funct12_i = x"000" else '0';
    ebreak <= '1' when sys_ctrl_i = '1' and funct12_i = x"001" else '0';
    mret   <= '1' when sys_ctrl_i = '1' and funct12_i = x"302" else '0';

    parked <= wfi or parked_reg;

    -- `and not exc_cause_reg` is a one-shot. int_taken is still high through the
    -- cycle csrs commits from exc_cause_reg; without it the trap commits twice,
    -- the second time with pc_reg advanced and int_taken already dropped,
    -- leaving a wrong mepc and an mcause without the interrupt bit. Covered by
    -- verif/tests/wfi_timer.
    exc_cause <= instr_err_i or fetch_fault or ecall or ebreak
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
    pipe_en   <= ready_i and (int_taken or not parked);

    retire    <= id_valid_i and ((not exc_cause) or parked);

    -- Its own process: pipeline_reg below only clocks under pipe_en, which a
    -- park holds at '0', so the wait would never be recorded there. id_valid_i
    -- releases it as well as int_taken -- a redirect can flush the slot the wfi
    -- sits in, and a flushed wfi must not keep the pipeline parked.
    park_reg: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_i = '1' then
                parked_reg <= '0';
            else
                parked_reg <= parked and id_valid_i and not int_taken;
            end if;
        end if;
    end process park_reg;

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
                wfi_reg         <= parked;
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
