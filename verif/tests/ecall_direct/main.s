.include "defs.inc"

# ECALL sitting in the shadow of a taken jump must never execute.
# Records which path ran plus mcause/mepc so the failure mode is visible:
#   begin_dump+0 : 0x600D600D if the fall-through (correct) path ran
#   begin_dump+4 : 0xBAD0BAD0 if the trap handler ran
#   begin_dump+8 : mcause
#   begin_dump+12: mepc

.globl _start
_start:
    la   t0, handler
    csrw mtvec, t0
    la   t1, begin_dump
    li   a0, 0x600D600D

    nop
    ecall                   # speculatively fetched, must be squashed

skip:
    sw   a0, 0(t1)
    call finish_test
1:  j    1b

handler:
    la   t1, begin_dump
    li   a0, 0xBAD0BAD0
    sw   a0, 4(t1)
    csrr a1, mcause
    sw   a1, 8(t1)
    csrr a2, mepc
    sw   a2, 12(t1)
    call finish_test
2:  j    2b
