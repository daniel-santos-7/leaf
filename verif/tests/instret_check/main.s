.include "defs.inc"

# minstret must count only retired (committed) instructions.
# Instructions fetched into the shadow of a taken jump are squashed and
# must not be counted. Dumps the delta across three taken jumps.

.globl _start
_start:
    la   t1, begin_dump
    csrr t2, instret
    j    1f
1:  j    2f
2:  j    3f
3:  csrr t3, instret
    sub  t4, t3, t2
    sw   t4, 0(t1)
    call finish_test
9:  j    9b
