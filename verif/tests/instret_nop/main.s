.include "defs.inc"

# Straight-line control: no redirects between the two instret reads.
# Delta must be exactly 6 (the first csrr + 5 nops).

.globl _start
_start:
    la   t1, begin_dump
    csrr t2, instret
    nop
    nop
    nop
    nop
    nop
    csrr t3, instret
    sub  t4, t3, t2
    sw   t4, 0(t1)
    call finish_test
9:  j    9b
