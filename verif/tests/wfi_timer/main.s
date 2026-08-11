.include "defs.inc"

# A wfi parked until a CLINT timer interrupt wakes it.
#
# The point of the test is instret. While the wfi is parked the ID stage
# stops advancing and nothing may retire; a core that qualifies its retire
# pulse with the wrong ready signal counts the instruction ahead of the wfi
# once per parked cycle. The park here lasts TIMER_DELAY rtc ticks, far more
# than DELTA_LIMIT, so that failure cannot hide.
#
# Only derived values reach the dump: the raw counter delta cannot match
# between Leaf and Spike -- different machines, different rtc rates -- but
# the verdict, the handler entry count and mcause must.

.equ CLINT_MTIMECMP, 0x02004000
.equ CLINT_MTIME,    0x0200BFF8

.equ TIMER_DELAY,  2000         # rtc ticks from now until the interrupt
.equ DELTA_LIMIT,  512          # instret must advance by less than this

.equ PASS_PATTERN, 0x600D600D
.equ FAIL_PATTERN, 0xBAD0BAD0

.globl _start
_start:
    la   t0, handler
    csrw mtvec, t0

    li   s3, 0                  # handler entry count

    # Park mtimecmp before arming MTIE: it leaves reset at zero on both
    # models, so MTIP is already pending here.
    li   t2, CLINT_MTIMECMP
    li   t3, -1
    sw   t3, 0(t2)
    sw   t3, 4(t2)

    li   t0, 0x80               # mie.MTIE
    csrs mie, t0
    li   t0, 0x8                # mstatus.MIE
    csrs mstatus, t0

    # Schedule the wake-up. The high word goes first, so the pair never
    # passes through a value small enough to fire early.
    li   t0, CLINT_MTIME
    lw   t1, 0(t0)
    addi t1, t1, TIMER_DELAY
    sw   x0, 4(t2)
    sw   t1, 0(t2)

    csrr s0, instret
    wfi
    csrr s1, instret
    sub  s2, s1, s0

    li   a0, FAIL_PATTERN
    li   t0, DELTA_LIMIT
    bgeu s2, t0, verdict        # parked cycles leaked into instret
    beqz s2, verdict            # the wfi itself never retired
    li   a0, PASS_PATTERN

verdict:
    la   t1, begin_dump
    sw   a0, 0(t1)
    sw   s3, 4(t1)              # exactly one trap
    csrr t0, mcause
    sw   t0, 8(t1)              # 0x80000007, machine timer interrupt
    call finish_test
1:  j    1b

handler:
    li   t2, CLINT_MTIMECMP
    li   t3, -1
    sw   t3, 0(t2)              # disarm before returning
    sw   t3, 4(t2)
    addi s3, s3, 1
    mret
