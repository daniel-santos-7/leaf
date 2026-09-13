.include "defs.inc"

# A misaligned load must report mcause=4 (load address misaligned).
# The EBREAK right after it is wrong-path (squashed by the fault redirect)
# and must not influence mcause/mtval.
#   begin_dump+0 : mcause  (4 = correct, 3 = breakpoint leaked in)
#   begin_dump+4 : mtval   (should be the bad address 0x80000001)

.globl _start
_start:
    la   t0, handler
    csrw mtvec, t0
    la   t1, begin_dump

    li   t2, 0x80000001         # deliberately misaligned
    lw   t3, 0(t2)              # -> load address misaligned, mcause = 4
    ebreak                      # wrong path, must be squashed

handler:
    la   t1, begin_dump
    csrr a1, mcause
    sw   a1, 0(t1)
    csrr a2, mtval
    sw   a2, 4(t1)
    call finish_test
1:  j    1b
