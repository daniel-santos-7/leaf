.include "defs.inc"

# MRET sitting in the shadow of a taken jump must never execute.
# If it does, the core redirects to mepc (bad_path) instead of falling
# through to skip.

.globl _start
_start:
    la   t0, bad_path
    csrw mepc, t0

    j    skip
    mret                    # speculatively fetched, must be squashed

skip:
    li   a0, 0x600D600D
    la   t1, begin_dump
    sw   a0, 0(t1)
    call finish_test
1:  j    1b

bad_path:
    li   a0, 0xBAD0BAD0
    la   t1, begin_dump
    sw   a0, 0(t1)
    call finish_test
2:  j    2b
