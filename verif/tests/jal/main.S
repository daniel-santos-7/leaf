.include "defs.inc"

# jal in three shapes: the link value for every rd, a backward jal closing a
# loop, and a forward jal over a long block so the immediate is more than a
# handful of low bits. Each jump has a poisoned instruction directly behind it
# that must never run.
#
# The link values are absolute addresses. main.S is linked first in both the
# Leaf and the Spike build, so _start sits at 0x80000000 either way and the
# two dumps agree word for word.

.altmacro

.set dump_offset, 0

.macro test_jal_case rd, addr, off
    li   x\rd, 0xBAD
    jal  x\rd, 1f
    li   x\rd, 0xDEAD
1:  la   x\addr, begin_dump + \off
    sw   x\rd, 0(x\addr)
.endm

.macro test_jal_all_regs
    .set i, 0
    .rept 32
        test_jal_case %i, %(((i + 3) % 31) + 1), dump_offset
        .set dump_offset, dump_offset + 4
        .set i, i + 1
    .endr
.endm

.globl _start
_start:
    test_jal_all_regs

    # jal x0 as the backward edge of a loop: four passes of +7
    li   x5, 4
    li   x6, 0
1:  addi x6, x6, 7
    addi x5, x5, -1
    beq  x5, x0, 2f
    jal  x0, 1b
2:  la   x8, begin_dump + dump_offset
    sw   x6, 0(x8)
    .set dump_offset, dump_offset + 4

    # a forward jal clearing 256 words in one go
    li   x7, 0
    jal  x9, 3f
    .rept 256
        addi x7, x7, 1
    .endr
3:  la   x8, begin_dump + dump_offset
    sw   x7, 0(x8)
    .set dump_offset, dump_offset + 4
    la   x8, begin_dump + dump_offset
    sw   x9, 0(x8)
    .set dump_offset, dump_offset + 4

    call finish_test
4:  j    4b
