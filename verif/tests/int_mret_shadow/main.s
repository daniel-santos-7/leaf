.include "defs.inc"

# An interrupt must not arm on an instruction the pipeline squashed.
#
# csrs registers pc_reg for whatever sits in the ID slot, decoded or not, so
# arming the trap from the live int_taken alone lets a stale or flushed slot
# supply the mepc. The nop count below lands the timer interrupt in the shadow
# of the ecall handler's mret: the wrong-path fetch past that mret was taken as
# the interrupted instruction, mepc came out pointing inside the handler, and
# the handler's own mret returned into itself forever -- the simulation never
# reached the halt word.
#
# What this test does NOT cover: csrs also stopped taking mcause.INT from the
# live int_taken. That half is unobservable here -- live cause bit with live
# cause code is self-consistent, exactly as the registered pair is -- and it
# survives the whole suite if reverted. It is there for an interrupt going
# pending during an ecall's own commit cycle, which would otherwise flip that
# ecall's mcause to an interrupt code (the two collide at 3, 7 and 11).
#
# The two constants are hand-tuned to this pipeline: TIMER_DELAY sets the
# arrival and SHADOW_NOPS slides the ecall into it. Change the fetch latency,
# the FIFO depth or the branch penalty and the arrival slides out of the
# shadow. The handler entry count in the dump is what makes that visible --
# a mistimed run that never takes both traps reports something other than 2
# rather than passing vacuously.
#
# Only the ecall's own mcause and the two counts reach the dump. Spike has no
# pipeline and orders the two traps differently, but the ecall is an ecall in
# both and both take exactly one of each.
#
#   begin_dump+0 : 0x600D600D pass / 0xBAD0BAD0 fail
#   begin_dump+4 : the ecall trap's mcause (0x0000000B)
#   begin_dump+8 : handler entries (2: one timer, one ecall)

.equ CLINT_MTIMECMP, 0x02004000
.equ CLINT_MTIME,    0x0200BFF8

.equ TIMER_DELAY, 8             # rtc ticks; places the arrival at the mret
.equ SHADOW_NOPS, 22            # slides the ecall into the arrival cycle

.equ MCAUSE_ECALL, 0x0000000B
.equ MCAUSE_TMI,   0x80000007

.equ PASS_PATTERN, 0x600D600D
.equ FAIL_PATTERN, 0xBAD0BAD0

.globl _start
_start:
    la   t0, handler
    csrw mtvec, t0

    li   s0, 0                  # the ecall trap's mcause, 0 until it traps
    li   s2, 0                  # handler entries

    # Park mtimecmp out of reach before arming MTIE: it leaves reset at zero
    # on both models, so MTIP would already be pending here.
    li   t2, CLINT_MTIMECMP
    li   t3, -1
    sw   t3, 0(t2)
    sw   t3, 4(t2)

    li   t0, 0x80               # mie.MTIE
    csrs mie, t0
    li   t0, 0x8                # mstatus.MIE
    csrs mstatus, t0

    # Schedule the arrival, high word first so the pair never passes through
    # a value small enough to fire early.
    li   t0, CLINT_MTIME
    lw   t1, 0(t0)
    addi t1, t1, TIMER_DELAY
    sw   x0, 4(t2)
    sw   t1, 0(t2)

    .rept SHADOW_NOPS
    nop
    .endr
    ecall

    # Both traps must have landed before judging: the ecall's own trap returns
    # here first, and the timer arrives around it. The bound keeps a run that
    # never takes the interrupt from spinning to the stop-time.
    li   t2, 4096
wait_both:
    li   t0, 2
    beq  s2, t0, judge
    addi t2, t2, -1
    bnez t2, wait_both

judge:
    la   t1, begin_dump
    li   a0, FAIL_PATTERN
    li   t0, MCAUSE_ECALL
    bne  s0, t0, verdict        # 0x8000000B, or the ecall never trapped
    li   t0, 2
    bne  s2, t0, verdict        # the interrupt missed the shadow entirely
    li   a0, PASS_PATTERN

verdict:
    sw   a0, 0(t1)
    sw   s0, 4(t1)
    sw   s2, 8(t1)
    call finish_test
1:  j    1b

handler:
    addi s2, s2, 1
    csrr t4, mcause
    li   t5, MCAUSE_TMI
    beq  t4, t5, tmi_entry

    # Anything else is the ecall's own trap. Record what it called itself and
    # step over the ecall so the mret does not land back on it.
    mv   s0, t4
    csrr t4, mepc
    addi t4, t4, 4
    csrw mepc, t4
    mret

tmi_entry:
    li   t2, CLINT_MTIMECMP
    li   t3, -1
    sw   t3, 0(t2)              # disarm, then resume
    sw   t3, 4(t2)
    mret
