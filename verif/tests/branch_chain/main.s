.include "defs.inc"

# Dense chain of taken branches/jumps: stresses the 1-bit fetch epoch with
# several redirects close together. a0 counts how many arms actually ran
# (expected 24 * 3 = 72 = 0x48).

.macro hop
    j    1f
1:  addi a0, a0, 1
    beq  x0, x0, 1f
1:  addi a0, a0, 1
    bne  a0, x0, 1f
1:  addi a0, a0, 1
.endm

.globl _start
_start:
    la   t1, begin_dump
    li   a0, 0

    .rept 24
        hop
    .endr

    sw   a0, 0(t1)
    call finish_test
2:  j    2b
