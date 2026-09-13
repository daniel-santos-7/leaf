.include "defs.inc"

# A wfi woken by a timer interrupt that is never taken.
#
# mie.MTIE is armed but mstatus.MIE stays clear. The spec (privileged,
# 3.3.3) makes WFI unaffected by the global enable: the hart must resume on
# a locally enabled interrupt and, since no trap is taken, carry on at pc+4.
# A wake condition masked by mstatus.MIE parks the hart forever -- the
# simulation then never reaches finish_test and writes no dump at all.
#
# The handler is here only to prove it is not entered: the dump would carry
# a non-zero entry count, and mcause is not read because no trap happened.

.equ CLINT_MTIMECMP, 0x02004000
.equ CLINT_MTIME,    0x0200BFF8

.equ TIMER_DELAY,  2000         # rtc ticks from now until the interrupt

.equ PASS_PATTERN, 0x600D600D

.globl _start
_start:
    la   t0, handler
    csrw mtvec, t0

    li   s3, 0                  # handler entry count

    li   t2, CLINT_MTIMECMP
    li   t3, -1
    sw   t3, 0(t2)
    sw   t3, 4(t2)

    li   t0, 0x80               # mie.MTIE, and mstatus.MIE left at 0
    csrs mie, t0

    # Schedule the wake-up. The high word goes first, so the pair never
    # passes through a value small enough to fire early.
    li   t0, CLINT_MTIME
    lw   t1, 0(t0)
    addi t1, t1, TIMER_DELAY
    sw   x0, 4(t2)
    sw   t1, 0(t2)

    wfi                         # resumes at pc+4, no trap

    li   a0, PASS_PATTERN
    la   t1, begin_dump
    sw   a0, 0(t1)
    sw   s3, 4(t1)              # 0, the handler was never entered
    csrr t0, mip
    sw   t0, 8(t1)              # 0x80, MTIP still pending and never served
    call finish_test
1:  j    1b

handler:
    addi s3, s3, 1
    mret
